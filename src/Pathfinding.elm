module Pathfinding exposing
    ( calculateUnitPath
    , findPath
    )

import Dict exposing (Dict)
import Grid exposing (isPathfindingCellOccupied)
import Types exposing (GridConfig, MapConfig)


-- A* PATHFINDING


type alias PathNode =
    { position : ( Int, Int )
    , gCost : Float
    , hCost : Float
    , parent : Maybe ( Int, Int )
    }


{-| Calculate octile distance between two grid cells
This is the true distance heuristic for 8-directional movement
where diagonal moves cost √2 and orthogonal moves cost 1
-}
octileDistance : ( Int, Int ) -> ( Int, Int ) -> Float
octileDistance ( x1, y1 ) ( x2, y2 ) =
    let
        dx =
            abs (x1 - x2)

        dy =
            abs (y1 - y2)

        minDist =
            min dx dy

        maxDist =
            max dx dy
    in
    -- Diagonal moves for the minimum distance, orthogonal for the rest
    toFloat minDist * 1.414 + toFloat (maxDist - minDist)


{-| Get neighboring pathfinding cells (8-directional with costs)
Returns list of (position, moveCost) tuples
Orthogonal moves cost 1.0, diagonal moves cost √2 (≈1.414)
-}
getNeighbors : ( Int, Int ) -> List ( ( Int, Int ), Float )
getNeighbors ( x, y ) =
    [ ( ( x + 1, y ), 1.0 ) -- Right
    , ( ( x - 1, y ), 1.0 ) -- Left
    , ( ( x, y + 1 ), 1.0 ) -- Down
    , ( ( x, y - 1 ), 1.0 ) -- Up
    , ( ( x + 1, y + 1 ), 1.414 ) -- Down-Right
    , ( ( x + 1, y - 1 ), 1.414 ) -- Up-Right
    , ( ( x - 1, y + 1 ), 1.414 ) -- Down-Left
    , ( ( x - 1, y - 1 ), 1.414 ) -- Up-Left
    ]


{-| Find a node in a list by position
-}
findNode : ( Int, Int ) -> List PathNode -> Maybe PathNode
findNode pos nodes =
    List.filter (\n -> n.position == pos) nodes
        |> List.head


{-| Remove a node from a list
-}
removeNode : ( Int, Int ) -> List PathNode -> List PathNode
removeNode pos nodes =
    List.filter (\n -> n.position /= pos) nodes


{-| Get the node with the lowest fCost from a list
-}
getLowestFCostNode : List PathNode -> Maybe PathNode
getLowestFCostNode nodes =
    case nodes of
        [] ->
            Nothing

        _ ->
            List.sortBy (\n -> n.gCost + n.hCost) nodes
                |> List.head


{-| Reconstruct path from end node back to start
-}
reconstructPath : ( Int, Int ) -> Dict ( Int, Int ) ( Int, Int ) -> List ( Int, Int )
reconstructPath endPos parentMap =
    let
        buildPath current acc =
            case Dict.get current parentMap of
                Just parent ->
                    buildPath parent (current :: acc)

                Nothing ->
                    current :: acc
    in
    buildPath endPos []


{-| A\* pathfinding algorithm
Returns a list of pathfinding grid cells from start to goal (excluding start, including goal)
-}
findPath : GridConfig -> MapConfig -> Dict ( Int, Int ) Int -> ( Int, Int ) -> ( Int, Int ) -> List ( Int, Int )
findPath gridConfig mapConfig occupancy start goal =
    let
        -- Check if a cell is walkable
        isWalkable ( x, y ) =
            let
                worldX =
                    toFloat x * gridConfig.pathfindingGridSize

                worldY =
                    toFloat y * gridConfig.pathfindingGridSize

                inBounds =
                    worldX >= 0 && worldX < mapConfig.width && worldY >= 0 && worldY < mapConfig.height
            in
            inBounds && not (isPathfindingCellOccupied ( x, y ) occupancy)

        -- A* main loop
        astar openSet closedSet parentMap =
            case getLowestFCostNode openSet of
                Nothing ->
                    -- No path found
                    []

                Just currentNode ->
                    if currentNode.position == goal then
                        -- Found the goal, reconstruct path
                        reconstructPath goal parentMap
                            |> List.tail
                            |> Maybe.withDefault []

                    else
                        let
                            newOpenSet =
                                removeNode currentNode.position openSet

                            newClosedSet =
                                currentNode.position :: closedSet

                            neighbors =
                                getNeighbors currentNode.position
                                    |> List.filter (\( pos, _ ) -> isWalkable pos)
                                    |> List.filter (\( pos, _ ) -> not (List.member pos newClosedSet))

                            -- Process each neighbor
                            ( updatedOpenSet, updatedParentMap ) =
                                List.foldl
                                    (\( neighborPos, moveCost ) ( accOpenSet, accParentMap ) ->
                                        let
                                            tentativeGCost =
                                                currentNode.gCost + moveCost

                                            existingNode =
                                                findNode neighborPos accOpenSet
                                        in
                                        case existingNode of
                                            Just existing ->
                                                if tentativeGCost < existing.gCost then
                                                    -- Found a better path to this neighbor
                                                    let
                                                        updatedNode =
                                                            { position = neighborPos
                                                            , gCost = tentativeGCost
                                                            , hCost = octileDistance neighborPos goal
                                                            , parent = Just currentNode.position
                                                            }

                                                        newOpenSet_ =
                                                            removeNode neighborPos accOpenSet
                                                                |> (::) updatedNode
                                                    in
                                                    ( newOpenSet_, Dict.insert neighborPos currentNode.position accParentMap )

                                                else
                                                    ( accOpenSet, accParentMap )

                                            Nothing ->
                                                -- Add new node to open set
                                                let
                                                    newNode =
                                                        { position = neighborPos
                                                        , gCost = tentativeGCost
                                                        , hCost = octileDistance neighborPos goal
                                                        , parent = Just currentNode.position
                                                        }
                                                in
                                                ( newNode :: accOpenSet, Dict.insert neighborPos currentNode.position accParentMap )
                                    )
                                    ( newOpenSet, parentMap )
                                    neighbors
                        in
                        astar updatedOpenSet newClosedSet updatedParentMap

        -- Initialize with start node
        startNode =
            { position = start
            , gCost = 0
            , hCost = octileDistance start goal
            , parent = Nothing
            }
    in
    if start == goal then
        []

    else if not (isWalkable goal) then
        -- Goal is not walkable
        []

    else
        astar [ startNode ] [] Dict.empty


{-| Calculate path for a unit from its current position to a target grid cell
-}
calculateUnitPath : GridConfig -> MapConfig -> Dict ( Int, Int ) Int -> Float -> Float -> ( Int, Int ) -> List ( Int, Int )
calculateUnitPath gridConfig mapConfig occupancy unitX unitY targetCell =
    let
        -- Get current pathfinding cell of the unit
        currentCell =
            ( floor (unitX / gridConfig.pathfindingGridSize)
            , floor (unitY / gridConfig.pathfindingGridSize)
            )

        path =
            findPath gridConfig mapConfig occupancy currentCell targetCell
    in
    path
