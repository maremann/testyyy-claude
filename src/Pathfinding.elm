module Pathfinding exposing
    ( calculateUnitPath
    , findPath
    )
import Dict exposing (Dict)
import Grid exposing (isPathfindingCellOccupied)
import Types exposing (GridConfig, MapConfig)
type alias PathNode = { position : ( Int, Int )
    , gCost : Float
    , hCost : Float
    , parent : Maybe ( Int, Int )
    }
octileDistance : ( Int, Int ) -> ( Int, Int ) -> Float
octileDistance ( x1, y1 ) ( x2, y2 ) =
    let
        dx = abs (x1 - x2)
        dy = abs (y1 - y2)
        minDist = min dx dy
        maxDist = max dx dy
    in
    toFloat minDist * 1.414 + toFloat (maxDist - minDist)
getNeighbors : ( Int, Int ) -> List ( ( Int, Int ), Float )
getNeighbors ( x, y ) = [ ( ( x + 1, y ), 1.0 ) -- Right
    , ( ( x - 1, y ), 1.0 ) -- Left
    , ( ( x, y + 1 ), 1.0 ) -- Down
    , ( ( x, y - 1 ), 1.0 ) -- Up
    , ( ( x + 1, y + 1 ), 1.414 ) -- Down-Right
    , ( ( x + 1, y - 1 ), 1.414 ) -- Up-Right
    , ( ( x - 1, y + 1 ), 1.414 ) -- Down-Left
    , ( ( x - 1, y - 1 ), 1.414 ) -- Up-Left
    ]
findNode : ( Int, Int ) -> List PathNode -> Maybe PathNode
findNode pos nodes = List.filter (\n -> n.position == pos) nodes
        |> List.head
removeNode : ( Int, Int ) -> List PathNode -> List PathNode
removeNode pos nodes = List.filter (\n -> n.position /= pos) nodes
getLowestFCostNode : List PathNode -> Maybe PathNode
getLowestFCostNode nodes =
    case nodes of
        [] -> Nothing
        _ -> List.sortBy (\n -> n.gCost + n.hCost) nodes
                |> List.head
reconstructPath : ( Int, Int ) -> Dict ( Int, Int ) ( Int, Int ) -> List ( Int, Int )
reconstructPath endPos parentMap =
    let
        buildPath current acc =
            case Dict.get current parentMap of
                Just parent -> buildPath parent (current :: acc)
                Nothing -> current :: acc
    in
    buildPath endPos []
findPath : GridConfig -> MapConfig -> Dict ( Int, Int ) Int -> ( Int, Int ) -> ( Int, Int ) -> List ( Int, Int )
findPath gridConfig mapConfig occupancy start goal =
    let
        isWalkable ( x, y ) =
            let
                worldX = toFloat x * gridConfig.pathfindingGridSize
                worldY = toFloat y * gridConfig.pathfindingGridSize
                inBounds =
                    worldX >= 0 && worldX < mapConfig.width && worldY >= 0 && worldY < mapConfig.height
            in
            inBounds && not (isPathfindingCellOccupied ( x, y ) occupancy)
        astar openSet closedSet parentMap =
            case getLowestFCostNode openSet of
                Nothing -> []
                Just currentNode ->
                    if currentNode.position == goal then
                        reconstructPath goal parentMap
                            |> List.tail
                            |> Maybe.withDefault []
                    else
                        let
                            newOpenSet = removeNode currentNode.position openSet
                            newClosedSet = currentNode.position :: closedSet
                            neighbors = getNeighbors currentNode.position
                                    |> List.filter (\( pos, _ ) -> isWalkable pos)
                                    |> List.filter (\( pos, _ ) -> not (List.member pos newClosedSet))
                            ( updatedOpenSet, updatedParentMap ) = List.foldl
                                    (\( neighborPos, moveCost ) ( accOpenSet, accParentMap ) ->
                                        let
                                            tentativeGCost = currentNode.gCost + moveCost
                                            existingNode = findNode neighborPos accOpenSet
                                        in
                                        case existingNode of
                                            Just existing ->
                                                if tentativeGCost < existing.gCost then
                                                    let
                                                        updatedNode = { position = neighborPos
                                                            , gCost = tentativeGCost
                                                            , hCost = octileDistance neighborPos goal
                                                            , parent = Just currentNode.position
                                                            }
                                                        newOpenSet_ = removeNode neighborPos accOpenSet
                                                                |> (::) updatedNode
                                                    in
                                                    ( newOpenSet_, Dict.insert neighborPos currentNode.position accParentMap )
                                                else
                                                    ( accOpenSet, accParentMap )
                                            Nothing ->
                                                let
                                                    newNode = { position = neighborPos
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
        startNode = { position = start
            , gCost = 0
            , hCost = octileDistance start goal
            , parent = Nothing
            }
    in
    if start == goal then
        []
    else if not (isWalkable goal) then
        []
    else
        astar [ startNode ] [] Dict.empty
calculateUnitPath : GridConfig -> MapConfig -> Dict ( Int, Int ) Int -> Float -> Float -> ( Int, Int ) -> List ( Int, Int )
calculateUnitPath gridConfig mapConfig occupancy unitX unitY targetCell =
    let
        currentCell = ( floor (unitX / gridConfig.pathfindingGridSize)
            , floor (unitY / gridConfig.pathfindingGridSize)
            )
        path =
            findPath gridConfig mapConfig occupancy currentCell targetCell
    in
    path
