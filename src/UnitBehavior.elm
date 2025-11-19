module UnitBehavior exposing
    ( updateGarrisonSpawning
    , updateUnitBehavior
    )
import GameHelpers exposing (exitGarrison, findNearestDamagedBuilding)
import Grid exposing (getBuildingEntrance)
import Types exposing (..)
updateUnitBehavior : Float -> List Building -> Unit -> ( Unit, Bool )
updateUnitBehavior deltaSeconds buildings unit =
    case unit.behavior of
        Dead -> ( unit, False )
        DebugError _ -> ( unit, False )
        WithoutHome ->
            let
                newTimer = unit.behaviorTimer + deltaSeconds
            in
            if newTimer >= unit.behaviorDuration then
                ( { unit | behavior = Dead, behaviorTimer = 0, behaviorDuration = 45.0 + (toFloat (modBy 15000 unit.id) / 1000.0) }, False )
            else
                ( { unit | behaviorTimer = newTimer }, False )
        LookingForTask ->
            case unit.unitType of
                "Peasant" ->
                    ( { unit | behavior = LookForBuildRepairTarget, behaviorTimer = 0 }, False )
                "Tax Collector" ->
                    ( { unit | behavior = LookForTaxTarget, behaviorTimer = 0 }, False )
                "Castle Guard" ->
                    ( { unit | behavior = GoingToSleep, behaviorTimer = 0 }, False )
                _ ->
                    ( { unit | behavior = GoingToSleep, behaviorTimer = 0 }, False )
        GoingToSleep ->
            case unit.homeBuilding of
                Nothing ->
                    ( { unit | behavior = WithoutHome, behaviorTimer = 0, behaviorDuration = 15.0 + (toFloat (modBy 15000 unit.id) / 1000.0) }, False )
                Just homeBuildingId ->
                    case List.filter (\b -> b.id == homeBuildingId) buildings |> List.head of
                        Nothing ->
                            ( { unit | behavior = WithoutHome, homeBuilding = Nothing, behaviorTimer = 0, behaviorDuration = 15.0 + (toFloat (modBy 15000 unit.id) / 1000.0) }, False )
                        Just homeBuilding ->
                            case unit.location of
                                Garrisoned _ ->
                                    ( { unit | behavior = Sleeping, behaviorTimer = 0 }, False )
                                OnMap x y ->
                                    let
                                        ( entranceGridX, entranceGridY ) = getBuildingEntrance homeBuilding
                                        buildGridSize = 64
                                        exitGridX = entranceGridX
                                        exitGridY = entranceGridY + 1
                                        exitX =
                                            toFloat exitGridX * toFloat buildGridSize + toFloat buildGridSize / 2
                                        exitY =
                                            toFloat exitGridY * toFloat buildGridSize + toFloat buildGridSize / 2
                                        dx = x - exitX
                                        dy = y - exitY
                                        distance = sqrt (dx * dx + dy * dy)
                                        isAtEntrance = distance < 32
                                    in
                                    if isAtEntrance then
                                        ( { unit | location = Garrisoned homeBuildingId, behavior = Sleeping, behaviorTimer = 0 }, False )
                                    else
                                        let
                                            targetCellX = floor (exitX / 32)
                                            targetCellY = floor (exitY / 32)
                                        in
                                        ( { unit | targetDestination = Just ( targetCellX, targetCellY ) }, True )
        Sleeping ->
            let
                healAmount = toFloat unit.maxHp * 0.1 * deltaSeconds
                newHp = min unit.maxHp (unit.hp + round healAmount)
                newTimer = unit.behaviorTimer + deltaSeconds
                shouldLookForTask = newTimer >= 1.0
            in
            if shouldLookForTask then
                ( { unit | hp = newHp, behavior = LookingForTask, behaviorTimer = 0 }, False )
            else
                ( { unit | hp = newHp, behaviorTimer = newTimer }, False )
        LookForBuildRepairTarget ->
            case unit.location of
                Garrisoned buildingId ->
                    case List.filter (\b -> b.id == buildingId) buildings |> List.head of
                        Just homeBuilding ->
                            let
                                exitedUnit = exitGarrison homeBuilding unit
                                ( finalX, finalY ) =
                                    case exitedUnit.location of
                                        OnMap x y -> ( x, y )
                                        _ -> ( 0, 0 )
                            in
                            case findNearestDamagedBuilding finalX finalY buildings of
                                Just targetBuilding ->
                                    let
                                        buildGridSize = 64
                                        targetX =
                                            toFloat targetBuilding.gridX * toFloat buildGridSize + (toFloat (buildingSizeToGridCells targetBuilding.size) * toFloat buildGridSize / 2)
                                        targetY =
                                            toFloat targetBuilding.gridY * toFloat buildGridSize + (toFloat (buildingSizeToGridCells targetBuilding.size) * toFloat buildGridSize / 2)
                                        targetCellX = floor (targetX / 32)
                                        targetCellY = floor (targetY / 32)
                                    in
                                    ( { exitedUnit
                                        | behavior = MovingToBuildRepairTarget
                                        , targetDestination = Just ( targetCellX, targetCellY )
                                        , behaviorTimer = 0
                                      }
                                    , True
                                    )
                                Nothing ->
                                    ( { exitedUnit | behavior = GoingToSleep, behaviorTimer = 0 }, False )
                        Nothing ->
                            ( { unit | behavior = DebugError "Home building not found" }, False )
                OnMap x y ->
                    case findNearestDamagedBuilding x y buildings of
                        Just targetBuilding ->
                            let
                                buildGridSize = 64
                                targetX =
                                    toFloat targetBuilding.gridX * toFloat buildGridSize + (toFloat (buildingSizeToGridCells targetBuilding.size) * toFloat buildGridSize / 2)
                                targetY =
                                    toFloat targetBuilding.gridY * toFloat buildGridSize + (toFloat (buildingSizeToGridCells targetBuilding.size) * toFloat buildGridSize / 2)
                                targetCellX = floor (targetX / 32)
                                targetCellY = floor (targetY / 32)
                            in
                            ( { unit
                                | behavior = MovingToBuildRepairTarget
                                , targetDestination = Just ( targetCellX, targetCellY )
                                , behaviorTimer = 0
                              }
                            , True
                            )
                        Nothing ->
                            ( { unit | behavior = GoingToSleep, behaviorTimer = 0 }, False )
        MovingToBuildRepairTarget ->
            case unit.location of
                OnMap x y ->
                    case findNearestDamagedBuilding x y buildings of
                        Just targetBuilding ->
                            let
                                buildGridSize = 64
                                buildingMinX = toFloat targetBuilding.gridX * toFloat buildGridSize
                                buildingMinY = toFloat targetBuilding.gridY * toFloat buildGridSize
                                buildingSize =
                                    toFloat (buildingSizeToGridCells targetBuilding.size) * toFloat buildGridSize
                                buildingMaxX = buildingMinX + buildingSize
                                buildingMaxY = buildingMinY + buildingSize
                                isNear = (x >= buildingMinX - 48 && x <= buildingMaxX + 48)
                                        && (y >= buildingMinY - 48 && y <= buildingMaxY + 48)
                            in
                            if isNear then
                                ( { unit | behavior = Repairing, behaviorTimer = 0 }, False )
                            else
                                ( unit, False )
                        Nothing ->
                            ( { unit | behavior = LookForBuildRepairTarget, behaviorTimer = 0 }, False )
                Garrisoned _ ->
                    ( { unit | behavior = DebugError "Moving while garrisoned" }, False )
        Repairing ->
            case unit.location of
                OnMap x y ->
                    case findNearestDamagedBuilding x y buildings of
                        Just targetBuilding ->
                            let
                                buildGridSize = 64
                                buildingMinX = toFloat targetBuilding.gridX * toFloat buildGridSize
                                buildingMinY = toFloat targetBuilding.gridY * toFloat buildGridSize
                                buildingSize =
                                    toFloat (buildingSizeToGridCells targetBuilding.size) * toFloat buildGridSize
                                buildingMaxX = buildingMinX + buildingSize
                                buildingMaxY = buildingMinY + buildingSize
                                isNear = (x >= buildingMinX - 48 && x <= buildingMaxX + 48)
                                        && (y >= buildingMinY - 48 && y <= buildingMaxY + 48)
                                newTimer = unit.behaviorTimer + deltaSeconds
                                canBuild = newTimer >= 0.15
                            in
                            if isNear && canBuild then
                                if targetBuilding.hp + 5 >= targetBuilding.maxHp then
                                    ( { unit | behavior = LookForBuildRepairTarget, behaviorTimer = 0 }, False )
                                else
                                    ( { unit | behaviorTimer = 0 }, False )
                            else if isNear then
                                ( { unit | behaviorTimer = newTimer }, False )
                            else
                                ( unit, False )
                        Nothing ->
                            ( { unit | behavior = LookForBuildRepairTarget, behaviorTimer = 0 }, False )
                Garrisoned _ ->
                    ( { unit | behavior = DebugError "Repairing while garrisoned" }, False )
        LookForTaxTarget -> ( unit, False )
        CollectingTaxes -> ( unit, False )
        ReturnToCastle -> ( unit, False )
        DeliveringGold -> ( unit, False )
updateGarrisonSpawning : Float -> Building -> ( Building, List ( String, Int ) )
updateGarrisonSpawning deltaSeconds building =
    let
        ( updatedConfig, unitsToSpawn ) = List.foldl
                (\slot ( accConfig, accSpawn ) ->
                    if slot.currentCount < slot.maxCount then
                        let
                            newTimer = slot.spawnTimer + deltaSeconds
                        in
                        if newTimer >= 30.0 then
                            ( { slot | spawnTimer = 0, currentCount = slot.currentCount + 1 } :: accConfig
                            , ( slot.unitType, building.id ) :: accSpawn
                            )
                        else
                            ( { slot | spawnTimer = newTimer } :: accConfig
                            , accSpawn
                            )
                    else
                        ( slot :: accConfig
                        , accSpawn
                        )
                )
                ( [], [] )
                building.garrisonConfig
        totalOccupied =
            List.foldl (\slot acc -> acc + slot.currentCount) 0 updatedConfig
    in
    ( { building | garrisonConfig = List.reverse updatedConfig, garrisonOccupied = totalOccupied }, List.reverse unitsToSpawn )
