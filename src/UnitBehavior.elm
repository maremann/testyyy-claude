module UnitBehavior exposing
    ( updateGarrisonSpawning
    , updateUnitBehavior
    )

import GameHelpers exposing (exitGarrison, findNearestDamagedBuilding)
import Grid exposing (getBuildingEntrance)
import Types exposing (..)


-- UNIT BEHAVIOR


{-| Update unit behavior state machine. Returns (updatedUnit, shouldGeneratePath).
-}
updateUnitBehavior : Float -> List Building -> Unit -> ( Unit, Bool )
updateUnitBehavior deltaSeconds buildings unit =
    case unit.behavior of
        Dead ->
            -- Dead units don't change behavior
            ( unit, False )

        DebugError _ ->
            -- Error state, don't change behavior
            ( unit, False )

        WithoutHome ->
            -- Unit without home: die after 15-30 seconds
            let
                newTimer =
                    unit.behaviorTimer + deltaSeconds
            in
            if newTimer >= unit.behaviorDuration then
                -- Time to die
                ( { unit | behavior = Dead, behaviorTimer = 0, behaviorDuration = 45.0 + (toFloat (modBy 15000 unit.id) / 1000.0) }, False )

            else
                ( { unit | behaviorTimer = newTimer }, False )

        LookingForTask ->
            -- Looking for task: check unit type and find appropriate work
            case unit.unitType of
                "Peasant" ->
                    -- Peasant looks for damaged buildings or construction sites
                    ( { unit | behavior = LookForBuildRepairTarget, behaviorTimer = 0 }, False )

                "Tax Collector" ->
                    -- Tax Collector looks for buildings with gold in coffer
                    ( { unit | behavior = LookForTaxTarget, behaviorTimer = 0 }, False )

                "Castle Guard" ->
                    -- Castle Guard has no tasks yet, go back to sleep
                    ( { unit | behavior = GoingToSleep, behaviorTimer = 0 }, False )

                _ ->
                    -- Unknown unit type, go back to sleep
                    ( { unit | behavior = GoingToSleep, behaviorTimer = 0 }, False )

        GoingToSleep ->
            -- Going to sleep: move back to home building
            case unit.homeBuilding of
                Nothing ->
                    -- No home, transition to WithoutHome
                    ( { unit | behavior = WithoutHome, behaviorTimer = 0, behaviorDuration = 15.0 + (toFloat (modBy 15000 unit.id) / 1000.0) }, False )

                Just homeBuildingId ->
                    case List.filter (\b -> b.id == homeBuildingId) buildings |> List.head of
                        Nothing ->
                            -- Home building destroyed, transition to WithoutHome
                            ( { unit | behavior = WithoutHome, homeBuilding = Nothing, behaviorTimer = 0, behaviorDuration = 15.0 + (toFloat (modBy 15000 unit.id) / 1000.0) }, False )

                        Just homeBuilding ->
                            case unit.location of
                                Garrisoned _ ->
                                    -- Already garrisoned, transition to Sleeping
                                    ( { unit | behavior = Sleeping, behaviorTimer = 0 }, False )

                                OnMap x y ->
                                    let
                                        -- Get entrance position
                                        ( entranceGridX, entranceGridY ) =
                                            getBuildingEntrance homeBuilding

                                        buildGridSize =
                                            64

                                        -- Calculate exit position (one tile below entrance, outside building)
                                        exitGridX =
                                            entranceGridX

                                        exitGridY =
                                            entranceGridY + 1

                                        exitX =
                                            toFloat exitGridX * toFloat buildGridSize + toFloat buildGridSize / 2

                                        exitY =
                                            toFloat exitGridY * toFloat buildGridSize + toFloat buildGridSize / 2

                                        -- Check if at exit position (entry point)
                                        dx =
                                            x - exitX

                                        dy =
                                            y - exitY

                                        distance =
                                            sqrt (dx * dx + dy * dy)

                                        isAtEntrance =
                                            distance < 32

                                        -- Within half a build grid cell
                                    in
                                    if isAtEntrance then
                                        -- Enter garrison and sleep
                                        ( { unit | location = Garrisoned homeBuildingId, behavior = Sleeping, behaviorTimer = 0 }, False )

                                    else
                                        -- Not at entrance yet, request path to exit position
                                        let
                                            targetCellX =
                                                floor (exitX / 32)

                                            targetCellY =
                                                floor (exitY / 32)
                                        in
                                        ( { unit | targetDestination = Just ( targetCellX, targetCellY ) }, True )

        Sleeping ->
            -- Sleeping: heal 10% max HP per second, check for tasks every 1s
            let
                -- Heal 10% of max HP per second
                healAmount =
                    toFloat unit.maxHp * 0.1 * deltaSeconds

                newHp =
                    min unit.maxHp (unit.hp + round healAmount)

                -- Increment behavior timer
                newTimer =
                    unit.behaviorTimer + deltaSeconds

                -- Check for task every 1 second
                shouldLookForTask =
                    newTimer >= 1.0
            in
            if shouldLookForTask then
                ( { unit | hp = newHp, behavior = LookingForTask, behaviorTimer = 0 }, False )

            else
                ( { unit | hp = newHp, behaviorTimer = newTimer }, False )

        LookForBuildRepairTarget ->
            -- Looking for build/repair target
            case unit.location of
                Garrisoned buildingId ->
                    -- Exit garrison first, then immediately look for buildings
                    case List.filter (\b -> b.id == buildingId) buildings |> List.head of
                        Just homeBuilding ->
                            let
                                exitedUnit =
                                    exitGarrison homeBuilding unit

                                -- Now check for damaged buildings at the exited position
                                ( finalX, finalY ) =
                                    case exitedUnit.location of
                                        OnMap x y ->
                                            ( x, y )

                                        _ ->
                                            ( 0, 0 )

                                -- Shouldn't happen
                            in
                            case findNearestDamagedBuilding finalX finalY buildings of
                                Just targetBuilding ->
                                    -- Found a target, start moving toward it
                                    let
                                        -- Calculate target position (building center)
                                        buildGridSize =
                                            64

                                        targetX =
                                            toFloat targetBuilding.gridX * toFloat buildGridSize + (toFloat (buildingSizeToGridCells targetBuilding.size) * toFloat buildGridSize / 2)

                                        targetY =
                                            toFloat targetBuilding.gridY * toFloat buildGridSize + (toFloat (buildingSizeToGridCells targetBuilding.size) * toFloat buildGridSize / 2)

                                        -- Calculate pathfinding cell
                                        targetCellX =
                                            floor (targetX / 32)

                                        targetCellY =
                                            floor (targetY / 32)
                                    in
                                    ( { exitedUnit
                                        | behavior = MovingToBuildRepairTarget
                                        , targetDestination = Just ( targetCellX, targetCellY )
                                        , behaviorTimer = 0
                                      }
                                    , True
                                        -- Request path
                                    )

                                Nothing ->
                                    -- No damaged buildings, go to sleep
                                    ( { exitedUnit | behavior = GoingToSleep, behaviorTimer = 0 }, False )

                        Nothing ->
                            -- Home building not found, error state
                            ( { unit | behavior = DebugError "Home building not found" }, False )

                OnMap x y ->
                    -- Already on map, find nearest damaged building
                    case findNearestDamagedBuilding x y buildings of
                        Just targetBuilding ->
                            -- Found a target, start moving toward it
                            let
                                -- Calculate target position (building center)
                                buildGridSize =
                                    64

                                targetX =
                                    toFloat targetBuilding.gridX * toFloat buildGridSize + (toFloat (buildingSizeToGridCells targetBuilding.size) * toFloat buildGridSize / 2)

                                targetY =
                                    toFloat targetBuilding.gridY * toFloat buildGridSize + (toFloat (buildingSizeToGridCells targetBuilding.size) * toFloat buildGridSize / 2)

                                -- Calculate pathfinding cell
                                targetCellX =
                                    floor (targetX / 32)

                                targetCellY =
                                    floor (targetY / 32)
                            in
                            ( { unit
                                | behavior = MovingToBuildRepairTarget
                                , targetDestination = Just ( targetCellX, targetCellY )
                                , behaviorTimer = 0
                              }
                            , True
                                -- Request path
                            )

                        Nothing ->
                            -- No damaged buildings, go to sleep
                            ( { unit | behavior = GoingToSleep, behaviorTimer = 0 }, False )

        MovingToBuildRepairTarget ->
            -- Moving toward build/repair target
            case unit.location of
                OnMap x y ->
                    -- Find the target building
                    case findNearestDamagedBuilding x y buildings of
                        Just targetBuilding ->
                            let
                                buildGridSize =
                                    64

                                -- Calculate building bounds
                                buildingMinX =
                                    toFloat targetBuilding.gridX * toFloat buildGridSize

                                buildingMinY =
                                    toFloat targetBuilding.gridY * toFloat buildGridSize

                                buildingSize =
                                    toFloat (buildingSizeToGridCells targetBuilding.size) * toFloat buildGridSize

                                buildingMaxX =
                                    buildingMinX + buildingSize

                                buildingMaxY =
                                    buildingMinY + buildingSize

                                -- Check if unit is adjacent to building (within 48 pixels)
                                isNear =
                                    (x >= buildingMinX - 48 && x <= buildingMaxX + 48)
                                        && (y >= buildingMinY - 48 && y <= buildingMaxY + 48)
                            in
                            if isNear then
                                -- Arrived at building, switch to Repairing
                                ( { unit | behavior = Repairing, behaviorTimer = 0 }, False )

                            else
                                -- Still moving, keep going
                                ( unit, False )

                        Nothing ->
                            -- Target building no longer needs repair, look for another
                            ( { unit | behavior = LookForBuildRepairTarget, behaviorTimer = 0 }, False )

                Garrisoned _ ->
                    -- Shouldn't be garrisoned while moving
                    ( { unit | behavior = DebugError "Moving while garrisoned" }, False )

        Repairing ->
            -- Repairing: use Build ability when near damaged building
            case unit.location of
                OnMap x y ->
                    -- Find the target building
                    case findNearestDamagedBuilding x y buildings of
                        Just targetBuilding ->
                            let
                                buildGridSize =
                                    64

                                -- Calculate building bounds
                                buildingMinX =
                                    toFloat targetBuilding.gridX * toFloat buildGridSize

                                buildingMinY =
                                    toFloat targetBuilding.gridY * toFloat buildGridSize

                                buildingSize =
                                    toFloat (buildingSizeToGridCells targetBuilding.size) * toFloat buildGridSize

                                buildingMaxX =
                                    buildingMinX + buildingSize

                                buildingMaxY =
                                    buildingMinY + buildingSize

                                -- Check if unit is adjacent to building (within 48 pixels)
                                isNear =
                                    (x >= buildingMinX - 48 && x <= buildingMaxX + 48)
                                        && (y >= buildingMinY - 48 && y <= buildingMaxY + 48)

                                -- Build ability: 0.15 second cooldown
                                newTimer =
                                    unit.behaviorTimer + deltaSeconds

                                canBuild =
                                    newTimer >= 0.15
                            in
                            if isNear && canBuild then
                                -- Repair complete, look for another target
                                if targetBuilding.hp + 5 >= targetBuilding.maxHp then
                                    ( { unit | behavior = LookForBuildRepairTarget, behaviorTimer = 0 }, False )

                                else
                                    -- Continue repairing
                                    ( { unit | behaviorTimer = 0 }, False )

                            else if isNear then
                                -- Near but cooldown not ready
                                ( { unit | behaviorTimer = newTimer }, False )

                            else
                                -- Not near, keep moving (path should already be set)
                                ( unit, False )

                        Nothing ->
                            -- No damaged buildings anymore, look for another task
                            ( { unit | behavior = LookForBuildRepairTarget, behaviorTimer = 0 }, False )

                Garrisoned _ ->
                    -- Shouldn't be garrisoned while repairing
                    ( { unit | behavior = DebugError "Repairing while garrisoned" }, False )

        LookForTaxTarget ->
            -- Looking for tax target, don't change behavior
            ( unit, False )

        CollectingTaxes ->
            -- Collecting taxes, don't change behavior
            ( unit, False )

        ReturnToCastle ->
            -- Returning to castle, don't change behavior
            ( unit, False )

        DeliveringGold ->
            -- Delivering gold, don't change behavior
            ( unit, False )


