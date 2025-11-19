module GameHelpers exposing
    ( createHenchman
    , exitGarrison
    , findNearestDamagedBuilding
    , randomNearbyCell
    , recalculateAllPaths
    , updateUnitMovement
    )
import Dict exposing (Dict)
import GameStrings
import Grid exposing (getBuildingEntrance)
import Pathfinding exposing (calculateUnitPath)
import Random
import Types exposing (..)
updateUnitMovement : GridConfig -> MapConfig -> Dict ( Int, Int ) Int -> Float -> Unit -> Unit
updateUnitMovement gridConfig mapConfig occupancy deltaSeconds unit =
    case unit.location of
        OnMap x y ->
            case unit.path of
                [] -> unit
                nextCell :: restOfPath ->
                    let
                        targetX =
                            toFloat (Tuple.first nextCell) * gridConfig.pathfindingGridSize + gridConfig.pathfindingGridSize / 2
                        targetY =
                            toFloat (Tuple.second nextCell) * gridConfig.pathfindingGridSize + gridConfig.pathfindingGridSize / 2
                        dx = targetX - x
                        dy = targetY - y
                        distance = sqrt (dx * dx + dy * dy)
                        moveDistance =
                            unit.movementSpeed * gridConfig.pathfindingGridSize * deltaSeconds
                    in
                    if distance <= moveDistance then
                        case ( unit.targetDestination, restOfPath ) of
                            ( Just targetCell, _ :: _ ) ->
                                let
                                    newPath =
                                        calculateUnitPath gridConfig mapConfig occupancy targetX targetY targetCell
                                in
                                { unit
                                    | location = OnMap targetX targetY
                                    , path = newPath
                                }
                            _ -> { unit
                                    | location = OnMap targetX targetY
                                    , path = restOfPath
                                }
                    else
                        let
                            normalizedDx = dx / distance
                            normalizedDy = dy / distance
                            newX = x + normalizedDx * moveDistance
                            newY = y + normalizedDy * moveDistance
                        in
                        { unit | location = OnMap newX newY }
        Garrisoned _ -> unit
randomNearbyCell : GridConfig -> Float -> Float -> Int -> Random.Generator ( Int, Int )
randomNearbyCell gridConfig unitX unitY radius =
    let
        currentCellX = floor (unitX / gridConfig.pathfindingGridSize)
        currentCellY = floor (unitY / gridConfig.pathfindingGridSize)
        minX = currentCellX - radius
        maxX = currentCellX + radius
        minY = currentCellY - radius
        maxY = currentCellY + radius
    in
    Random.map2 (\x y -> ( x, y ))
        (Random.int minX maxX)
        (Random.int minY maxY)
exitGarrison : Building -> Unit -> Unit
exitGarrison homeBuilding unit =
    let
        ( entranceGridX, entranceGridY ) = getBuildingEntrance homeBuilding
        buildGridSize = 64
        exitGridX = entranceGridX
        exitGridY = entranceGridY + 1
        worldX =
            toFloat exitGridX * toFloat buildGridSize + toFloat buildGridSize / 2
        worldY =
            toFloat exitGridY * toFloat buildGridSize + toFloat buildGridSize / 2
    in
    { unit | location = OnMap worldX worldY }
findNearestDamagedBuilding : Float -> Float -> List Building -> Maybe Building
findNearestDamagedBuilding unitX unitY buildings =
    let
        buildGridSize = 64
        damagedBuildings = List.filter (\b -> b.hp < b.maxHp) buildings
        buildingWithDistance b =
            let
                buildingCenterX =
                    toFloat b.gridX * toFloat buildGridSize + (toFloat (buildingSizeToGridCells b.size) * toFloat buildGridSize / 2)
                buildingCenterY =
                    toFloat b.gridY * toFloat buildGridSize + (toFloat (buildingSizeToGridCells b.size) * toFloat buildGridSize / 2)
                dx = unitX - buildingCenterX
                dy = unitY - buildingCenterY
                distance = sqrt (dx * dx + dy * dy)
            in
            ( b, distance )
        sortedByDistance = damagedBuildings
                |> List.map buildingWithDistance
                |> List.sortBy Tuple.second
                |> List.map Tuple.first
    in
    List.head sortedByDistance
createHenchman : String -> Int -> Int -> Building -> Unit
createHenchman unitType unitId buildingId homeBuilding =
    let
        ( hp, speed, tags ) =
            if unitType == GameStrings.unitTypePeasant then
                ( 50, 2.0, [ HenchmanTag ] )
            else if unitType == GameStrings.unitTypeTaxCollector then
                ( 50, 1.5, [ HenchmanTag ] )
            else if unitType == GameStrings.unitTypeCastleGuard then
                ( 100, 2.0, [ HenchmanTag ] )
            else
                ( 50, 2.0, [ HenchmanTag ] )
    in
    { id = unitId
    , owner = Player
    , location = Garrisoned buildingId
    , hp = hp
    , maxHp = hp
    , movementSpeed = speed
    , unitType = unitType
    , unitKind = Henchman
    , color = "#888"
    , path = []
    , behavior = Sleeping
    , behaviorTimer = 0
    , behaviorDuration = 0
    , thinkingTimer = 0
    , thinkingDuration = 0
    , homeBuilding = Just buildingId
    , carriedGold = 0
    , targetDestination = Nothing
    , activeRadius = 192
    , searchRadius = 384
    , tags = tags
    }
recalculateAllPaths : GridConfig -> MapConfig -> Dict ( Int, Int ) Int -> List Unit -> List Unit
recalculateAllPaths gridConfig mapConfig occupancy units = List.map
        (\unit ->
            if List.isEmpty unit.path then
                unit
            else
                case unit.location of
                    OnMap x y ->
                        case List.reverse unit.path |> List.head of
                            Just goalCell ->
                                let
                                    newPath =
                                        calculateUnitPath gridConfig mapConfig occupancy x y goalCell
                                in
                                { unit | path = newPath }
                            Nothing -> unit
                    Garrisoned _ -> unit
        )
        units
