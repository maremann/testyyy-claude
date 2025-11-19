module Model exposing (..)

import Browser.Dom as Dom
import Dict exposing (Dict)
import Random
import Task


-- MODEL


type alias TooltipState =
    { elementId : String
    , hoverTime : Float
    , mouseX : Float
    , mouseY : Float
    }


type alias Model =
    { camera : Camera
    , dragState : DragState
    , windowSize : ( Int, Int )
    , decorativeShapes : List DecorativeShape
    , mapConfig : MapConfig
    , gameState : GameState
    , gold : Int
    , selected : Maybe Selectable
    , gridConfig : GridConfig
    , showBuildGrid : Bool
    , showPathfindingGrid : Bool
    , buildings : List Building
    , buildingOccupancy : Dict ( Int, Int ) Int
    , nextBuildingId : Int
    , goldInputValue : String
    , pathfindingOccupancy : Dict ( Int, Int ) Int
    , showPathfindingOccupancy : Bool
    , buildMode : Maybe BuildingTemplate
    , mouseWorldPos : Maybe ( Float, Float )
    , showBuildingOccupancy : Bool
    , simulationFrameCount : Int
    , accumulatedTime : Float
    , lastSimulationDeltas : List Float
    , simulationSpeed : SimulationSpeed
    , units : List Unit
    , nextUnitId : Int
    , debugTab : DebugTab
    , buildingTab : BuildingTab
    , showCityActiveArea : Bool
    , showCitySearchArea : Bool
    , tooltipHover : Maybe TooltipState
    }


type GameState
    = PreGame
    | Playing
    | GameOver


type SimulationSpeed
    = Pause
    | Speed1x
    | Speed2x
    | Speed10x
    | Speed100x


type DebugTab
    = StatsTab
    | VisualizationTab
    | ControlsTab


type BuildingTab
    = MainTab
    | InfoTab


type UnitBehavior
    = Dead
    | DebugError String
    | WithoutHome
    | LookingForTask
    | GoingToSleep
    | Sleeping
    | LookForBuildRepairTarget
    | MovingToBuildRepairTarget
    | Repairing
    | LookForTaxTarget
    | CollectingTaxes
    | ReturnToCastle
    | DeliveringGold


type BuildingBehavior
    = Idle
    | UnderConstruction
    | SpawnHouse
    | GenerateGold
    | BuildingDead
    | BuildingDebugError String


type UnitKind
    = Hero
    | Henchman


type Tag
    = BuildingTag
    | HeroTag
    | HenchmanTag
    | GuildTag
    | ObjectiveTag
    | CofferTag


type Selectable
    = GlobalButtonDebug
    | GlobalButtonBuild
    | BuildingSelected Int
    | UnitSelected Int


type BuildingSize
    = Small
    | Medium
    | Large
    | Huge


type BuildingOwner
    = Player
    | Enemy


type alias GarrisonSlotConfig =
    { unitType : String
    , maxCount : Int
    , currentCount : Int
    , spawnTimer : Float
    }


type alias Building =
    { id : Int
    , owner : BuildingOwner
    , gridX : Int
    , gridY : Int
    , size : BuildingSize
    , hp : Int
    , maxHp : Int
    , garrisonSlots : Int
    , garrisonOccupied : Int
    , buildingType : String
    , behavior : BuildingBehavior
    , behaviorTimer : Float
    , behaviorDuration : Float
    , coffer : Int
    , garrisonConfig : List GarrisonSlotConfig
    , activeRadius : Float
    , searchRadius : Float
    , tags : List Tag
    }


type alias BuildingTemplate =
    { name : String
    , size : BuildingSize
    , cost : Int
    , maxHp : Int
    , garrisonSlots : Int
    }


type UnitLocation
    = OnMap Float Float
    | Garrisoned Int


type alias Unit =
    { id : Int
    , owner : BuildingOwner
    , location : UnitLocation
    , hp : Int
    , maxHp : Int
    , movementSpeed : Float
    , unitType : String
    , unitKind : UnitKind
    , color : String
    , path : List ( Int, Int )
    , behavior : UnitBehavior
    , behaviorTimer : Float
    , behaviorDuration : Float
    , thinkingTimer : Float
    , thinkingDuration : Float
    , homeBuilding : Maybe Int
    , carriedGold : Int
    , targetDestination : Maybe ( Int, Int )
    , activeRadius : Float
    , searchRadius : Float
    , tags : List Tag
    }