{-| Update garrison spawn timers and return units that need to be spawned
Returns (Building, List (unitType, buildingId))
-}
updateGarrisonSpawning : Float -> Building -> ( Building, List ( String, Int ) )
updateGarrisonSpawning deltaSeconds building =
    let
        -- Update each garrison slot's spawn timer
        ( updatedConfig, unitsToSpawn ) =
            List.foldl
                (\slot ( accConfig, accSpawn ) ->
                    if slot.currentCount < slot.maxCount then
                        let
                            newTimer =
                                slot.spawnTimer + deltaSeconds
                        in
                        if newTimer >= 30.0 then
                            -- Time to spawn - reset timer and add to spawn list
                            ( { slot | spawnTimer = 0, currentCount = slot.currentCount + 1 } :: accConfig
                            , ( slot.unitType, building.id ) :: accSpawn
                            )

                        else
                            -- Still waiting - update timer
                            ( { slot | spawnTimer = newTimer } :: accConfig
                            , accSpawn
                            )

                    else
                        -- Slot is full - don't update timer
                        ( slot :: accConfig
                        , accSpawn
                        )
                )
                ( [], [] )
                building.garrisonConfig

        -- Calculate total garrison occupied from config
        totalOccupied =
            List.foldl (\slot acc -> acc + slot.currentCount) 0 updatedConfig
    in
    ( { building | garrisonConfig = List.reverse updatedConfig, garrisonOccupied = totalOccupied }, List.reverse unitsToSpawn )
