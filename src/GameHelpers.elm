module GameHelpers exposing
    ( createHenchman
    , exitGarrison
    , findNearestDamagedBuilding
    , randomNearbyCell
    , recalculateAllPaths
    , updateUnitMovement
    )

import Dict exposing (Dict)
import Grid exposing (getBuildingEntrance)
import Pathfinding exposing (calculateUnitPath)
import Random
import Types exposing (..)


-- UNIT MOVEMENT AND HELPERS


{-| Update a unit's position, moving it along its path. Recalculates path when reaching intermediate cells.
-}
updateUnitMovement : GridConfig -> MapConfig -> Dict ( Int, Int ) Int -> Float -> Unit -> Unit
updateUnitMovement gridConfig mapConfig occupancy deltaSeconds unit =
    case unit.location of
        OnMap x y ->
            case unit.path of
                [] ->
                    -- No path, unit stays in place
                    unit

                nextCell :: restOfPath ->
                    let
                        -- Target position (center of next pathfinding cell)
                        targetX =
                            toFloat (Tuple.first nextCell) * gridConfig.pathfindingGridSize + gridConfig.pathfindingGridSize / 2

                        targetY =
                            toFloat (Tuple.second nextCell) * gridConfig.pathfindingGridSize + gridConfig.pathfindingGridSize / 2

                        -- Direction vector
                        dx =
                            targetX - x

                        dy =
                            targetY - y

                        distance =
                            sqrt (dx * dx + dy * dy)

                        -- Movement distance this frame (cells/second * pixels per cell * seconds)
                        moveDistance =
                            unit.movementSpeed * gridConfig.pathfindingGridSize * deltaSeconds
                    in
                    if distance <= moveDistance then
                        -- Reached the target cell, recalculate path if we have a target destination
                        case ( unit.targetDestination, restOfPath ) of
                            ( Just targetCell, _ :: _ ) ->
                                -- Have a destination and more cells to go - recalculate path
                                let
                                    newPath =
                                        calculateUnitPath gridConfig mapConfig occupancy targetX targetY targetCell
                                in
                                { unit
                                    | location = OnMap targetX targetY
                                    , path = newPath
                                }

                            _ ->
                                -- No destination or reached final cell - just pop the cell
                                { unit
                                    | location = OnMap targetX targetY
                                    , path = restOfPath
                                }

                    else
                        -- Move towards the target
                        let
                            -- Normalize direction
                            normalizedDx =
                                dx / distance

                            normalizedDy =
                                dy / distance

                            newX =
                                x + normalizedDx * moveDistance

                            newY =
                                y + normalizedDy * moveDistance
                        in
                        { unit | location = OnMap newX newY }

        Garrisoned _ ->
            -- Garrisoned units don't move
            unit


{-| Generate a random target cell within radius of current position
-}
randomNearbyCell : GridConfig -> Float -> Float -> Int -> Random.Generator ( Int, Int )
randomNearbyCell gridConfig unitX unitY radius =
    let
        currentCellX =
            floor (unitX / gridConfig.pathfindingGridSize)

        currentCellY =
            floor (unitY / gridConfig.pathfindingGridSize)

        minX =
            currentCellX - radius

        maxX =
            currentCellX + radius

        minY =
            currentCellY - radius

        maxY =
            currentCellY + radius
    in
    Random.map2 (\x y -> ( x, y ))
        (Random.int minX maxX)
        (Random.int minY maxY)


{-| Exit a unit from garrison to the building's entrance
-}
exitGarrison : Building -> Unit -> Unit
exitGarrison homeBuilding unit =
    let
        ( entranceGridX, entranceGridY ) =
            getBuildingEntrance homeBuilding

        buildGridSize =
            64

        -- Place unit one tile below entrance (outside building collision)
        -- Entrance is at bottom edge, so +1 tile southward (Y+1) is outside
        exitGridX =
            entranceGridX

        exitGridY =
            entranceGridY + 1

        -- Calculate world position at center of exit tile
        worldX =
            toFloat exitGridX * toFloat buildGridSize + toFloat buildGridSize / 2

        worldY =
            toFloat exitGridY * toFloat buildGridSize + toFloat buildGridSize / 2
    in
    { unit | location = OnMap worldX worldY }


{-| Find the nearest damaged building (HP < max HP) for repair
-}
findNearestDamagedBuilding : Float -> Float -> List Building -> Maybe Building
findNearestDamagedBuilding unitX unitY buildings =
    let
        buildGridSize =
            64

        damagedBuildings =
            List.filter (\b -> b.hp < b.maxHp) buildings

        buildingWithDistance b =
            let
                buildingCenterX =
                    toFloat b.gridX * toFloat buildGridSize + (toFloat (buildingSizeToGridCells b.size) * toFloat buildGridSize / 2)

                buildingCenterY =
                    toFloat b.gridY * toFloat buildGridSize + (toFloat (buildingSizeToGridCells b.size) * toFloat buildGridSize / 2)

                dx =
                    unitX - buildingCenterX

                dy =
                    unitY - buildingCenterY

                distance =
                    sqrt (dx * dx + dy * dy)
            in
            ( b, distance )

        sortedByDistance =
            damagedBuildings
                |> List.map buildingWithDistance
                |> List.sortBy Tuple.second
                |> List.map Tuple.first
    in
    List.head sortedByDistance


{-| Create a henchman unit of the specified type
-}
createHenchman : String -> Int -> Int -> Building -> Unit
createHenchman unitType unitId buildingId homeBuilding =
    let
        ( hp, speed, tags ) =
            case unitType of
                "Peasant" ->
                    ( 50, 2.0, [ HenchmanTag ] )

                "Tax Collector" ->
                    ( 50, 1.5, [ HenchmanTag ] )

                "Castle Guard" ->
                    ( 100, 2.0, [ HenchmanTag ] )

                _ ->
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


{-| Recalculate paths for all units (called when occupancy changes)
-}
recalculateAllPaths : GridConfig -> MapConfig -> Dict ( Int, Int ) Int -> List Unit -> List Unit
recalculateAllPaths gridConfig mapConfig occupancy units =
    List.map
        (\unit ->
            if List.isEmpty unit.path then
                -- No path, nothing to recalculate
                unit

            else
                case unit.location of
                    OnMap x y ->
                        case List.reverse unit.path |> List.head of
                            Just goalCell ->
                                -- Recalculate path to the same goal
                                let
                                    newPath =
                                        calculateUnitPath gridConfig mapConfig occupancy x y goalCell
                                in
                                { unit | path = newPath }

                            Nothing ->
                                unit

                    Garrisoned _ ->
                        unit
        )
        units