type alias Camera =
    { x : Float
    , y : Float
    }


type DragState
    = NotDragging
    | DraggingViewport Position
    | DraggingMinimap Position


type alias Position =
    { x : Float
    , y : Float
    }


type alias DecorativeShape =
    { x : Float
    , y : Float
    , size : Float
    , shapeType : ShapeType
    , color : String
    }


type ShapeType
    = Circle
    | Rectangle


type alias MapConfig =
    { width : Float
    , height : Float
    , boundary : Float
    }


type alias GridConfig =
    { buildGridSize : Float
    , pathfindingGridSize : Float
    }



-- BUILDING TEMPLATES


testBuildingTemplate : BuildingTemplate
testBuildingTemplate =
    { name = "Test Building"
    , size = Medium
    , cost = 500
    , maxHp = 500
    , garrisonSlots = 5
    }


castleTemplate : BuildingTemplate
castleTemplate =
    { name = "Castle"
    , size = Huge
    , cost = 10000
    , maxHp = 5000
    , garrisonSlots = 6
    }


houseTemplate : BuildingTemplate
houseTemplate =
    { name = "House"
    , size = Medium
    , cost = 0
    , maxHp = 500
    , garrisonSlots = 0
    }


warriorsGuildTemplate : BuildingTemplate
warriorsGuildTemplate =
    { name = "Warrior's Guild"
    , size = Large
    , cost = 1500
    , maxHp = 1000
    , garrisonSlots = 0
    }


buildingSizeToGridCells : BuildingSize -> Int
buildingSizeToGridCells size =
    case size of
        Small ->
            1

        Medium ->
            2

        Large ->
            3

        Huge ->
            4


{-| Generate a random color string for units -}
randomUnitColor : Random.Generator String
randomUnitColor =
    let
        colors =
            [ "#FF6B6B"
            , "#4ECDC4"
            , "#45B7D1"
            , "#FFA07A"
            , "#98D8C8"
            , "#F7DC6F"
            , "#BB8FCE"
            , "#85C1E2"
            , "#F8B739"
            , "#52C41A"
            ]

        randomIndex =
            Random.int 0 (List.length colors - 1)
    in
    Random.map
        (\idx ->
            List.drop idx colors
                |> List.head
                |> Maybe.withDefault "#FF6B6B"
        )
        randomIndex



-- BUILDING GRID OCCUPANCY


{-| Get the build grid cells occupied by a building (includes 1-cell spacing requirement) -}
getBuildingGridCellsWithSpacing : Building -> List ( Int, Int )
getBuildingGridCellsWithSpacing building =
    let
        sizeCells =
            buildingSizeToGridCells building.size

        -- Include 1-cell border for spacing requirement
        startX =
            building.gridX - 1

        startY =
            building.gridY - 1

        endX =
            building.gridX + sizeCells

        endY =
            building.gridY + sizeCells

        xs =
            List.range startX endX

        ys =
            List.range startY endY
    in
    List.concatMap (\x -> List.map (\y -> ( x, y )) ys) xs


{-| Get the build grid cells actually occupied by a building (no spacing) -}
getBuildingGridCells : Building -> List ( Int, Int )
getBuildingGridCells building =
    let
        sizeCells =
            buildingSizeToGridCells building.size

        xs =
            List.range building.gridX (building.gridX + sizeCells - 1)

        ys =
            List.range building.gridY (building.gridY + sizeCells - 1)
    in
    List.concatMap (\x -> List.map (\y -> ( x, y )) ys) xs


{-| Add a building's occupancy to the building grid -}
addBuildingGridOccupancy : Building -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
addBuildingGridOccupancy building occupancy =
    let
        cells =
            getBuildingGridCells building

        incrementCell cell dict =
            Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            Just (count + 1)

                        Nothing ->
                            Just 1
                )
                dict
    in
    List.foldl incrementCell occupancy cells


{-| Remove a building's occupancy from the building grid -}
removeBuildingGridOccupancy : Building -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
removeBuildingGridOccupancy building occupancy =
    let
        cells =
            getBuildingGridCells building

        decrementCell cell dict =
            Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            if count <= 1 then
                                Nothing

                            else
                                Just (count - 1)

                        Nothing ->
                            Nothing
                )
                dict
    in
    List.foldl decrementCell occupancy cells


{-| Check if any build grid cells are occupied (for placement validation) -}
areBuildGridCellsOccupied : List ( Int, Int ) -> Dict ( Int, Int ) Int -> Bool
areBuildGridCellsOccupied cells occupancy =
    List.any (\cell -> Dict.member cell occupancy) cells


{-| Check if a building placement is valid -}
isValidBuildingPlacement : Int -> Int -> BuildingSize -> MapConfig -> GridConfig -> Dict ( Int, Int ) Int -> List Building -> Bool
isValidBuildingPlacement gridX gridY size mapConfig gridConfig buildingOccupancy buildings =
    let
        sizeCells =
            buildingSizeToGridCells size

        -- Check map bounds
        maxGridX =
            floor (mapConfig.width / gridConfig.buildGridSize)

        maxGridY =
            floor (mapConfig.height / gridConfig.buildGridSize)

        inBounds =
            gridX >= 0
                && gridY >= 0
                && (gridX + sizeCells) <= maxGridX
                && (gridY + sizeCells) <= maxGridY

        -- Check occupancy (including 1-cell spacing)
        tempBuilding =
            { id = 0
            , owner = Player
            , gridX = gridX
            , gridY = gridY
            , size = size
            , hp = 0
            , maxHp = 0
            , garrisonSlots = 0
            , garrisonOccupied = 0
            , buildingType = ""
            , behavior = Idle
            , behaviorTimer = 0
            , behaviorDuration = 0
            , coffer = 0
            , garrisonConfig = []
            , activeRadius = 192
            , searchRadius = 384
            , tags = [ BuildingTag ]
            }

        cellsWithSpacing =
            getBuildingGridCellsWithSpacing tempBuilding

        notOccupied =
            not (areBuildGridCellsOccupied cellsWithSpacing buildingOccupancy)

        -- Check if at least half the building tiles are within city search area
        buildingCells =
            getBuildingGridCells tempBuilding

        citySearchArea =
            getCitySearchArea buildings

        searchAreaSet =
            List.foldl (\cell acc -> Dict.insert cell () acc) Dict.empty citySearchArea

        tilesInSearchArea =
            List.filter (\cell -> Dict.member cell searchAreaSet) buildingCells
                |> List.length

        totalTiles =
            List.length buildingCells

        atLeastHalfInSearchArea =
            -- If there are no buildings yet, allow placement anywhere
            if List.isEmpty buildings then
                True
            else
                toFloat tilesInSearchArea >= toFloat totalTiles / 2
    in
    inBounds && notOccupied && atLeastHalfInSearchArea



-- PATHFINDING OCCUPANCY


{-| Calculate which pathfinding grid cells a building occupies.
    Returns a list of (x, y) coordinates in pathfinding grid space.
-}
getBuildingPathfindingCells : GridConfig -> Building -> List ( Int, Int )
getBuildingPathfindingCells gridConfig building =
    let
        -- Building position in world pixels
        buildingWorldX =
            toFloat building.gridX * gridConfig.buildGridSize

        buildingWorldY =
            toFloat building.gridY * gridConfig.buildGridSize

        -- Building size in world pixels
        buildingSizeCells =
            buildingSizeToGridCells building.size

        buildingWorldWidth =
            toFloat buildingSizeCells * gridConfig.buildGridSize

        buildingWorldHeight =
            toFloat buildingSizeCells * gridConfig.buildGridSize

        -- Convert to pathfinding grid coordinates
        startPfX =
            floor (buildingWorldX / gridConfig.pathfindingGridSize)

        startPfY =
            floor (buildingWorldY / gridConfig.pathfindingGridSize)

        endPfX =
            floor ((buildingWorldX + buildingWorldWidth - 1) / gridConfig.pathfindingGridSize)

        endPfY =
            floor ((buildingWorldY + buildingWorldHeight - 1) / gridConfig.pathfindingGridSize)

        -- Generate all cells
        xs =
            List.range startPfX endPfX

        ys =
            List.range startPfY endPfY
    in
    List.concatMap (\x -> List.map (\y -> ( x, y )) ys) xs


{-| Get the entrance tile coordinates for a building in build grid space.
    - Small (1x1): The tile itself (gridX, gridY)
    - Medium (2x2): Bottom left tile (gridX, gridY + 1)
    - Large (3x3): Bottom center tile (gridX + 1, gridY + 2)
    - Huge (4x4): Bottom middle-left tile (gridX + 1, gridY + 3)
-}
getBuildingEntrance : Building -> ( Int, Int )
getBuildingEntrance building =
    case building.size of
        Small ->
            ( building.gridX, building.gridY )

        Medium ->
            ( building.gridX, building.gridY + 1 )

        Large ->
            ( building.gridX + 1, building.gridY + 2 )

        Huge ->
            ( building.gridX + 1, building.gridY + 3 )


{-| Find a valid adjacent location to spawn a House near existing buildings.
    Returns Nothing if no valid location found.
-}
findAdjacentHouseLocation : MapConfig -> GridConfig -> List Building -> Dict ( Int, Int ) Int -> Maybe ( Int, Int )
findAdjacentHouseLocation mapConfig gridConfig buildings buildingOccupancy =
    let
        houseSize =
            Medium

        -- Get all cells adjacent to all buildings (with 1 cell spacing)
        adjacentCells =
            buildings
                |> List.concatMap (\b -> getBuildingAreaCells b 1)
                |> List.filter (\( gx, gy ) ->
                    -- Check if this would be valid for a house
                    isValidBuildingPlacement gx gy houseSize mapConfig gridConfig buildingOccupancy buildings
                )
                |> List.take 100  -- Limit to first 100 candidates for performance

        -- Pick the first valid one (could randomize in future)
    in
    List.head adjacentCells


{-| Calculate all build grid cells within a certain distance (in build grid cells) of a building.
    Returns a list of (gridX, gridY) coordinates.
-}
getBuildingAreaCells : Building -> Int -> List ( Int, Int )
getBuildingAreaCells building radiusInCells =
    let
        -- Get building center in build grid coordinates
        sizeCells =
            buildingSizeToGridCells building.size

        centerX =
            building.gridX + sizeCells // 2

        centerY =
            building.gridY + sizeCells // 2

        -- Generate all cells within radius
        minX =
            centerX - radiusInCells

        maxX =
            centerX + radiusInCells

        minY =
            centerY - radiusInCells

        maxY =
            centerY + radiusInCells

        allCells =
            List.concatMap
                (\x ->
                    List.map (\y -> ( x, y ))
                        (List.range minY maxY)
                )
                (List.range minX maxX)
    in
    allCells


{-| Calculate city active area: all build grid cells within 3 cells of any friendly building -}
getCityActiveArea : List Building -> List ( Int, Int )
getCityActiveArea buildings =
    buildings
        |> List.filter (\b -> b.owner == Player)
        |> List.concatMap (\b -> getBuildingAreaCells b 3)
        |> List.foldl (\cell acc -> Dict.insert cell () acc) Dict.empty
        |> Dict.keys


{-| Calculate city search area: all build grid cells within 6 cells of any friendly building -}
getCitySearchArea : List Building -> List ( Int, Int )
getCitySearchArea buildings =
    buildings
        |> List.filter (\b -> b.owner == Player)
        |> List.concatMap (\b -> getBuildingAreaCells b 6)
        |> List.foldl (\cell acc -> Dict.insert cell () acc) Dict.empty
        |> Dict.keys


{-| Add a building's occupancy to the pathfinding grid -}
addBuildingOccupancy : GridConfig -> Building -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
addBuildingOccupancy gridConfig building occupancy =
    let
        cells =
            getBuildingPathfindingCells gridConfig building

        incrementCell cell dict =
            Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            Just (count + 1)

                        Nothing ->
                            Just 1
                )
                dict
    in
    List.foldl incrementCell occupancy cells


{-| Remove a building's occupancy from the pathfinding grid -}
removeBuildingOccupancy : GridConfig -> Building -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
removeBuildingOccupancy gridConfig building occupancy =
    let
        cells =
            getBuildingPathfindingCells gridConfig building

        decrementCell cell dict =
            Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            if count <= 1 then
                                Nothing

                            else
                                Just (count - 1)

                        Nothing ->
                            Nothing
                )
                dict
    in
    List.foldl decrementCell occupancy cells


{-| Check if a pathfinding grid cell is occupied -}
isPathfindingCellOccupied : ( Int, Int ) -> Dict ( Int, Int ) Int -> Bool
isPathfindingCellOccupied cell occupancy =
    case Dict.get cell occupancy of
        Just count ->
            count > 0

        Nothing ->
            False



-- UNIT OCCUPANCY


{-| Calculate which pathfinding grid cells a unit occupies.
    Unit diameter is half a pathfinding cell (16 pixels when pathfinding cell is 32).
    A unit occupies all cells it touches.
-}
getUnitPathfindingCells : GridConfig -> Float -> Float -> List ( Int, Int )
getUnitPathfindingCells gridConfig worldX worldY =
    let
        -- Unit radius is quarter of pathfinding grid (8 pixels)
        unitRadius =
            gridConfig.pathfindingGridSize / 4

        -- Bounding box of the unit
        minX =
            worldX - unitRadius

        maxX =
            worldX + unitRadius

        minY =
            worldY - unitRadius

        maxY =
            worldY + unitRadius

        -- Convert to pathfinding grid coordinates
        startPfX =
            floor (minX / gridConfig.pathfindingGridSize)

        endPfX =
            floor (maxX / gridConfig.pathfindingGridSize)

        startPfY =
            floor (minY / gridConfig.pathfindingGridSize)

        endPfY =
            floor (maxY / gridConfig.pathfindingGridSize)

        -- Generate all cells
        xs =
            List.range startPfX endPfX

        ys =
            List.range startPfY endPfY
    in
    List.concatMap (\x -> List.map (\y -> ( x, y )) ys) xs


{-| Add a unit's occupancy to the pathfinding grid -}
addUnitOccupancy : GridConfig -> Float -> Float -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
addUnitOccupancy gridConfig worldX worldY occupancy =
    let
        cells =
            getUnitPathfindingCells gridConfig worldX worldY

        incrementCell cell dict =
            Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            Just (count + 1)

                        Nothing ->
                            Just 1
                )
                dict
    in
    List.foldl incrementCell occupancy cells


{-| Remove a unit's occupancy from the pathfinding grid -}
removeUnitOccupancy : GridConfig -> Float -> Float -> Dict ( Int, Int ) Int -> Dict ( Int, Int ) Int
removeUnitOccupancy gridConfig worldX worldY occupancy =
    let
        cells =
            getUnitPathfindingCells gridConfig worldX worldY

        decrementCell cell dict =
            Dict.update cell
                (\maybeCount ->
                    case maybeCount of
                        Just count ->
                            if count <= 1 then
                                Nothing

                            else
                                Just (count - 1)

                        Nothing ->
                            Nothing
                )
                dict
    in
    List.foldl decrementCell occupancy cells


{-| Find the nearest unoccupied pathfinding cell to a given world position -}
findNearestUnoccupiedTile : GridConfig -> MapConfig -> Dict ( Int, Int ) Int -> Float -> Float -> ( Float, Float )
findNearestUnoccupiedTile gridConfig mapConfig occupancy targetX targetY =
    let
        -- Convert target to pathfinding grid
        targetPfX =
            floor (targetX / gridConfig.pathfindingGridSize)

        targetPfY =
            floor (targetY / gridConfig.pathfindingGridSize)

        -- Search in expanding rings
        searchRadius maxRadius currentRadius =
            if currentRadius > maxRadius then
                -- Fallback to center if no unoccupied cell found
                ( targetX, targetY )

            else
                let
                    -- Generate cells in a ring at currentRadius
                    ringCells =
                        if currentRadius == 0 then
                            [ ( targetPfX, targetPfY ) ]

                        else
                            List.range -currentRadius currentRadius
                                |> List.concatMap
                                    (\dx ->
                                        List.range -currentRadius currentRadius
                                            |> List.filterMap
                                                (\dy ->
                                                    if abs dx == currentRadius || abs dy == currentRadius then
                                                        Just ( targetPfX + dx, targetPfY + dy )

                                                    else
                                                        Nothing
                                                )
                                    )

                    -- Find first unoccupied cell in ring
                    unoccupiedCell =
                        ringCells
                            |> List.filter
                                (\cell ->
                                    not (isPathfindingCellOccupied cell occupancy)
                                        && isWithinMapBounds gridConfig mapConfig cell
                                )
                            |> List.head
                in
                case unoccupiedCell of
                    Just ( pfX, pfY ) ->
                        -- Convert back to world coordinates (center of cell)
                        ( toFloat pfX * gridConfig.pathfindingGridSize + gridConfig.pathfindingGridSize / 2
                        , toFloat pfY * gridConfig.pathfindingGridSize + gridConfig.pathfindingGridSize / 2
                        )

                    Nothing ->
                        searchRadius maxRadius (currentRadius + 1)

        isWithinMapBounds : GridConfig -> MapConfig -> ( Int, Int ) -> Bool
        isWithinMapBounds gc mc ( pfX, pfY ) =
            let
                worldX =
                    toFloat pfX * gc.pathfindingGridSize

                worldY =
                    toFloat pfY * gc.pathfindingGridSize
            in
            worldX >= 0 && worldX < mc.width && worldY >= 0 && worldY < mc.height
    in
    searchRadius 50 0



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
    [ ( ( x + 1, y ), 1.0 )       -- Right
    , ( ( x - 1, y ), 1.0 )       -- Left
    , ( ( x, y + 1 ), 1.0 )       -- Down
    , ( ( x, y - 1 ), 1.0 )       -- Up
    , ( ( x + 1, y + 1 ), 1.414 ) -- Down-Right
    , ( ( x + 1, y - 1 ), 1.414 ) -- Up-Right
    , ( ( x - 1, y + 1 ), 1.414 ) -- Down-Left
    , ( ( x - 1, y - 1 ), 1.414 ) -- Up-Left
    ]


{-| Find a node in a list by position -}
findNode : ( Int, Int ) -> List PathNode -> Maybe PathNode
findNode pos nodes =
    List.filter (\n -> n.position == pos) nodes
        |> List.head


{-| Remove a node from a list -}
removeNode : ( Int, Int ) -> List PathNode -> List PathNode
removeNode pos nodes =
    List.filter (\n -> n.position /= pos) nodes


{-| Get the node with the lowest fCost from a list -}
getLowestFCostNode : List PathNode -> Maybe PathNode
getLowestFCostNode nodes =
    case nodes of
        [] ->
            Nothing

        _ ->
            List.sortBy (\n -> n.gCost + n.hCost) nodes
                |> List.head


{-| Reconstruct path from end node back to start -}
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


{-| A* pathfinding algorithm
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


{-| Calculate path for a unit from its current position to a target grid cell -}
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



-- UNIT MOVEMENT AND BEHAVIOR


{-| Update a unit's position, moving it along its path. Recalculates path when reaching intermediate cells. -}
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


{-| Generate a random target cell within radius of current position -}
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
                                            distance < 32  -- Within half a build grid cell
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
                                        OnMap x y -> ( x, y )
                                        _ -> ( 0, 0 )  -- Shouldn't happen
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
                                    , True  -- Request path
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
                            , True  -- Request path
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


{-| Update building behavior based on timer
    Returns (Building, Bool) where Bool indicates if a house should be spawned
-}
updateBuildingBehavior : Float -> Building -> ( Building, Bool )
updateBuildingBehavior deltaSeconds building =
    case building.behavior of
        Idle ->
            ( building, False )

        UnderConstruction ->
            -- Not implemented yet
            ( building, False )

        SpawnHouse ->
            let
                newTimer =
                    building.behaviorTimer + deltaSeconds
            in
            if newTimer >= building.behaviorDuration then
                -- Time to spawn a house
                -- Reset timer with new pseudo-random duration (30-45s)
                let
                    -- Use building ID and current timer to generate pseudo-random duration
                    randomValue =
                        toFloat (modBy 15000 (building.id * 1000 + round (building.behaviorTimer * 1000)))
                            / 1000.0

                    newDuration =
                        30.0 + randomValue
                in
                ( { building | behaviorTimer = 0, behaviorDuration = newDuration }, True )

            else
                ( { building | behaviorTimer = newTimer }, False )

        GenerateGold ->
            let
                newTimer =
                    building.behaviorTimer + deltaSeconds
            in
            if newTimer >= building.behaviorDuration then
                -- Time to generate gold
                -- Reset timer with new pseudo-random duration (15-45s)
                let
                    -- Use building ID and current timer to generate pseudo-random values
                    randomSeed =
                        building.id * 1000 + round (building.behaviorTimer * 1000)

                    durationRandomValue =
                        toFloat (modBy 30000 randomSeed) / 1000.0

                    newDuration =
                        15.0 + durationRandomValue

                    -- Different gold amounts for House (45-90) vs Guild (450-900)
                    ( minGold, maxGold ) =
                        if building.buildingType == "House" then
                            ( 45, 90 )

                        else
                            ( 450, 900 )

                    goldRange =
                        maxGold - minGold

                    goldRandomValue =
                        modBy (goldRange + 1) (randomSeed + 12345)

                    goldAmount =
                        minGold + goldRandomValue
                in
                ( { building | behaviorTimer = 0, behaviorDuration = newDuration, coffer = building.coffer + goldAmount }, False )

            else
                ( { building | behaviorTimer = newTimer }, False )

        BuildingDead ->
            ( building, False )

        BuildingDebugError _ ->
            ( building, False )


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


{-| Recalculate paths for all units (called when occupancy changes) -}
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
