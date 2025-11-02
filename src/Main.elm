module Main exposing (..)

import Browser
import Browser.Dom as Dom
import Browser.Events as E
import Debug
import Dict exposing (Dict)
import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Html.Events exposing (on, stopPropagationOn)
import Json.Decode as D
import Random
import Task


-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



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
    = Thinking
    | FindingRandomTarget
    | MovingTowardTarget
    | Dead
    | DebugError String
    | WithoutHome
    | LookingForTask
    | GoingToSleep
    | Sleeping
    | LookForBuildRepairTarget
    | BuildingConstruction
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


init : () -> ( Model, Cmd Msg )
init _ =
    let
        mapConfig =
            { width = 4992
            , height = 4992
            , boundary = 500
            }

        gridConfig =
            { buildGridSize = 64
            , pathfindingGridSize = 32
            }

        initialModel =
            { camera = { x = 2496, y = 2496 }
            , dragState = NotDragging
            , windowSize = ( 800, 600 )
            , decorativeShapes = []
            , mapConfig = mapConfig
            , gameState = PreGame
            , gold = 10000
            , selected = Nothing
            , gridConfig = gridConfig
            , showBuildGrid = False
            , showPathfindingGrid = False
            , buildings = []
            , buildingOccupancy = Dict.empty
            , nextBuildingId = 1
            , goldInputValue = ""
            , pathfindingOccupancy = Dict.empty
            , showPathfindingOccupancy = False
            , buildMode = Nothing
            , mouseWorldPos = Nothing
            , showBuildingOccupancy = False
            , simulationFrameCount = 0
            , accumulatedTime = 0
            , lastSimulationDeltas = []
            , simulationSpeed = Speed1x
            , units = []
            , nextUnitId = 1
            , debugTab = StatsTab
            , buildingTab = MainTab
            , showCityActiveArea = False
            , showCitySearchArea = False
            , tooltipHover = Nothing
            }
    in
    ( initialModel
    , Cmd.batch
        [ Random.generate ShapesGenerated (generateShapes 150 mapConfig)
        , Task.perform GotViewport Dom.getViewport
        ]
    )



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
    in
    findPath gridConfig mapConfig occupancy currentCell targetCell



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
    - Thinking: Increment timer, transition to FindingRandomTarget after 1-2 seconds
    - FindingRandomTarget: Request new path generation (handled by caller)
    - MovingTowardTarget: When path is empty (destination reached), transition to Thinking
-}
updateUnitBehavior : Float -> Unit -> ( Unit, Bool )
updateUnitBehavior deltaSeconds unit =
    case unit.behavior of
        Thinking ->
            let
                newTimer =
                    unit.thinkingTimer + deltaSeconds
            in
            if newTimer >= unit.thinkingDuration then
                -- Transition to FindingRandomTarget
                ( { unit | behavior = FindingRandomTarget, thinkingTimer = 0 }, True )

            else
                -- Still thinking
                ( { unit | thinkingTimer = newTimer }, False )

        FindingRandomTarget ->
            -- This state is briefly entered to trigger path generation
            -- The unit will be transitioned to MovingTowardTarget when path is assigned
            ( unit, False )

        MovingTowardTarget ->
            -- Check if destination reached (path is empty)
            if List.isEmpty unit.path then
                -- Transition back to Thinking, clear target destination
                -- Random duration between 1.0 and 2.0 seconds (using unit ID as seed for variety)
                let
                    newThinkingDuration =
                        1.0 + (toFloat (modBy 1000 unit.id) / 1000.0)
                in
                ( { unit | behavior = Thinking, thinkingTimer = 0, thinkingDuration = newThinkingDuration, targetDestination = Nothing }, False )

            else
                -- Still moving
                ( unit, False )

        Dead ->
            -- Dead units don't change behavior
            ( unit, False )

        DebugError _ ->
            -- Error state, don't change behavior
            ( unit, False )

        WithoutHome ->
            -- Unit without home, don't change behavior
            ( unit, False )

        LookingForTask ->
            -- Looking for task, don't change behavior
            ( unit, False )

        GoingToSleep ->
            -- Going to sleep, don't change behavior
            ( unit, False )

        Sleeping ->
            -- Sleeping, don't change behavior
            ( unit, False )

        LookForBuildRepairTarget ->
            -- Looking for build/repair target, don't change behavior
            ( unit, False )

        BuildingConstruction ->
            -- Building construction, don't change behavior
            ( unit, False )

        Repairing ->
            -- Repairing, don't change behavior
            ( unit, False )

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
    in
    ( { building | garrisonConfig = List.reverse updatedConfig }, List.reverse unitsToSpawn )


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



-- UPDATE


type Msg
    = WindowResize Int Int
    | MouseDown Float Float
    | MouseMove Float Float
    | MouseUp
    | MinimapMouseDown Float Float
    | MinimapMouseMove Float Float
    | ShapesGenerated (List DecorativeShape)
    | GotViewport Dom.Viewport
    | SelectThing Selectable
    | ToggleBuildGrid
    | TogglePathfindingGrid
    | GoldInputChanged String
    | SetGoldFromInput
    | TogglePathfindingOccupancy
    | EnterBuildMode BuildingTemplate
    | ExitBuildMode
    | WorldMouseMove Float Float
    | PlaceBuilding
    | ToggleBuildingOccupancy
    | ToggleCityActiveArea
    | ToggleCitySearchArea
    | TooltipEnter String Float Float
    | TooltipLeave
    | Frame Float
    | SetSimulationSpeed SimulationSpeed
    | SpawnTestUnit
    | TestUnitColorGenerated String
    | AssignUnitDestination Int ( Int, Int )
    | SetDebugTab DebugTab
    | SetBuildingTab BuildingTab
    | PlaceTestBuilding


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WindowResize width height ->
            ( { model | windowSize = ( width, height ) }, Cmd.none )

        MouseDown x y ->
            ( { model | dragState = DraggingViewport { x = x, y = y } }, Cmd.none )

        MouseMove x y ->
            case model.dragState of
                DraggingViewport startPos ->
                    let
                        dx =
                            startPos.x - x

                        dy =
                            startPos.y - y

                        newCamera =
                            constrainCamera model.mapConfig model.windowSize
                                { x = model.camera.x + dx
                                , y = model.camera.y + dy
                                }
                    in
                    ( { model
                        | camera = newCamera
                        , dragState = DraggingViewport { x = x, y = y }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        MouseUp ->
            ( { model | dragState = NotDragging }, Cmd.none )

        MinimapMouseDown clientX clientY ->
            let
                -- Convert global clientX/clientY to minimap-relative coordinates
                ( winWidth, winHeight ) =
                    model.windowSize

                minimapWidth =
                    200

                minimapHeight =
                    150

                minimapLeft =
                    toFloat winWidth - 20 - 204 + 2

                minimapTop =
                    toFloat winHeight - 20 - 154 + 2

                offsetX =
                    clamp 0 (toFloat minimapWidth) (clientX - minimapLeft)

                offsetY =
                    clamp 0 (toFloat minimapHeight) (clientY - minimapTop)

                minimapConfig =
                    { width = 200
                    , height = 150
                    , padding = 10
                    }

                clickedOnViewbox =
                    isClickOnViewbox model minimapConfig offsetX offsetY

                ( newCamera, dragOffset ) =
                    if clickedOnViewbox then
                        -- Clicked on viewbox: maintain offset
                        ( model.camera, minimapClickOffset model minimapConfig offsetX offsetY )

                    else
                        -- Clicked on background: center the camera
                        let
                            centered =
                                centerCameraOnMinimapClick model minimapConfig offsetX offsetY
                                    |> constrainCamera model.mapConfig model.windowSize

                            scale =
                                getMinimapScale minimapConfig model.mapConfig

                            -- Offset is half the viewport size in minimap coordinates
                            -- because we centered the click point
                            centerOffset =
                                { x = toFloat winWidth * scale / 2
                                , y = toFloat winHeight * scale / 2
                                }
                        in
                        ( centered, centerOffset )
            in
            ( { model | camera = newCamera, dragState = DraggingMinimap dragOffset }, Cmd.none )

        MinimapMouseMove clientX clientY ->
            case model.dragState of
                DraggingMinimap offset ->
                    let
                        -- Convert global clientX/clientY to minimap-relative coordinates
                        ( winWidth, winHeight ) =
                            model.windowSize

                        minimapWidth =
                            200

                        minimapHeight =
                            150

                        -- Minimap is at right: 20px, bottom: 20px
                        -- Size is 200x150 + 2px border on each side = 204x154 total
                        -- offsetX/Y are measured from padding edge (inside the 2px border)
                        minimapLeft =
                            toFloat winWidth - 20 - 204 + 2

                        minimapTop =
                            toFloat winHeight - 20 - 154 + 2

                        offsetX =
                            clamp 0 (toFloat minimapWidth) (clientX - minimapLeft)

                        offsetY =
                            clamp 0 (toFloat minimapHeight) (clientY - minimapTop)

                        newCamera =
                            minimapDragToCamera model offset offsetX offsetY
                                |> constrainCamera model.mapConfig model.windowSize
                    in
                    ( { model | camera = newCamera }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ShapesGenerated shapes ->
            ( { model | decorativeShapes = shapes }, Cmd.none )

        GotViewport viewport ->
            let
                width =
                    round viewport.viewport.width

                height =
                    round viewport.viewport.height
            in
            ( { model | windowSize = ( width, height ) }, Cmd.none )

        SelectThing thing ->
            let
                -- Exit build mode when switching away from build menu
                newBuildMode =
                    case thing of
                        GlobalButtonBuild ->
                            model.buildMode

                        _ ->
                            Nothing
            in
            ( { model | selected = Just thing, buildMode = newBuildMode }, Cmd.none )

        ToggleBuildGrid ->
            ( { model | showBuildGrid = not model.showBuildGrid }, Cmd.none )

        TogglePathfindingGrid ->
            ( { model | showPathfindingGrid = not model.showPathfindingGrid }, Cmd.none )

        GoldInputChanged value ->
            ( { model | goldInputValue = value }, Cmd.none )

        SetGoldFromInput ->
            case String.toInt model.goldInputValue of
                Just amount ->
                    ( { model | gold = amount, goldInputValue = "" }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        TogglePathfindingOccupancy ->
            ( { model | showPathfindingOccupancy = not model.showPathfindingOccupancy }, Cmd.none )

        EnterBuildMode template ->
            ( { model | buildMode = Just template }, Cmd.none )

        ExitBuildMode ->
            ( { model | buildMode = Nothing }, Cmd.none )

        WorldMouseMove worldX worldY ->
            ( { model | mouseWorldPos = Just ( worldX, worldY ) }, Cmd.none )

        PlaceBuilding ->
            case ( model.buildMode, model.mouseWorldPos ) of
                ( Just template, Just ( worldX, worldY ) ) ->
                    let
                        -- Convert world coordinates to build grid coordinates
                        gridX =
                            floor (worldX / model.gridConfig.buildGridSize)

                        gridY =
                            floor (worldY / model.gridConfig.buildGridSize)

                        -- Center the building on the grid cell
                        sizeCells =
                            buildingSizeToGridCells template.size

                        centeredGridX =
                            gridX - (sizeCells // 2)

                        centeredGridY =
                            gridY - (sizeCells // 2)

                        -- Check if placement is valid
                        isValid =
                            isValidBuildingPlacement centeredGridX centeredGridY template.size model.mapConfig model.gridConfig model.buildingOccupancy model.buildings

                        -- Check if player has enough gold
                        canAfford =
                            model.gold >= template.cost
                    in
                    if isValid && canAfford then
                        let
                            -- Determine building-specific properties
                            ( buildingBehavior, buildingTags ) =
                                case template.name of
                                    "Castle" ->
                                        ( SpawnHouse, [ BuildingTag, ObjectiveTag ] )

                                    "House" ->
                                        ( GenerateGold, [ BuildingTag, CofferTag ] )

                                    "Warrior's Guild" ->
                                        ( GenerateGold, [ BuildingTag, GuildTag, CofferTag ] )

                                    _ ->
                                        ( Idle, [ BuildingTag ] )

                            -- Initialize behavior duration based on behavior type
                            initialDuration =
                                case buildingBehavior of
                                    SpawnHouse ->
                                        -- 30-45 seconds, use building ID for pseudo-random
                                        30.0 + toFloat (modBy 15000 (model.nextBuildingId * 1000)) / 1000.0

                                    GenerateGold ->
                                        -- 15-45 seconds, use building ID for pseudo-random
                                        15.0 + toFloat (modBy 30000 (model.nextBuildingId * 1000)) / 1000.0

                                    _ ->
                                        0

                            -- Initialize garrison configuration based on building type
                            initialGarrisonConfig =
                                case template.name of
                                    "Castle" ->
                                        [ { unitType = "Castle Guard", maxCount = 2, currentCount = 0, spawnTimer = 0 }
                                        , { unitType = "Tax Collector", maxCount = 1, currentCount = 0, spawnTimer = 0 }
                                        , { unitType = "Peasant", maxCount = 3, currentCount = 0, spawnTimer = 0 }
                                        ]

                                    _ ->
                                        []

                            newBuilding =
                                { id = model.nextBuildingId
                                , owner = Player
                                , gridX = centeredGridX
                                , gridY = centeredGridY
                                , size = template.size
                                , hp = template.maxHp
                                , maxHp = template.maxHp
                                , garrisonSlots = template.garrisonSlots
                                , garrisonOccupied = 0
                                , buildingType = template.name
                                , behavior = buildingBehavior
                                , behaviorTimer = 0
                                , behaviorDuration = initialDuration
                                , coffer = 0
                                , garrisonConfig = initialGarrisonConfig
                                , activeRadius = 192
                                , searchRadius = 384
                                , tags = buildingTags
                                }

                            newBuildingOccupancy =
                                addBuildingGridOccupancy newBuilding model.buildingOccupancy

                            newPathfindingOccupancy =
                                addBuildingOccupancy model.gridConfig newBuilding model.pathfindingOccupancy

                            -- Recalculate paths for all units due to occupancy change
                            updatedUnits =
                                recalculateAllPaths model.gridConfig model.mapConfig newPathfindingOccupancy model.units

                            -- Transition from PreGame to Playing when Castle is placed
                            newGameState =
                                if model.gameState == PreGame && template.name == "Castle" then
                                    Playing

                                else
                                    model.gameState
                        in
                        ( { model
                            | buildings = newBuilding :: model.buildings
                            , buildingOccupancy = newBuildingOccupancy
                            , pathfindingOccupancy = newPathfindingOccupancy
                            , nextBuildingId = model.nextBuildingId + 1
                            , gold = model.gold - template.cost
                            , buildMode = Nothing
                            , units = updatedUnits
                            , gameState = newGameState
                          }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ToggleBuildingOccupancy ->
            ( { model | showBuildingOccupancy = not model.showBuildingOccupancy }, Cmd.none )

        ToggleCityActiveArea ->
            ( { model | showCityActiveArea = not model.showCityActiveArea }, Cmd.none )

        ToggleCitySearchArea ->
            ( { model | showCitySearchArea = not model.showCitySearchArea }, Cmd.none )

        TooltipEnter elementId x y ->
            ( { model | tooltipHover = Just { elementId = elementId, hoverTime = 0, mouseX = x, mouseY = y } }, Cmd.none )

        TooltipLeave ->
            ( { model | tooltipHover = Nothing }, Cmd.none )

        SetSimulationSpeed speed ->
            ( { model | simulationSpeed = speed }, Cmd.none )

        SpawnTestUnit ->
            -- Generate random color for the unit
            ( model, Random.generate TestUnitColorGenerated randomUnitColor )

        TestUnitColorGenerated color ->
            let
                -- Get center of screen in world coordinates
                ( winWidth, winHeight ) =
                    model.windowSize

                spawnX =
                    model.camera.x + toFloat winWidth / 2

                spawnY =
                    model.camera.y + toFloat winHeight / 2

                -- Find nearest unoccupied position
                ( finalX, finalY ) =
                    findNearestUnoccupiedTile model.gridConfig model.mapConfig model.pathfindingOccupancy spawnX spawnY

                newUnit =
                    { id = model.nextUnitId
                    , owner = Player
                    , location = OnMap finalX finalY
                    , hp = 100
                    , maxHp = 100
                    , movementSpeed = 2.5
                    , unitType = "Test Unit"
                    , unitKind = Henchman
                    , color = color
                    , path = []
                    , behavior = Thinking
                    , behaviorTimer = 0
                    , behaviorDuration = 0
                    , thinkingTimer = 0
                    , thinkingDuration = 1.0 + (toFloat (modBy 1000 model.nextUnitId) / 1000.0)
                    , homeBuilding = Nothing
                    , carriedGold = 0
                    , targetDestination = Nothing
                    , activeRadius = 192
                    , searchRadius = 384
                    , tags = [ HenchmanTag ]
                    }

                -- Add unit occupancy to pathfinding grid
                newOccupancy =
                    addUnitOccupancy model.gridConfig finalX finalY model.pathfindingOccupancy
            in
            ( { model
                | units = newUnit :: model.units
                , nextUnitId = model.nextUnitId + 1
                , pathfindingOccupancy = newOccupancy
              }
            , Cmd.none
            )

        AssignUnitDestination unitId targetCell ->
            let
                -- Update the specific unit with a new path, target destination, and transition to MovingTowardTarget
                updatedUnits =
                    List.map
                        (\unit ->
                            if unit.id == unitId then
                                case unit.location of
                                    OnMap x y ->
                                        let
                                            newPath =
                                                calculateUnitPath model.gridConfig model.mapConfig model.pathfindingOccupancy x y targetCell
                                        in
                                        { unit | path = newPath, behavior = MovingTowardTarget, targetDestination = Just targetCell }

                                    Garrisoned _ ->
                                        unit

                            else
                                unit
                        )
                        model.units
            in
            ( { model | units = updatedUnits }, Cmd.none )

        SetDebugTab tab ->
            ( { model | debugTab = tab }, Cmd.none )

        SetBuildingTab tab ->
            ( { model | buildingTab = tab }, Cmd.none )

        PlaceTestBuilding ->
            let
                -- Get center of screen in world coordinates
                ( winWidth, winHeight ) =
                    model.windowSize

                centerWorldX =
                    model.camera.x + toFloat winWidth / 2

                centerWorldY =
                    model.camera.y + toFloat winHeight / 2

                -- Convert to grid coordinates
                gridX =
                    floor (centerWorldX / model.gridConfig.buildGridSize)

                gridY =
                    floor (centerWorldY / model.gridConfig.buildGridSize)

                -- Center the building on the grid cell
                template =
                    testBuildingTemplate

                sizeCells =
                    buildingSizeToGridCells template.size

                centeredGridX =
                    gridX - (sizeCells // 2)

                centeredGridY =
                    gridY - (sizeCells // 2)

                -- Check if placement is valid
                isValid =
                    isValidBuildingPlacement centeredGridX centeredGridY template.size model.mapConfig model.gridConfig model.buildingOccupancy model.buildings

                -- Check if player has enough gold
                canAfford =
                    model.gold >= template.cost
            in
            if isValid && canAfford then
                let
                    newBuilding =
                        { id = model.nextBuildingId
                        , owner = Player
                        , gridX = centeredGridX
                        , gridY = centeredGridY
                        , size = template.size
                        , hp = template.maxHp
                        , maxHp = template.maxHp
                        , garrisonSlots = template.garrisonSlots
                        , garrisonOccupied = 0
                        , buildingType = template.name
                        , behavior = Idle
                        , behaviorTimer = 0
                        , behaviorDuration = 0
                        , coffer = 0
                        , garrisonConfig = []
                        , activeRadius = 192
                        , searchRadius = 384
                        , tags = [ BuildingTag ]
                        }

                    newBuildingOccupancy =
                        addBuildingGridOccupancy newBuilding model.buildingOccupancy

                    newPathfindingOccupancy =
                        addBuildingOccupancy model.gridConfig newBuilding model.pathfindingOccupancy

                    -- Recalculate paths for all units due to occupancy change
                    updatedUnits =
                        recalculateAllPaths model.gridConfig model.mapConfig newPathfindingOccupancy model.units
                in
                ( { model
                    | buildings = newBuilding :: model.buildings
                    , buildingOccupancy = newBuildingOccupancy
                    , pathfindingOccupancy = newPathfindingOccupancy
                    , nextBuildingId = model.nextBuildingId + 1
                    , gold = model.gold - template.cost
                    , units = updatedUnits
                    , selected = Just (BuildingSelected newBuilding.id)
                  }
                , Cmd.none
                )

            else
                -- Cannot place building - invalid location or not enough gold
                ( model, Cmd.none )

        Frame delta ->
            let
                -- Update tooltip hover timer
                updatedTooltipHover =
                    case model.tooltipHover of
                        Just tooltipState ->
                            Just { tooltipState | hoverTime = tooltipState.hoverTime + delta }

                        Nothing ->
                            Nothing

                -- Pause if delta > 1000ms (indicates tab was hidden or system lag)
                isPaused =
                    delta > 1000 || model.simulationSpeed == Pause

                -- Get speed multiplier
                speedMultiplier =
                    case model.simulationSpeed of
                        Pause ->
                            0

                        Speed1x ->
                            1

                        Speed2x ->
                            2

                        Speed10x ->
                            10

                        Speed100x ->
                            100

                -- Accumulate time since last frame (scaled by speed)
                newAccumulatedTime =
                    if isPaused then
                        model.accumulatedTime

                    else
                        model.accumulatedTime + (delta * toFloat speedMultiplier)

                -- Fixed timestep: 50ms = 20 times per second
                simulationTimestep =
                    50.0

                -- Check if we should run simulation
                shouldSimulate =
                    newAccumulatedTime >= simulationTimestep && not isPaused
            in
            if shouldSimulate then
                let
                    -- Run simulation and track the delta
                    newSimulationDeltas =
                        (newAccumulatedTime :: model.lastSimulationDeltas)
                            |> List.take 3

                    -- Reset accumulated time
                    remainingTime =
                        newAccumulatedTime - simulationTimestep

                    -- Delta in seconds for this simulation frame
                    deltaSeconds =
                        simulationTimestep / 1000.0

                    -- Update unit behaviors, positions, and occupancy
                    ( updatedUnits, updatedOccupancy, unitsNeedingPaths ) =
                        List.foldl
                            (\unit ( accUnits, accOccupancy, accNeedingPaths ) ->
                                case unit.location of
                                    OnMap oldX oldY ->
                                        let
                                            -- Update behavior state
                                            ( behaviorUpdatedUnit, shouldGeneratePath ) =
                                                updateUnitBehavior deltaSeconds unit

                                            -- Remove old occupancy
                                            occupancyWithoutUnit =
                                                removeUnitOccupancy model.gridConfig oldX oldY accOccupancy

                                            -- Move unit (with path recalculation on cell arrival)
                                            movedUnit =
                                                updateUnitMovement model.gridConfig model.mapConfig occupancyWithoutUnit deltaSeconds behaviorUpdatedUnit

                                            -- Add new occupancy
                                            newOccupancyForUnit =
                                                case movedUnit.location of
                                                    OnMap newX newY ->
                                                        addUnitOccupancy model.gridConfig newX newY occupancyWithoutUnit

                                                    Garrisoned _ ->
                                                        occupancyWithoutUnit

                                            -- Collect units that need path generation
                                            needsPath =
                                                if shouldGeneratePath then
                                                    movedUnit :: accNeedingPaths

                                                else
                                                    accNeedingPaths
                                        in
                                        ( movedUnit :: accUnits, newOccupancyForUnit, needsPath )

                                    Garrisoned _ ->
                                        ( unit :: accUnits, accOccupancy, accNeedingPaths )
                            )
                            ( [], model.pathfindingOccupancy, [] )
                            model.units

                    -- Update building behaviors and garrison spawning
                    ( updatedBuildings, buildingsNeedingHouseSpawn, henchmenToSpawn ) =
                        List.foldl
                            (\building ( accBuildings, accNeedingHouseSpawn, accHenchmenSpawn ) ->
                                let
                                    ( behaviorUpdatedBuilding, shouldSpawnHouse ) =
                                        updateBuildingBehavior deltaSeconds building

                                    ( garrisonUpdatedBuilding, unitsToSpawn ) =
                                        updateGarrisonSpawning deltaSeconds behaviorUpdatedBuilding

                                    needsHouseSpawn =
                                        if shouldSpawnHouse then
                                            garrisonUpdatedBuilding :: accNeedingHouseSpawn

                                        else
                                            accNeedingHouseSpawn
                                in
                                ( garrisonUpdatedBuilding :: accBuildings, needsHouseSpawn, unitsToSpawn ++ accHenchmenSpawn )
                            )
                            ( [], [], [] )
                            model.buildings

                    -- Spawn henchmen units
                    ( newHenchmen, nextUnitIdAfterSpawning ) =
                        List.foldl
                            (\( unitType, buildingId ) ( accUnits, currentUnitId ) ->
                                -- Find the home building to get its entrance position
                                case List.filter (\b -> b.id == buildingId) updatedBuildings |> List.head of
                                    Just homeBuilding ->
                                        let
                                            newUnit =
                                                createHenchman unitType currentUnitId buildingId homeBuilding
                                        in
                                        ( newUnit :: accUnits, currentUnitId + 1 )

                                    Nothing ->
                                        -- Building not found, skip spawning
                                        ( accUnits, currentUnitId )
                            )
                            ( [], model.nextUnitId )
                            henchmenToSpawn

                    -- Combine existing units with new henchmen
                    allUnits =
                        updatedUnits ++ newHenchmen

                    -- Spawn houses for buildings that need them
                    ( ( buildingsAfterHouseSpawn, buildingOccupancyAfterHouses ), ( pathfindingOccupancyAfterHouses, nextBuildingIdAfterHouses ) ) =
                        List.foldl
                            (\castleBuilding ( ( accBuildings, accBuildOcc ), ( accPfOcc, currentBuildingId ) ) ->
                                case findAdjacentHouseLocation model.mapConfig model.gridConfig accBuildings accBuildOcc of
                                    Just ( gridX, gridY ) ->
                                        let
                                            newHouse =
                                                { id = currentBuildingId
                                                , owner = Player
                                                , gridX = gridX
                                                , gridY = gridY
                                                , size = Medium
                                                , hp = 500
                                                , maxHp = 500
                                                , garrisonSlots = 0
                                                , garrisonOccupied = 0
                                                , buildingType = "House"
                                                , behavior = GenerateGold
                                                , behaviorTimer = 0
                                                , behaviorDuration = 15.0 + toFloat (modBy 30000 (currentBuildingId * 1000)) / 1000.0
                                                , coffer = 0
                                                , garrisonConfig = []
                                                , activeRadius = 192
                                                , searchRadius = 384
                                                , tags = [ BuildingTag, CofferTag ]
                                                }

                                            newBuildOcc =
                                                addBuildingGridOccupancy newHouse accBuildOcc

                                            newPfOcc =
                                                addBuildingOccupancy model.gridConfig newHouse accPfOcc
                                        in
                                        ( ( newHouse :: accBuildings, newBuildOcc ), ( newPfOcc, currentBuildingId + 1 ) )

                                    Nothing ->
                                        -- No valid location found, skip spawning
                                        ( ( accBuildings, accBuildOcc ), ( accPfOcc, currentBuildingId ) )
                            )
                            ( ( updatedBuildings, model.buildingOccupancy ), ( updatedOccupancy, model.nextBuildingId ) )
                            buildingsNeedingHouseSpawn

                    -- Recalculate unit paths due to new house placement
                    unitsAfterHouseSpawn =
                        if List.isEmpty buildingsNeedingHouseSpawn then
                            allUnits
                        else
                            recalculateAllPaths model.gridConfig model.mapConfig pathfindingOccupancyAfterHouses allUnits

                    -- Check for Game Over (Castle destroyed)
                    newGameState =
                        if List.any (\b -> List.member ObjectiveTag b.tags && b.hp <= 0) buildingsAfterHouseSpawn then
                            GameOver
                        else
                            model.gameState

                    -- Generate random destinations for units that need them
                    cmds =
                        List.map
                            (\unit ->
                                case unit.location of
                                    OnMap x y ->
                                        Random.generate
                                            (AssignUnitDestination unit.id)
                                            (randomNearbyCell model.gridConfig x y 10)

                                    Garrisoned _ ->
                                        Cmd.none
                            )
                            unitsNeedingPaths
                in
                ( { model
                    | accumulatedTime = remainingTime
                    , simulationFrameCount = model.simulationFrameCount + 1
                    , lastSimulationDeltas = newSimulationDeltas
                    , units = unitsAfterHouseSpawn
                    , buildings = buildingsAfterHouseSpawn
                    , buildingOccupancy = buildingOccupancyAfterHouses
                    , pathfindingOccupancy = pathfindingOccupancyAfterHouses
                    , tooltipHover = updatedTooltipHover
                    , nextUnitId = nextUnitIdAfterSpawning
                    , nextBuildingId = nextBuildingIdAfterHouses
                    , gameState = newGameState
                  }
                , Cmd.batch cmds
                )

            else
                ( { model | accumulatedTime = newAccumulatedTime, tooltipHover = updatedTooltipHover }, Cmd.none )


constrainCamera : MapConfig -> ( Int, Int ) -> Camera -> Camera
constrainCamera config ( winWidth, winHeight ) camera =
    let
        viewWidth =
            toFloat winWidth

        viewHeight =
            toFloat winHeight

        minX =
            0 - config.boundary

        maxX =
            config.width + config.boundary - viewWidth

        minY =
            0 - config.boundary

        maxY =
            config.height + config.boundary - viewHeight
    in
    { x = clamp minX maxX camera.x
    , y = clamp minY maxY camera.y
    }


type alias MinimapConfig =
    { width : Int
    , height : Int
    , padding : Float
    }


getMinimapScale : MinimapConfig -> MapConfig -> Float
getMinimapScale minimapConfig mapConfig =
    min ((toFloat minimapConfig.width - minimapConfig.padding * 2) / mapConfig.width) ((toFloat minimapConfig.height - minimapConfig.padding * 2) / mapConfig.height)


isClickOnViewbox : Model -> MinimapConfig -> Float -> Float -> Bool
isClickOnViewbox model minimapConfig clickX clickY =
    let
        scale =
            getMinimapScale minimapConfig model.mapConfig

        ( winWidth, winHeight ) =
            model.windowSize

        viewboxLeft =
            minimapConfig.padding + (model.camera.x * scale)

        viewboxTop =
            minimapConfig.padding + (model.camera.y * scale)

        viewboxWidth =
            toFloat winWidth * scale

        viewboxHeight =
            toFloat winHeight * scale
    in
    clickX >= viewboxLeft && clickX <= viewboxLeft + viewboxWidth && clickY >= viewboxTop && clickY <= viewboxTop + viewboxHeight


minimapClickOffset : Model -> MinimapConfig -> Float -> Float -> Position
minimapClickOffset model minimapConfig clickX clickY =
    let
        scale =
            getMinimapScale minimapConfig model.mapConfig

        viewboxLeft =
            minimapConfig.padding + (model.camera.x * scale)

        viewboxTop =
            minimapConfig.padding + (model.camera.y * scale)

        offsetX =
            clickX - viewboxLeft

        offsetY =
            clickY - viewboxTop
    in
    { x = offsetX, y = offsetY }


centerCameraOnMinimapClick : Model -> MinimapConfig -> Float -> Float -> Camera
centerCameraOnMinimapClick model minimapConfig clickX clickY =
    let
        scale =
            getMinimapScale minimapConfig model.mapConfig

        ( winWidth, winHeight ) =
            model.windowSize

        -- Clamp click coordinates to terrain bounds on minimap
        terrainWidth =
            model.mapConfig.width * scale

        terrainHeight =
            model.mapConfig.height * scale

        clampedX =
            clamp minimapConfig.padding (minimapConfig.padding + terrainWidth) clickX

        clampedY =
            clamp minimapConfig.padding (minimapConfig.padding + terrainHeight) clickY

        worldX =
            (clampedX - minimapConfig.padding) / scale - (toFloat winWidth / 2)

        worldY =
            (clampedY - minimapConfig.padding) / scale - (toFloat winHeight / 2)
    in
    { x = worldX, y = worldY }


minimapDragToCamera : Model -> Position -> Float -> Float -> Camera
minimapDragToCamera model offset clickX clickY =
    let
        minimapConfig =
            { width = 200
            , height = 150
            , padding = 10
            }

        scale =
            getMinimapScale minimapConfig model.mapConfig

        worldX =
            (clickX - minimapConfig.padding - offset.x) / scale

        worldY =
            (clickY - minimapConfig.padding - offset.y) / scale
    in
    { x = worldX, y = worldY }



-- RANDOM SHAPE GENERATION


generateShapes : Int -> MapConfig -> Random.Generator (List DecorativeShape)
generateShapes count config =
    Random.list count (generateShape config)


generateShape : MapConfig -> Random.Generator DecorativeShape
generateShape config =
    Random.map5 DecorativeShape
        (Random.float 0 config.width)
        (Random.float 0 config.height)
        (Random.float 20 80)
        generateShapeType
        generateColor


generateShapeType : Random.Generator ShapeType
generateShapeType =
    Random.uniform Circle [ Rectangle ]


generateColor : Random.Generator String
generateColor =
    Random.uniform "#8B4513" [ "#A0522D", "#D2691E", "#CD853F", "#DEB887", "#228B22", "#006400" ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.dragState of
        NotDragging ->
            Sub.batch
                [ E.onResize WindowResize
                , E.onAnimationFrameDelta Frame
                ]

        DraggingViewport _ ->
            Sub.batch
                [ E.onResize WindowResize
                , E.onMouseMove (D.map2 MouseMove (D.field "clientX" D.float) (D.field "clientY" D.float))
                , E.onMouseUp (D.succeed MouseUp)
                , E.onAnimationFrameDelta Frame
                ]

        DraggingMinimap _ ->
            Sub.batch
                [ E.onResize WindowResize
                , E.onMouseMove (D.map2 MinimapMouseMove (D.field "clientX" D.float) (D.field "clientY" D.float))
                , E.onMouseUp (D.succeed MouseUp)
                , E.onAnimationFrameDelta Frame
                ]



-- VIEW


view : Model -> Html Msg
view model =
    let
        ( winWidth, winHeight ) =
            model.windowSize

        aspectRatio =
            4 / 3

        viewportWidth =
            toFloat winWidth

        viewportHeight =
            toFloat winHeight

        cursor =
            case model.dragState of
                DraggingViewport _ ->
                    "grabbing"

                DraggingMinimap _ ->
                    "grabbing"

                NotDragging ->
                    "grab"

        -- Panel sizing calculations
        minimapWidth =
            204

        minimapMargin =
            20

        globalButtonsWidth =
            120

        globalButtonsBorder =
            4

        globalButtonsMargin =
            20

        panelGap =
            10

        selectionPanelBorder =
            4

        selectionPanelMinWidth =
            100

        selectionPanelMaxWidth =
            700

        -- Calculate initial available space for selection panel (without global buttons)
        initialAvailableWidth =
            toFloat winWidth - toFloat (minimapWidth + minimapMargin) - toFloat selectionPanelBorder

        -- Try max width first to determine if panels can stick together
        trialSelectionPanelWidth =
            clamp (toFloat selectionPanelMinWidth) (toFloat selectionPanelMaxWidth) initialAvailableWidth

        -- Check if global buttons should stick to selection panel or be flush left
        -- Account for borders in total width calculation
        totalPanelsWidth =
            globalButtonsWidth + globalButtonsBorder + panelGap + round trialSelectionPanelWidth + selectionPanelBorder

        canStickToPanel =
            totalPanelsWidth <= (winWidth - minimapWidth - minimapMargin - globalButtonsMargin)

        -- Final selection panel width (reduced if global buttons are flush left)
        selectionPanelWidth =
            if canStickToPanel then
                trialSelectionPanelWidth

            else
                -- Global buttons are flush left, reduce available width to avoid overlap
                let
                    reducedAvailableWidth =
                        toFloat winWidth - toFloat (minimapWidth + minimapMargin + selectionPanelBorder + panelGap + globalButtonsWidth + globalButtonsBorder + globalButtonsMargin + panelGap)
                in
                clamp (toFloat selectionPanelMinWidth) (toFloat selectionPanelMaxWidth) reducedAvailableWidth

        globalButtonsLeft =
            if canStickToPanel then
                -- Stick to selection panel, account for borders
                toFloat winWidth - toFloat (minimapWidth + minimapMargin) - selectionPanelWidth - toFloat selectionPanelBorder - toFloat panelGap - toFloat globalButtonsWidth - toFloat globalButtonsBorder

            else
                -- Flush to window left
                toFloat globalButtonsMargin
    in
    div
        [ style "width" "100vw"
        , style "height" "100vh"
        , style "overflow" "hidden"
        , style "position" "relative"
        , style "background-color" "#000"
        , style "user-select" "none"
        , style "-webkit-user-select" "none"
        , style "-moz-user-select" "none"
        ]
        [ Html.node "style" [] [ text "::-webkit-scrollbar { height: 16px; width: 16px; background-color: #222; border-top: 1px solid #444; } ::-webkit-scrollbar-thumb { background-color: #888; border: 2px solid #444; border-radius: 8px; } ::-webkit-scrollbar-thumb:hover { background-color: #aaa; } * { scrollbar-width: auto; scrollbar-color: #888 #222; }" ]
        , viewMainViewport model cursor viewportWidth viewportHeight
        , viewGoldCounter model
        , viewGlobalButtonsPanel model globalButtonsLeft
        , viewSelectionPanel model selectionPanelWidth
        , viewMinimap model
        , viewTooltip model
        , viewPreGameOverlay model
        , viewGameOverOverlay model
        ]


viewMainViewport : Model -> String -> Float -> Float -> Html Msg
viewMainViewport model cursor viewportWidth viewportHeight =
    let
        handleMouseDown =
            case model.buildMode of
                Just _ ->
                    on "mousedown" (D.succeed PlaceBuilding)

                Nothing ->
                    on "mousedown" (D.map2 MouseDown (D.field "clientX" D.float) (D.field "clientY" D.float))

        handleMouseMove =
            case model.buildMode of
                Just _ ->
                    on "mousemove"
                        (D.map2
                            (\clientX clientY ->
                                let
                                    worldX =
                                        model.camera.x + clientX

                                    worldY =
                                        model.camera.y + clientY
                                in
                                WorldMouseMove worldX worldY
                            )
                            (D.field "clientX" D.float)
                            (D.field "clientY" D.float)
                        )

                Nothing ->
                    Html.Attributes.class ""
    in
    div
        [ style "width" "100%"
        , style "height" "100%"
        , style "position" "relative"
        , style "overflow" "hidden"
        , style "cursor" cursor
        , handleMouseDown
        , handleMouseMove
        ]
        [ viewTerrain model viewportWidth viewportHeight
        , viewDecorativeShapes model viewportWidth viewportHeight
        , viewBuildings model
        , viewUnits model
        , viewSelectedUnitPath model
        , viewGrids model viewportWidth viewportHeight
        , viewPathfindingOccupancy model viewportWidth viewportHeight
        , viewBuildingOccupancy model viewportWidth viewportHeight
        , viewCitySearchArea model viewportWidth viewportHeight
        , viewCityActiveArea model viewportWidth viewportHeight
        , viewBuildingPreview model
        , viewUnitRadii model
        ]


viewTerrain : Model -> Float -> Float -> Html Msg
viewTerrain model viewportWidth viewportHeight =
    let
        terrainLeft =
            0 - model.camera.x

        terrainTop =
            0 - model.camera.y

        terrainWidth =
            model.mapConfig.width

        terrainHeight =
            model.mapConfig.height
    in
    div
        [ style "position" "absolute"
        , style "left" (String.fromFloat terrainLeft ++ "px")
        , style "top" (String.fromFloat terrainTop ++ "px")
        , style "width" (String.fromFloat terrainWidth ++ "px")
        , style "height" (String.fromFloat terrainHeight ++ "px")
        , style "background-color" "#1a6b1a"
        ]
        []


viewDecorativeShapes : Model -> Float -> Float -> Html Msg
viewDecorativeShapes model viewportWidth viewportHeight =
    div []
        (List.map (viewShape model) model.decorativeShapes)


viewShape : Model -> DecorativeShape -> Html Msg
viewShape model shape =
    let
        screenX =
            shape.x - model.camera.x

        screenY =
            shape.y - model.camera.y

        ( shapeStyle, shapeRadius ) =
            case shape.shapeType of
                Circle ->
                    ( [ style "border-radius" "50%" ], shape.size / 2 )

                Rectangle ->
                    ( [], 0 )
    in
    div
        ([ style "position" "absolute"
         , style "left" (String.fromFloat (screenX - shapeRadius) ++ "px")
         , style "top" (String.fromFloat (screenY - shapeRadius) ++ "px")
         , style "width" (String.fromFloat shape.size ++ "px")
         , style "height" (String.fromFloat shape.size ++ "px")
         , style "background-color" shape.color
         ]
            ++ shapeStyle
        )
        []


viewBuildings : Model -> Html Msg
viewBuildings model =
    div []
        (List.map (viewBuilding model) model.buildings)


viewBuilding : Model -> Building -> Html Msg
viewBuilding model building =
    let
        worldX =
            toFloat building.gridX * model.gridConfig.buildGridSize

        worldY =
            toFloat building.gridY * model.gridConfig.buildGridSize

        screenX =
            worldX - model.camera.x

        screenY =
            worldY - model.camera.y

        sizeCells =
            buildingSizeToGridCells building.size

        buildingSizePx =
            toFloat sizeCells * model.gridConfig.buildGridSize

        buildingColor =
            case building.buildingType of
                "Test Building" ->
                    "#8B4513"

                _ ->
                    "#666"

        isSelected =
            case model.selected of
                Just (BuildingSelected id) ->
                    id == building.id

                _ ->
                    False

        -- Get entrance tile position
        ( entranceGridX, entranceGridY ) =
            getBuildingEntrance building

        -- Calculate entrance overlay position relative to building
        entranceOffsetX =
            toFloat (entranceGridX - building.gridX) * model.gridConfig.buildGridSize

        entranceOffsetY =
            toFloat (entranceGridY - building.gridY) * model.gridConfig.buildGridSize

        entranceTileSize =
            model.gridConfig.buildGridSize
    in
    div
        [ style "position" "absolute"
        , style "left" (String.fromFloat screenX ++ "px")
        , style "top" (String.fromFloat screenY ++ "px")
        , style "width" (String.fromFloat buildingSizePx ++ "px")
        , style "height" (String.fromFloat buildingSizePx ++ "px")
        , style "background-color" buildingColor
        , style "border" "2px solid #333"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "color" "#fff"
        , style "font-size" "12px"
        , style "font-weight" "bold"
        , style "cursor" "pointer"
        , style "user-select" "none"
        , Html.Events.onClick (SelectThing (BuildingSelected building.id))
        ]
        [ text building.buildingType
        , -- Entrance overlay
          div
            [ style "position" "absolute"
            , style "left" (String.fromFloat entranceOffsetX ++ "px")
            , style "top" (String.fromFloat entranceOffsetY ++ "px")
            , style "width" (String.fromFloat entranceTileSize ++ "px")
            , style "height" (String.fromFloat entranceTileSize ++ "px")
            , style "background-color" "rgba(139, 69, 19, 0.5)"
            , style "border" "1px solid rgba(0, 0, 0, 0.4)"
            , style "pointer-events" "none"
            ]
            []
        , if isSelected then
            div
                [ style "position" "absolute"
                , style "inset" "0"
                , style "border-radius" "4px"
                , style "background-color" "rgba(255, 215, 0, 0.3)"
                , style "pointer-events" "none"
                , style "box-shadow" "inset 0 0 10px rgba(255, 215, 0, 0.6)"
                ]
                []

          else
            text ""
        , -- Health bar
          let
            healthPercent =
                toFloat building.hp / toFloat building.maxHp
          in
          div
            [ style "position" "absolute"
            , style "bottom" "-8px"
            , style "left" "0"
            , style "width" "100%"
            , style "height" "4px"
            , style "background-color" "rgba(0, 0, 0, 0.5)"
            , style "pointer-events" "none"
            ]
            [ div
                [ style "width" (String.fromFloat (healthPercent * 100) ++ "%")
                , style "height" "100%"
                , style "background-color" "#2E4272"
                ]
                []
            ]
        ]


viewUnits : Model -> Html Msg
viewUnits model =
    div []
        (List.filterMap
            (\unit ->
                case unit.location of
                    OnMap x y ->
                        Just (viewUnit model unit x y)

                    Garrisoned _ ->
                        Nothing
            )
            model.units
        )


viewUnit : Model -> Unit -> Float -> Float -> Html Msg
viewUnit model unit worldX worldY =
    let
        screenX =
            worldX - model.camera.x

        screenY =
            worldY - model.camera.y

        -- Unit visual diameter is half of pathfinding grid (16 pixels)
        visualDiameter =
            model.gridConfig.pathfindingGridSize / 2

        visualRadius =
            visualDiameter / 2

        -- Selection area is twice as large (32 pixels diameter)
        selectionDiameter =
            visualDiameter * 2

        selectionRadius =
            selectionDiameter / 2

        isSelected =
            case model.selected of
                Just (UnitSelected id) ->
                    id == unit.id

                _ ->
                    False
    in
    -- Outer clickable area (larger)
    div
        [ style "position" "absolute"
        , style "left" (String.fromFloat (screenX - selectionRadius) ++ "px")
        , style "top" (String.fromFloat (screenY - selectionRadius) ++ "px")
        , style "width" (String.fromFloat selectionDiameter ++ "px")
        , style "height" (String.fromFloat selectionDiameter ++ "px")
        , style "cursor" "pointer"
        , style "user-select" "none"
        , Html.Events.onClick (SelectThing (UnitSelected unit.id))
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        ]
        [ -- Inner visual representation (smaller)
          div
            [ style "width" (String.fromFloat visualDiameter ++ "px")
            , style "height" (String.fromFloat visualDiameter ++ "px")
            , style "background-color" unit.color
            , style "border" "2px solid #333"
            , style "border-radius" "50%"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "color" "#fff"
            , style "font-size" "8px"
            , style "font-weight" "bold"
            , style "pointer-events" "none"
            ]
            [ text "U" ]
        , if isSelected then
            div
                [ style "position" "absolute"
                , style "width" (String.fromFloat visualDiameter ++ "px")
                , style "height" (String.fromFloat visualDiameter ++ "px")
                , style "border-radius" "50%"
                , style "background-color" "rgba(255, 215, 0, 0.3)"
                , style "pointer-events" "none"
                , style "box-shadow" "inset 0 0 10px rgba(255, 215, 0, 0.6)"
                ]
                []

          else
            text ""
        , -- Health bar
          let
            healthPercent =
                toFloat unit.hp / toFloat unit.maxHp
          in
          div
            [ style "position" "absolute"
            , style "bottom" (String.fromFloat (selectionRadius - visualRadius - 6) ++ "px")
            , style "left" "0"
            , style "width" "100%"
            , style "height" "3px"
            , style "background-color" "rgba(0, 0, 0, 0.5)"
            , style "pointer-events" "none"
            ]
            [ div
                [ style "width" (String.fromFloat (healthPercent * 100) ++ "%")
                , style "height" "100%"
                , style "background-color" "#2E4272"
                ]
                []
            ]
        , -- Thinking animation (shrinking circle)
          if unit.behavior == Thinking then
            let
                -- Calculate animation progress (0 = just started, 1 = finished)
                progress =
                    if unit.thinkingDuration > 0 then
                        unit.thinkingTimer / unit.thinkingDuration
                    else
                        1.0

                -- Remaining progress determines size (1 = full size, 0 = shrunk to nothing)
                remainingProgress =
                    1.0 - progress

                -- Start at 2x unit size (32px diameter) and shrink to 0
                maxRadius =
                    visualDiameter

                currentRadius =
                    maxRadius * remainingProgress
            in
            div
                [ style "position" "absolute"
                , style "width" (String.fromFloat (currentRadius * 2) ++ "px")
                , style "height" (String.fromFloat (currentRadius * 2) ++ "px")
                , style "border-radius" "50%"
                , style "background-color" "rgba(255, 255, 255, 0.3)"
                , style "border" "2px solid rgba(255, 255, 255, 0.6)"
                , style "pointer-events" "none"
                , style "top" (String.fromFloat (selectionRadius - currentRadius) ++ "px")
                , style "left" (String.fromFloat (selectionRadius - currentRadius) ++ "px")
                ]
                []

          else
            text ""
        ]


viewSelectedUnitPath : Model -> Html Msg
viewSelectedUnitPath model =
    case model.selected of
        Just (UnitSelected unitId) ->
            let
                maybeUnit =
                    List.filter (\u -> u.id == unitId) model.units
                        |> List.head
            in
            case maybeUnit of
                Just unit ->
                    div []
                        (List.map
                            (\( cellX, cellY ) ->
                                let
                                    -- Center of the pathfinding cell in world coordinates
                                    worldX =
                                        toFloat cellX * model.gridConfig.pathfindingGridSize + model.gridConfig.pathfindingGridSize / 2

                                    worldY =
                                        toFloat cellY * model.gridConfig.pathfindingGridSize + model.gridConfig.pathfindingGridSize / 2

                                    -- Convert to screen coordinates
                                    screenX =
                                        worldX - model.camera.x

                                    screenY =
                                        worldY - model.camera.y

                                    -- Dot size
                                    dotSize =
                                        6
                                in
                                div
                                    [ style "position" "absolute"
                                    , style "left" (String.fromFloat (screenX - dotSize / 2) ++ "px")
                                    , style "top" (String.fromFloat (screenY - dotSize / 2) ++ "px")
                                    , style "width" (String.fromFloat dotSize ++ "px")
                                    , style "height" (String.fromFloat dotSize ++ "px")
                                    , style "background-color" "#FFD700"
                                    , style "border-radius" "50%"
                                    , style "border" "1px solid #FFA500"
                                    , style "pointer-events" "none"
                                    , style "opacity" "0.8"
                                    ]
                                    []
                            )
                            unit.path
                        )

                Nothing ->
                    text ""

        _ ->
            text ""


viewGrids : Model -> Float -> Float -> Html Msg
viewGrids model viewportWidth viewportHeight =
    div []
        ((if model.showBuildGrid then
            viewGrid model model.gridConfig.buildGridSize "rgba(255, 255, 0, 0.3)" viewportWidth viewportHeight

          else
            []
         )
            ++ (if model.showPathfindingGrid then
                    viewGrid model model.gridConfig.pathfindingGridSize "rgba(0, 255, 255, 0.3)" viewportWidth viewportHeight

                else
                    []
               )
        )


viewGrid : Model -> Float -> String -> Float -> Float -> List (Html Msg)
viewGrid model gridSize color viewportWidth viewportHeight =
    let
        terrainLeft =
            0 - model.camera.x

        terrainTop =
            0 - model.camera.y

        -- Calculate visible range
        startX =
            max 0 (floor (model.camera.x / gridSize)) * round gridSize

        startY =
            max 0 (floor (model.camera.y / gridSize)) * round gridSize

        endX =
            min model.mapConfig.width (model.camera.x + viewportWidth)

        endY =
            min model.mapConfig.height (model.camera.y + viewportHeight)

        -- Generate vertical lines
        verticalLines =
            List.map
                (\x ->
                    div
                        [ style "position" "absolute"
                        , style "left" (String.fromFloat (toFloat x - model.camera.x) ++ "px")
                        , style "top" (String.fromFloat terrainTop ++ "px")
                        , style "width" "1px"
                        , style "height" (String.fromFloat model.mapConfig.height ++ "px")
                        , style "background-color" color
                        , style "pointer-events" "none"
                        ]
                        []
                )
                (List.range (startX // round gridSize) (round endX // round gridSize)
                    |> List.map (\i -> i * round gridSize)
                )

        -- Generate horizontal lines
        horizontalLines =
            List.map
                (\y ->
                    div
                        [ style "position" "absolute"
                        , style "left" (String.fromFloat terrainLeft ++ "px")
                        , style "top" (String.fromFloat (toFloat y - model.camera.y) ++ "px")
                        , style "width" (String.fromFloat model.mapConfig.width ++ "px")
                        , style "height" "1px"
                        , style "background-color" color
                        , style "pointer-events" "none"
                        ]
                        []
                )
                (List.range (startY // round gridSize) (round endY // round gridSize)
                    |> List.map (\i -> i * round gridSize)
                )
    in
    verticalLines ++ horizontalLines


viewPathfindingOccupancy : Model -> Float -> Float -> Html Msg
viewPathfindingOccupancy model viewportWidth viewportHeight =
    if not model.showPathfindingOccupancy then
        div [] []

    else
        let
            gridSize =
                model.gridConfig.pathfindingGridSize

            -- Calculate visible range in pathfinding grid coordinates
            startPfX =
                max 0 (floor (model.camera.x / gridSize))

            startPfY =
                max 0 (floor (model.camera.y / gridSize))

            endPfX =
                min (floor (model.mapConfig.width / gridSize)) (ceiling ((model.camera.x + viewportWidth) / gridSize))

            endPfY =
                min (floor (model.mapConfig.height / gridSize)) (ceiling ((model.camera.y + viewportHeight) / gridSize))

            -- Generate all visible cells
            cellsX =
                List.range startPfX endPfX

            cellsY =
                List.range startPfY endPfY

            allCells =
                List.concatMap (\x -> List.map (\y -> ( x, y )) cellsY) cellsX

            -- Filter to only occupied cells
            occupiedCells =
                List.filter (\cell -> isPathfindingCellOccupied cell model.pathfindingOccupancy) allCells

            -- Render occupied cells
            renderCell ( x, y ) =
                let
                    worldX =
                        toFloat x * gridSize

                    worldY =
                        toFloat y * gridSize

                    screenX =
                        worldX - model.camera.x

                    screenY =
                        worldY - model.camera.y
                in
                div
                    [ style "position" "absolute"
                    , style "left" (String.fromFloat screenX ++ "px")
                    , style "top" (String.fromFloat screenY ++ "px")
                    , style "width" (String.fromFloat gridSize ++ "px")
                    , style "height" (String.fromFloat gridSize ++ "px")
                    , style "background-color" "rgba(0, 0, 139, 0.5)"
                    , style "pointer-events" "none"
                    ]
                    []
        in
        div [] (List.map renderCell occupiedCells)


viewBuildingOccupancy : Model -> Float -> Float -> Html Msg
viewBuildingOccupancy model viewportWidth viewportHeight =
    if not model.showBuildingOccupancy then
        div [] []

    else
        let
            gridSize =
                model.gridConfig.buildGridSize

            -- Calculate visible range in building grid coordinates
            startGridX =
                max 0 (floor (model.camera.x / gridSize))

            startGridY =
                max 0 (floor (model.camera.y / gridSize))

            endGridX =
                min (floor (model.mapConfig.width / gridSize)) (ceiling ((model.camera.x + viewportWidth) / gridSize))

            endGridY =
                min (floor (model.mapConfig.height / gridSize)) (ceiling ((model.camera.y + viewportHeight) / gridSize))

            -- Generate all visible cells
            cellsX =
                List.range startGridX endGridX

            cellsY =
                List.range startGridY endGridY

            allCells =
                List.concatMap (\x -> List.map (\y -> ( x, y )) cellsY) cellsX

            -- Filter to only occupied cells
            occupiedCells =
                List.filter (\cell -> Dict.member cell model.buildingOccupancy) allCells

            -- Render occupied cells
            renderCell ( x, y ) =
                let
                    worldX =
                        toFloat x * gridSize

                    worldY =
                        toFloat y * gridSize

                    screenX =
                        worldX - model.camera.x

                    screenY =
                        worldY - model.camera.y
                in
                div
                    [ style "position" "absolute"
                    , style "left" (String.fromFloat screenX ++ "px")
                    , style "top" (String.fromFloat screenY ++ "px")
                    , style "width" (String.fromFloat gridSize ++ "px")
                    , style "height" (String.fromFloat gridSize ++ "px")
                    , style "background-color" "rgba(255, 165, 0, 0.4)"
                    , style "pointer-events" "none"
                    ]
                    []
        in
        div [] (List.map renderCell occupiedCells)


viewCityActiveArea : Model -> Float -> Float -> Html Msg
viewCityActiveArea model viewportWidth viewportHeight =
    if not model.showCityActiveArea then
        div [] []

    else
        let
            gridSize =
                model.gridConfig.buildGridSize

            -- Calculate city active area cells
            cityCells =
                getCityActiveArea model.buildings

            -- Calculate visible range in building grid coordinates
            startGridX =
                max 0 (floor (model.camera.x / gridSize))

            startGridY =
                max 0 (floor (model.camera.y / gridSize))

            endGridX =
                min (floor (model.mapConfig.width / gridSize)) (ceiling ((model.camera.x + viewportWidth) / gridSize))

            endGridY =
                min (floor (model.mapConfig.height / gridSize)) (ceiling ((model.camera.y + viewportHeight) / gridSize))

            -- Convert city cells to dict for fast lookup
            cityDict =
                List.foldl (\cell acc -> Dict.insert cell () acc) Dict.empty cityCells

            -- Generate all visible cells and filter to city cells
            cellsX =
                List.range startGridX endGridX

            cellsY =
                List.range startGridY endGridY

            allVisibleCells =
                List.concatMap (\x -> List.map (\y -> ( x, y )) cellsY) cellsX

            visibleCityCells =
                List.filter (\cell -> Dict.member cell cityDict) allVisibleCells

            -- Render city cells
            renderCell ( x, y ) =
                let
                    worldX =
                        toFloat x * gridSize

                    worldY =
                        toFloat y * gridSize

                    screenX =
                        worldX - model.camera.x

                    screenY =
                        worldY - model.camera.y
                in
                div
                    [ style "position" "absolute"
                    , style "left" (String.fromFloat screenX ++ "px")
                    , style "top" (String.fromFloat screenY ++ "px")
                    , style "width" (String.fromFloat gridSize ++ "px")
                    , style "height" (String.fromFloat gridSize ++ "px")
                    , style "background-color" "rgba(0, 255, 0, 0.2)"
                    , style "pointer-events" "none"
                    ]
                    []
        in
        div [] (List.map renderCell visibleCityCells)


viewCitySearchArea : Model -> Float -> Float -> Html Msg
viewCitySearchArea model viewportWidth viewportHeight =
    if not model.showCitySearchArea then
        div [] []

    else
        let
            gridSize =
                model.gridConfig.buildGridSize

            -- Calculate city search area cells
            cityCells =
                getCitySearchArea model.buildings

            -- Calculate visible range in building grid coordinates
            startGridX =
                max 0 (floor (model.camera.x / gridSize))

            startGridY =
                max 0 (floor (model.camera.y / gridSize))

            endGridX =
                min (floor (model.mapConfig.width / gridSize)) (ceiling ((model.camera.x + viewportWidth) / gridSize))

            endGridY =
                min (floor (model.mapConfig.height / gridSize)) (ceiling ((model.camera.y + viewportHeight) / gridSize))

            -- Convert city cells to dict for fast lookup
            cityDict =
                List.foldl (\cell acc -> Dict.insert cell () acc) Dict.empty cityCells

            -- Generate all visible cells and filter to city cells
            cellsX =
                List.range startGridX endGridX

            cellsY =
                List.range startGridY endGridY

            allVisibleCells =
                List.concatMap (\x -> List.map (\y -> ( x, y )) cellsY) cellsX

            visibleCityCells =
                List.filter (\cell -> Dict.member cell cityDict) allVisibleCells

            -- Render city cells
            renderCell ( x, y ) =
                let
                    worldX =
                        toFloat x * gridSize

                    worldY =
                        toFloat y * gridSize

                    screenX =
                        worldX - model.camera.x

                    screenY =
                        worldY - model.camera.y
                in
                div
                    [ style "position" "absolute"
                    , style "left" (String.fromFloat screenX ++ "px")
                    , style "top" (String.fromFloat screenY ++ "px")
                    , style "width" (String.fromFloat gridSize ++ "px")
                    , style "height" (String.fromFloat gridSize ++ "px")
                    , style "background-color" "rgba(0, 255, 0, 0.1)"
                    , style "pointer-events" "none"
                    ]
                    []
        in
        div [] (List.map renderCell visibleCityCells)


viewUnitRadii : Model -> Html Msg
viewUnitRadii model =
    case model.selected of
        Just (UnitSelected unitId) ->
            let
                maybeUnit =
                    List.filter (\u -> u.id == unitId) model.units
                        |> List.head
            in
            case maybeUnit of
                Just unit ->
                    case unit.location of
                        OnMap x y ->
                            let
                                screenX =
                                    x - model.camera.x

                                screenY =
                                    y - model.camera.y

                                -- Active radius circle
                                activeCircle =
                                    div
                                        [ style "position" "absolute"
                                        , style "left" (String.fromFloat (screenX - unit.activeRadius) ++ "px")
                                        , style "top" (String.fromFloat (screenY - unit.activeRadius) ++ "px")
                                        , style "width" (String.fromFloat (unit.activeRadius * 2) ++ "px")
                                        , style "height" (String.fromFloat (unit.activeRadius * 2) ++ "px")
                                        , style "border" "2px solid rgba(255, 255, 0, 0.6)"
                                        , style "border-radius" "50%"
                                        , style "pointer-events" "none"
                                        ]
                                        []

                                -- Search radius circle
                                searchCircle =
                                    div
                                        [ style "position" "absolute"
                                        , style "left" (String.fromFloat (screenX - unit.searchRadius) ++ "px")
                                        , style "top" (String.fromFloat (screenY - unit.searchRadius) ++ "px")
                                        , style "width" (String.fromFloat (unit.searchRadius * 2) ++ "px")
                                        , style "height" (String.fromFloat (unit.searchRadius * 2) ++ "px")
                                        , style "border" "2px solid rgba(255, 255, 0, 0.3)"
                                        , style "border-radius" "50%"
                                        , style "pointer-events" "none"
                                        ]
                                        []
                            in
                            div [] [ searchCircle, activeCircle ]

                        Garrisoned _ ->
                            div [] []

                Nothing ->
                    div [] []

        _ ->
            div [] []


viewBuildingPreview : Model -> Html Msg
viewBuildingPreview model =
    case ( model.buildMode, model.mouseWorldPos ) of
        ( Just template, Just ( worldX, worldY ) ) ->
            let
                -- Convert world coordinates to build grid coordinates
                gridX =
                    floor (worldX / model.gridConfig.buildGridSize)

                gridY =
                    floor (worldY / model.gridConfig.buildGridSize)

                -- Center the building on the grid cell
                sizeCells =
                    buildingSizeToGridCells template.size

                centeredGridX =
                    gridX - (sizeCells // 2)

                centeredGridY =
                    gridY - (sizeCells // 2)

                -- Check if placement is valid
                isValid =
                    isValidBuildingPlacement centeredGridX centeredGridY template.size model.mapConfig model.gridConfig model.buildingOccupancy model.buildings
                        && model.gold >= template.cost

                -- Calculate screen position
                worldPosX =
                    toFloat centeredGridX * model.gridConfig.buildGridSize

                worldPosY =
                    toFloat centeredGridY * model.gridConfig.buildGridSize

                screenX =
                    worldPosX - model.camera.x

                screenY =
                    worldPosY - model.camera.y

                buildingSizePx =
                    toFloat sizeCells * model.gridConfig.buildGridSize

                previewColor =
                    if isValid then
                        "rgba(0, 255, 0, 0.5)"

                    else
                        "rgba(255, 0, 0, 0.5)"
            in
            div
                [ style "position" "absolute"
                , style "left" (String.fromFloat screenX ++ "px")
                , style "top" (String.fromFloat screenY ++ "px")
                , style "width" (String.fromFloat buildingSizePx ++ "px")
                , style "height" (String.fromFloat buildingSizePx ++ "px")
                , style "background-color" previewColor
                , style "border" "2px solid rgba(255, 255, 255, 0.8)"
                , style "pointer-events" "none"
                , style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "color" "#fff"
                , style "font-size" "14px"
                , style "font-weight" "bold"
                ]
                [ text template.name ]

        _ ->
            div [] []


viewGlobalButtonsPanel : Model -> Float -> Html Msg
viewGlobalButtonsPanel model leftPosition =
    let
        panelSize =
            120

        button label selectable isSelected =
            div
                [ style "width" "100%"
                , style "height" "36px"
                , style "background-color"
                    (if isSelected then
                        "#555"

                     else
                        "#333"
                    )
                , style "color" "#fff"
                , style "border" "2px solid #666"
                , style "border-radius" "4px"
                , style "cursor" "pointer"
                , style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "font-size" "12px"
                , style "font-weight" "bold"
                , style "position" "relative"
                , Html.Events.onClick (SelectThing selectable)
                ]
                [ text label
                , if isSelected then
                    div
                        [ style "position" "absolute"
                        , style "inset" "0"
                        , style "border-radius" "4px"
                        , style "background-color" "rgba(255, 215, 0, 0.3)"
                        , style "pointer-events" "none"
                        , style "box-shadow" "inset 0 0 10px rgba(255, 215, 0, 0.6)"
                        ]
                        []

                  else
                    text ""
                ]
    in
    div
        [ style "position" "absolute"
        , style "bottom" "20px"
        , style "left" (String.fromFloat leftPosition ++ "px")
        , style "width" (String.fromInt panelSize ++ "px")
        , style "height" (String.fromInt panelSize ++ "px")
        , style "background-color" "rgba(0, 0, 0, 0.8)"
        , style "border" "2px solid #666"
        , style "border-radius" "4px"
        , style "padding" "8px"
        , style "display" "flex"
        , style "flex-direction" "column"
        , style "gap" "6px"
        ]
        [ button "Debug" GlobalButtonDebug (model.selected == Just GlobalButtonDebug)
        , button "Build" GlobalButtonBuild (model.selected == Just GlobalButtonBuild)
        ]


viewSelectionPanel : Model -> Float -> Html Msg
viewSelectionPanel model panelWidth =
    let
        panelHeight =
            120

        debugTabbedContent : Model -> Html Msg
        debugTabbedContent m =
            let
                tabButton tab label =
                    let
                        isActive =
                            m.debugTab == tab
                    in
                    div
                        [ style "padding" "6px 12px"
                        , style "background-color"
                            (if isActive then
                                "#0f0"

                             else
                                "#222"
                            )
                        , style "color"
                            (if isActive then
                                "#000"

                             else
                                "#0f0"
                            )
                        , style "cursor" "pointer"
                        , style "border-radius" "3px"
                        , style "font-family" "monospace"
                        , style "font-size" "10px"
                        , style "font-weight" "bold"
                        , style "user-select" "none"
                        , Html.Events.onClick (SetDebugTab tab)
                        ]
                        [ text label ]

                tabsColumn =
                    div
                        [ style "display" "flex"
                        , style "flex-direction" "column"
                        , style "gap" "4px"
                        , style "padding" "8px"
                        , style "border-right" "1px solid #0f0"
                        , style "flex-shrink" "0"
                        ]
                        [ tabButton StatsTab "STATS"
                        , tabButton VisualizationTab "VISUAL"
                        , tabButton ControlsTab "CONTROLS"
                        ]

                tabContent =
                    case m.debugTab of
                        StatsTab ->
                            debugStatsContent m

                        VisualizationTab ->
                            debugVisualizationContent

                        ControlsTab ->
                            debugControlsContent
            in
            div
                [ style "display" "flex"
                , style "flex-direction" "row"
                ]
                [ tabsColumn, tabContent ]

        debugStatsContent m =
            let
                avgDelta =
                    if List.isEmpty m.lastSimulationDeltas then
                        0

                    else
                        (List.sum m.lastSimulationDeltas) / toFloat (List.length m.lastSimulationDeltas)
            in
            div
                [ style "padding" "12px"
                , style "color" "#0f0"
                , style "font-family" "monospace"
                , style "font-size" "11px"
                , style "display" "flex"
                , style "flex-direction" "row"
                , style "gap" "16px"
                ]
                [ div
                    [ style "display" "flex"
                    , style "flex-direction" "column"
                    , style "gap" "6px"
                    ]
                    [ div []
                        [ text "Camera: ("
                        , text (String.fromFloat m.camera.x)
                        , text ", "
                        , text (String.fromFloat m.camera.y)
                        , text ")"
                        ]
                    , div []
                        [ text "Sim Frame: "
                        , text (String.fromInt m.simulationFrameCount)
                        ]
                    , div []
                        [ text "Avg Delta: "
                        , text (String.fromFloat (round (avgDelta * 10) |> toFloat |> (\x -> x / 10)))
                        , text "ms"
                        ]
                    ]
                ]

        debugVisualizationContent =
            let
                checkbox isChecked label onClick =
                    div
                        [ style "display" "flex"
                        , style "gap" "8px"
                        , style "align-items" "center"
                        , style "cursor" "pointer"
                        , Html.Events.onClick onClick
                        ]
                        [ div
                            [ style "width" "14px"
                            , style "height" "14px"
                            , style "border" "2px solid #0f0"
                            , style "border-radius" "2px"
                            , style "background-color"
                                (if isChecked then
                                    "#0f0"

                                 else
                                    "transparent"
                                )
                            ]
                            []
                        , text label
                        ]
            in
            div
                [ style "padding" "12px"
                , style "color" "#0f0"
                , style "font-family" "monospace"
                , style "font-size" "11px"
                , style "display" "flex"
                , style "flex-direction" "row"
                , style "gap" "16px"
                ]
                [ div
                    [ style "display" "flex"
                    , style "flex-direction" "column"
                    , style "gap" "6px"
                    ]
                    [ checkbox model.showBuildGrid "Build Grid" ToggleBuildGrid
                    , checkbox model.showPathfindingGrid "Pathfinding Grid" TogglePathfindingGrid
                    ]
                , div
                    [ style "display" "flex"
                    , style "flex-direction" "column"
                    , style "gap" "6px"
                    ]
                    [ checkbox model.showPathfindingOccupancy "PF Occupancy" TogglePathfindingOccupancy
                    , checkbox model.showBuildingOccupancy "Build Occupancy" ToggleBuildingOccupancy
                    ]
                , div
                    [ style "display" "flex"
                    , style "flex-direction" "column"
                    , style "gap" "6px"
                    ]
                    [ checkbox model.showCityActiveArea "City Active" ToggleCityActiveArea
                    , checkbox model.showCitySearchArea "City Search" ToggleCitySearchArea
                    ]
                ]

        debugControlsContent =
            let
                speedRadio speed label =
                    let
                        isSelected =
                            model.simulationSpeed == speed
                    in
                    div
                        [ style "display" "flex"
                        , style "gap" "6px"
                        , style "align-items" "center"
                        , style "cursor" "pointer"
                        , Html.Events.onClick (SetSimulationSpeed speed)
                        ]
                        [ div
                            [ style "width" "12px"
                            , style "height" "12px"
                            , style "border" "2px solid #0f0"
                            , style "border-radius" "50%"
                            , style "display" "flex"
                            , style "align-items" "center"
                            , style "justify-content" "center"
                            ]
                            [ if isSelected then
                                div
                                    [ style "width" "6px"
                                    , style "height" "6px"
                                    , style "background-color" "#0f0"
                                    , style "border-radius" "50%"
                                    ]
                                    []

                              else
                                text ""
                            ]
                        , text label
                        ]
            in
            div
                [ style "padding" "12px"
                , style "color" "#0f0"
                , style "font-family" "monospace"
                , style "font-size" "11px"
                , style "display" "flex"
                , style "flex-direction" "row"
                , style "gap" "16px"
                ]
                [ div
                    [ style "display" "flex"
                    , style "flex-direction" "column"
                    , style "gap" "6px"
                    ]
                    [ div [] [ text "Speed:" ]
                    , speedRadio Pause "0x"
                    , speedRadio Speed1x "1x"
                    , speedRadio Speed2x "2x"
                    , speedRadio Speed10x "10x"
                    , speedRadio Speed100x "100x"
                    ]
                , div
                    [ style "display" "flex"
                    , style "flex-direction" "column"
                    , style "gap" "10px"
                    ]
                    [ div
                        [ style "display" "flex"
                        , style "flex-direction" "column"
                        , style "gap" "6px"
                        ]
                        [ div [] [ text "Gold:" ]
                        , div
                            [ style "display" "flex"
                            , style "gap" "4px"
                            ]
                            [ Html.input
                                [ Html.Attributes.type_ "text"
                                , Html.Attributes.value model.goldInputValue
                                , Html.Attributes.placeholder "Amount"
                                , Html.Events.onInput GoldInputChanged
                                , style "width" "80px"
                                , style "padding" "4px"
                                , style "background-color" "#222"
                                , style "color" "#0f0"
                                , style "border" "1px solid #0f0"
                                , style "border-radius" "2px"
                                , style "font-family" "monospace"
                                , style "font-size" "11px"
                                ]
                                []
                            , div
                                [ style "padding" "4px 8px"
                                , style "background-color" "#0f0"
                                , style "color" "#000"
                                , style "border-radius" "2px"
                                , style "cursor" "pointer"
                                , style "font-weight" "bold"
                                , style "font-size" "10px"
                                , Html.Events.onClick SetGoldFromInput
                                ]
                                [ text "SET" ]
                            ]
                        ]
                    , div
                        [ style "display" "flex"
                        , style "gap" "4px"
                        ]
                        [ div
                            [ style "padding" "6px 10px"
                            , style "background-color" "#0f0"
                            , style "color" "#000"
                            , style "border-radius" "2px"
                            , style "cursor" "pointer"
                            , style "font-weight" "bold"
                            , style "font-size" "10px"
                            , style "text-align" "center"
                            , Html.Events.onClick SpawnTestUnit
                            ]
                            [ text "SPAWN TEST UNIT" ]
                        , div
                            [ style "padding" "6px 10px"
                            , style "background-color" "#0f0"
                            , style "color" "#000"
                            , style "border-radius" "2px"
                            , style "cursor" "pointer"
                            , style "font-weight" "bold"
                            , style "font-size" "10px"
                            , style "text-align" "center"
                            , Html.Events.onClick PlaceTestBuilding
                            ]
                            [ text "PLACE TEST BUILDING" ]
                        ]
                    ]
                ]

        debugInfoSection =
            let
                -- Calculate running average of last 3 simulation deltas
                avgDelta =
                    if List.isEmpty model.lastSimulationDeltas then
                        0

                    else
                        (List.sum model.lastSimulationDeltas) / toFloat (List.length model.lastSimulationDeltas)
            in
            div
                [ style "padding" "12px"
                , style "color" "#0f0"
                , style "font-family" "monospace"
                , style "font-size" "11px"
                , style "display" "flex"
                , style "flex-direction" "column"
                , style "gap" "6px"
                , style "flex-shrink" "0"
                ]
                [ div []
                    [ text "Camera: ("
                    , text (String.fromFloat model.camera.x)
                    , text ", "
                    , text (String.fromFloat model.camera.y)
                    , text ")"
                    ]
                , div []
                    [ text "Gold: "
                    , text (String.fromInt model.gold)
                    ]
                , div []
                    [ text "Sim Frame: "
                    , text (String.fromInt model.simulationFrameCount)
                    ]
                , div []
                    [ text "Avg Delta: "
                    , text (String.fromFloat (round (avgDelta * 10) |> toFloat |> (\x -> x / 10)))
                    , text "ms"
                    ]
                ]

        debugGridSection =
            div
                [ style "padding" "12px"
                , style "color" "#0f0"
                , style "font-family" "monospace"
                , style "font-size" "11px"
                , style "display" "flex"
                , style "flex-direction" "column"
                , style "gap" "6px"
                , style "flex-shrink" "0"
                , style "border-left" "1px solid #0f0"
                ]
                [ div
                    [ style "display" "flex"
                    , style "gap" "8px"
                    , style "align-items" "center"
                    , style "cursor" "pointer"
                    , Html.Events.onClick ToggleBuildGrid
                    ]
                    [ div
                        [ style "width" "14px"
                        , style "height" "14px"
                        , style "border" "2px solid #0f0"
                        , style "border-radius" "2px"
                        , style "background-color"
                            (if model.showBuildGrid then
                                "#0f0"

                             else
                                "transparent"
                            )
                        ]
                        []
                    , text "Build Grid"
                    ]
                , div
                    [ style "display" "flex"
                    , style "gap" "8px"
                    , style "align-items" "center"
                    , style "cursor" "pointer"
                    , Html.Events.onClick TogglePathfindingGrid
                    ]
                    [ div
                        [ style "width" "14px"
                        , style "height" "14px"
                        , style "border" "2px solid #0f0"
                        , style "border-radius" "2px"
                        , style "background-color"
                            (if model.showPathfindingGrid then
                                "#0f0"

                             else
                                "transparent"
                            )
                        ]
                        []
                    , text "Pathfinding Grid"
                    ]
                , div
                    [ style "display" "flex"
                    , style "gap" "8px"
                    , style "align-items" "center"
                    , style "cursor" "pointer"
                    , Html.Events.onClick TogglePathfindingOccupancy
                    ]
                    [ div
                        [ style "width" "14px"
                        , style "height" "14px"
                        , style "border" "2px solid #0f0"
                        , style "border-radius" "2px"
                        , style "background-color"
                            (if model.showPathfindingOccupancy then
                                "#0f0"

                             else
                                "transparent"
                            )
                        ]
                        []
                    , text "PF Occupancy"
                    ]
                , div
                    [ style "display" "flex"
                    , style "gap" "8px"
                    , style "align-items" "center"
                    , style "cursor" "pointer"
                    , Html.Events.onClick ToggleBuildingOccupancy
                    ]
                    [ div
                        [ style "width" "14px"
                        , style "height" "14px"
                        , style "border" "2px solid #0f0"
                        , style "border-radius" "2px"
                        , style "background-color"
                            (if model.showBuildingOccupancy then
                                "#0f0"

                             else
                                "transparent"
                            )
                        ]
                        []
                    , text "Build Occupancy"
                    ]
                ]

        buildingOption : BuildingTemplate -> Html Msg
        buildingOption template =
            let
                canAfford =
                    model.gold >= template.cost

                isActive =
                    case model.buildMode of
                        Just activeTemplate ->
                            activeTemplate.name == template.name

                        Nothing ->
                            False

                sizeLabel =
                    case template.size of
                        Small ->
                            "1×1"

                        Medium ->
                            "2×2"

                        Large ->
                            "3×3"

                        Huge ->
                            "4×4"

                clickHandler =
                    if canAfford then
                        if isActive then
                            Html.Events.onClick ExitBuildMode

                        else
                            Html.Events.onClick (EnterBuildMode template)

                    else
                        Html.Attributes.class ""
            in
            div
                [ style "display" "flex"
                , style "flex-direction" "column"
                , style "align-items" "center"
                , style "gap" "4px"
                , style "padding" "8px"
                , style "background-color"
                    (if canAfford then
                        "#333"

                     else
                        "#222"
                    )
                , style "border"
                    (if canAfford then
                        "2px solid #666"

                     else
                        "2px solid #444"
                    )
                , style "border-radius" "4px"
                , style "cursor"
                    (if canAfford then
                        "pointer"

                     else
                        "not-allowed"
                    )
                , style "flex-shrink" "0"
                , style "opacity"
                    (if canAfford then
                        "1"

                     else
                        "0.5"
                    )
                , style "position" "relative"
                , clickHandler
                , on "mouseenter"
                    (D.map2 (\x y -> TooltipEnter ("building-" ++ template.name) x y)
                        (D.field "clientX" D.float)
                        (D.field "clientY" D.float)
                    )
                , Html.Events.onMouseLeave TooltipLeave
                ]
                [ div
                    [ style "font-size" "12px"
                    , style "color" "#fff"
                    , style "font-weight" "bold"
                    ]
                    [ text template.name ]
                , div
                    [ style "font-size" "10px"
                    , style "color" "#aaa"
                    ]
                    [ text sizeLabel ]
                , div
                    [ style "color" "#FFD700"
                    , style "font-size" "12px"
                    , style "font-weight" "bold"
                    ]
                    [ text (String.fromInt template.cost ++ "g") ]
                , if isActive then
                    div
                        [ style "position" "absolute"
                        , style "inset" "0"
                        , style "border-radius" "4px"
                        , style "background-color" "rgba(255, 255, 255, 0.3)"
                        , style "pointer-events" "none"
                        , style "box-shadow" "inset 0 0 10px rgba(255, 255, 255, 0.6)"
                        ]
                        []

                  else
                    text ""
                ]

        buildContent =
            case model.gameState of
                PreGame ->
                    -- Only show Castle during pre-game
                    div
                        [ style "display" "flex"
                        , style "gap" "8px"
                        , style "padding" "8px"
                        ]
                        [ buildingOption castleTemplate ]

                Playing ->
                    -- Show all buildings except Castle
                    div
                        [ style "display" "flex"
                        , style "gap" "8px"
                        , style "padding" "8px"
                        ]
                        [ buildingOption testBuildingTemplate
                        , buildingOption warriorsGuildTemplate
                        ]

                GameOver ->
                    -- Show nothing during game over
                    div
                        [ style "padding" "12px"
                        , style "color" "#f00"
                        , style "font-family" "monospace"
                        , style "font-size" "14px"
                        , style "font-weight" "bold"
                        ]
                        [ text "GAME OVER" ]

        noSelectionContent =
            div
                [ style "padding" "12px"
                , style "color" "#888"
                , style "font-size" "14px"
                , style "font-style" "italic"
                , style "display" "flex"
                , style "align-items" "center"
                , style "height" "100%"
                ]
                [ text "No selection" ]

        buildingSelectedContent buildingId =
            let
                maybeBuilding =
                    List.filter (\b -> b.id == buildingId) model.buildings
                        |> List.head
            in
            case maybeBuilding of
                Just building ->
                    let
                        tagToString tag =
                            case tag of
                                BuildingTag ->
                                    "Building"

                                HeroTag ->
                                    "Hero"

                                HenchmanTag ->
                                    "Henchman"

                                GuildTag ->
                                    "Guild"

                                ObjectiveTag ->
                                    "Objective"

                                CofferTag ->
                                    "Coffer"

                        -- Tab buttons
                        tabButton label tab =
                            div
                                [ style "padding" "6px 12px"
                                , style "background-color" (if model.buildingTab == tab then "#555" else "#333")
                                , style "cursor" "pointer"
                                , style "border-radius" "4px 4px 0 0"
                                , style "font-size" "10px"
                                , style "font-weight" "bold"
                                , style "user-select" "none"
                                , Html.Events.onClick (SetBuildingTab tab)
                                ]
                                [ text label ]

                        tabContent =
                            case model.buildingTab of
                                MainTab ->
                                    div
                                        [ style "display" "flex"
                                        , style "flex-direction" "row"
                                        , style "gap" "16px"
                                        , style "align-items" "flex-start"
                                        ]
                                        [ -- Column 1: Name, HP, Owner
                                          div
                                            [ style "display" "flex"
                                            , style "flex-direction" "column"
                                            , style "gap" "4px"
                                            ]
                                            [ div
                                                [ style "font-weight" "bold"
                                                , style "font-size" "12px"
                                                ]
                                                [ text building.buildingType ]
                                            , div
                                                [ style "font-size" "9px"
                                                , style "color" "#aaa"
                                                , style "display" "flex"
                                                , style "gap" "4px"
                                                ]
                                                ([ text "[" ]
                                                    ++ (building.tags
                                                            |> List.map
                                                                (\tag ->
                                                                    div
                                                                        [ style "cursor" "help"
                                                                        , on "mouseenter"
                                                                            (D.map2 (\x y -> TooltipEnter ("tag-" ++ tagToString tag) x y)
                                                                                (D.field "clientX" D.float)
                                                                                (D.field "clientY" D.float)
                                                                            )
                                                                        , Html.Events.onMouseLeave TooltipLeave
                                                                        ]
                                                                        [ text (tagToString tag) ]
                                                                )
                                                            |> List.intersperse (text ", ")
                                                       )
                                                    ++ [ text "]" ]
                                                )
                                            , div []
                                                [ text ("HP: " ++ String.fromInt building.hp ++ "/" ++ String.fromInt building.maxHp) ]
                                            , div []
                                                [ text ("Owner: " ++ (case building.owner of
                                                    Player -> "Player"
                                                    Enemy -> "Enemy"
                                                    ))
                                                ]
                                            ]
                                        , -- Column 2: Garrison
                                          div
                                            [ style "display" "flex"
                                            , style "flex-direction" "column"
                                            , style "gap" "4px"
                                            ]
                                            (if List.isEmpty building.garrisonConfig then
                                                [ div
                                                    [ style "cursor" "help"
                                                    , on "mouseenter"
                                                        (D.map2 (\x y -> TooltipEnter ("garrison-" ++ String.fromInt building.id) x y)
                                                            (D.field "clientX" D.float)
                                                            (D.field "clientY" D.float)
                                                        )
                                                    , Html.Events.onMouseLeave TooltipLeave
                                                    ]
                                                    [ text ("Garrison: " ++ String.fromInt building.garrisonOccupied ++ "/" ++ String.fromInt building.garrisonSlots) ]
                                                ]
                                            else
                                                [ div []
                                                    [ text "Garrison:" ]
                                                ]
                                                ++ List.map
                                                    (\slot ->
                                                        div
                                                            [ style "font-size" "10px"
                                                            , style "color" "#aaa"
                                                            , style "padding-left" "8px"
                                                            ]
                                                            [ text ("  " ++ slot.unitType ++ ": " ++ String.fromInt slot.currentCount ++ "/" ++ String.fromInt slot.maxCount) ]
                                                    )
                                                    building.garrisonConfig
                                            )
                                        ]

                                InfoTab ->
                                    div
                                        [ style "display" "flex"
                                        , style "flex-direction" "row"
                                        , style "gap" "16px"
                                        , style "align-items" "flex-start"
                                        ]
                                        [ -- Column 1: Behavior, Timer, Coffer
                                          div
                                            [ style "display" "flex"
                                            , style "flex-direction" "column"
                                            , style "gap" "8px"
                                            ]
                                            ([ div
                                                [ style "cursor" "help"
                                                , on "mouseenter"
                                                    (D.map2 (\x y -> TooltipEnter ("behavior-" ++ (case building.behavior of
                                                        Idle -> "Idle"
                                                        UnderConstruction -> "Under Construction"
                                                        SpawnHouse -> "Spawn House"
                                                        GenerateGold -> "Generate Gold"
                                                        BuildingDead -> "Dead"
                                                        BuildingDebugError msg -> "Error: " ++ msg
                                                        )) x y)
                                                        (D.field "clientX" D.float)
                                                        (D.field "clientY" D.float)
                                                    )
                                                , Html.Events.onMouseLeave TooltipLeave
                                                ]
                                                [ text ("Behavior: " ++ (case building.behavior of
                                                    Idle -> "Idle"
                                                    UnderConstruction -> "Under Construction"
                                                    SpawnHouse -> "Spawn House"
                                                    GenerateGold -> "Generate Gold"
                                                    BuildingDead -> "Dead"
                                                    BuildingDebugError msg -> "Error: " ++ msg
                                                    ))
                                                ]
                                            , div
                                                [ style "font-size" "10px"
                                                , style "color" "#aaa"
                                                ]
                                                [ text ("Timer: " ++ String.fromFloat (round (building.behaviorTimer * 10) |> toFloat |> (\x -> x / 10)) ++ "s / " ++ String.fromFloat (round (building.behaviorDuration * 10) |> toFloat |> (\x -> x / 10)) ++ "s") ]
                                            ]
                                            ++ (if List.member CofferTag building.tags then
                                                [ div []
                                                    [ text ("Coffer: " ++ String.fromInt building.coffer ++ " gold") ]
                                                ]
                                            else
                                                []
                                            )
                                            )
                                        , -- Column 2: Garrison Cooldowns
                                          div
                                            [ style "display" "flex"
                                            , style "flex-direction" "column"
                                            , style "gap" "4px"
                                            ]
                                            (if not (List.isEmpty building.garrisonConfig) then
                                                [ div []
                                                    [ text "Garrison Cooldowns:" ]
                                                ]
                                                ++ List.map
                                                    (\slot ->
                                                        div
                                                            [ style "font-size" "10px"
                                                            , style "color" "#aaa"
                                                            , style "padding-left" "8px"
                                                            ]
                                                            [ text ("  " ++ slot.unitType ++ ": " ++
                                                                (if slot.currentCount < slot.maxCount then
                                                                    String.fromFloat (round (slot.spawnTimer * 10) |> toFloat |> (\x -> x / 10)) ++ "s / 30.0s"
                                                                else
                                                                    "Full"
                                                                ))
                                                            ]
                                                    )
                                                    building.garrisonConfig
                                            else
                                                []
                                            )
                                        ]
                    in
                    div
                        [ style "display" "flex"
                        , style "flex-direction" "column"
                        ]
                        [ -- Tab buttons
                          div
                            [ style "display" "flex"
                            , style "gap" "4px"
                            , style "padding" "8px 8px 0 8px"
                            ]
                            [ tabButton "Main" MainTab
                            , tabButton "Info" InfoTab
                            ]
                        , -- Tab content
                          div
                            [ style "padding" "12px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            ]
                            [ tabContent ]
                        ]

                Nothing ->
                    div
                        [ style "padding" "12px"
                        , style "color" "#f00"
                        , style "font-size" "12px"
                        ]
                        [ text "Building not found" ]

        unitSelectedContent unitId =
            let
                maybeUnit =
                    List.filter (\u -> u.id == unitId) model.units
                        |> List.head
            in
            case maybeUnit of
                Just unit ->
                    let
                        tagToString tag =
                            case tag of
                                BuildingTag ->
                                    "Building"

                                HeroTag ->
                                    "Hero"

                                HenchmanTag ->
                                    "Henchman"

                                GuildTag ->
                                    "Guild"

                                ObjectiveTag ->
                                    "Objective"

                                CofferTag ->
                                    "Coffer"
                    in
                    div
                        [ style "padding" "12px"
                        , style "color" "#fff"
                        , style "font-family" "monospace"
                        , style "font-size" "11px"
                        , style "display" "flex"
                        , style "flex-direction" "row"
                        , style "gap" "16px"
                        ]
                        [ -- Column 1: Name and HP
                          div
                            [ style "display" "flex"
                            , style "flex-direction" "column"
                            , style "gap" "4px"
                            ]
                            [ div
                                [ style "font-weight" "bold"
                                , style "font-size" "12px"
                                ]
                                [ text unit.unitType ]
                            , div
                                [ style "font-size" "9px"
                                , style "color" "#aaa"
                                , style "display" "flex"
                                , style "gap" "4px"
                                ]
                                ([ text "[" ]
                                    ++ (unit.tags
                                            |> List.map
                                                (\tag ->
                                                    div
                                                        [ style "cursor" "help"
                                                        , on "mouseenter"
                                                            (D.map2 (\x y -> TooltipEnter ("tag-" ++ tagToString tag) x y)
                                                                (D.field "clientX" D.float)
                                                                (D.field "clientY" D.float)
                                                            )
                                                        , Html.Events.onMouseLeave TooltipLeave
                                                        ]
                                                        [ text (tagToString tag) ]
                                                )
                                            |> List.intersperse (text ", ")
                                       )
                                    ++ [ text "]" ]
                                )
                            , div []
                                [ text ("HP: " ++ String.fromInt unit.hp ++ "/" ++ String.fromInt unit.maxHp) ]
                            ]
                        , -- Column 2: Everything else
                          div
                            [ style "display" "flex"
                            , style "flex-direction" "column"
                            , style "gap" "4px"
                            ]
                            [ div []
                                [ text ("Speed: " ++ String.fromFloat unit.movementSpeed ++ " cells/s") ]
                            , div []
                                [ text ("Owner: " ++ (case unit.owner of
                                    Player -> "Player"
                                    Enemy -> "Enemy"
                                    ))
                                ]
                            , div []
                                [ text ("Location: " ++ (case unit.location of
                                    OnMap x y -> "(" ++ String.fromInt (round x) ++ ", " ++ String.fromInt (round y) ++ ")"
                                    Garrisoned buildingId -> "Garrisoned in #" ++ String.fromInt buildingId
                                    ))
                                ]
                            , div
                                [ style "cursor" "help"
                                , on "mouseenter"
                                    (D.map2 (\x y -> TooltipEnter ("behavior-" ++ (case unit.behavior of
                                        Thinking -> "Thinking"
                                        FindingRandomTarget -> "Finding Target"
                                        MovingTowardTarget -> "Moving"
                                        Dead -> "Dead"
                                        DebugError msg -> "Error: " ++ msg
                                        WithoutHome -> "Without Home"
                                        LookingForTask -> "Looking for Task"
                                        GoingToSleep -> "Going to Sleep"
                                        Sleeping -> "Sleeping"
                                        LookForBuildRepairTarget -> "Looking for Build/Repair"
                                        BuildingConstruction -> "Building"
                                        Repairing -> "Repairing"
                                        LookForTaxTarget -> "Looking for Tax Target"
                                        CollectingTaxes -> "Collecting Taxes"
                                        ReturnToCastle -> "Returning to Castle"
                                        DeliveringGold -> "Delivering Gold"
                                        )) x y)
                                        (D.field "clientX" D.float)
                                        (D.field "clientY" D.float)
                                    )
                                , Html.Events.onMouseLeave TooltipLeave
                                ]
                                [ text ("Behavior: " ++ (case unit.behavior of
                                    Thinking -> "Thinking"
                                    FindingRandomTarget -> "Finding Target"
                                    MovingTowardTarget -> "Moving"
                                    Dead -> "Dead"
                                    DebugError msg -> "Error: " ++ msg
                                    WithoutHome -> "Without Home"
                                    LookingForTask -> "Looking for Task"
                                    GoingToSleep -> "Going to Sleep"
                                    Sleeping -> "Sleeping"
                                    LookForBuildRepairTarget -> "Looking for Build/Repair"
                                    BuildingConstruction -> "Building"
                                    Repairing -> "Repairing"
                                    LookForTaxTarget -> "Looking for Tax Target"
                                    CollectingTaxes -> "Collecting Taxes"
                                    ReturnToCastle -> "Returning to Castle"
                                    DeliveringGold -> "Delivering Gold"
                                    ))
                                ]
                            ]
                        ]

                Nothing ->
                    div
                        [ style "padding" "12px"
                        , style "color" "#f00"
                        , style "font-size" "12px"
                        ]
                        [ text "Unit not found" ]

        content =
            case model.selected of
                Nothing ->
                    [ noSelectionContent ]

                Just GlobalButtonDebug ->
                    [ debugTabbedContent model ]

                Just GlobalButtonBuild ->
                    [ buildContent ]

                Just (BuildingSelected buildingId) ->
                    [ buildingSelectedContent buildingId ]

                Just (UnitSelected unitId) ->
                    [ unitSelectedContent unitId ]
    in
    div
        [ style "position" "absolute"
        , style "bottom" "20px"
        , style "right" "224px"
        , style "width" (String.fromFloat panelWidth ++ "px")
        , style "height" (String.fromInt panelHeight ++ "px")
        , style "background-color" "rgba(0, 0, 0, 0.8)"
        , style "border" "2px solid #666"
        , style "border-radius" "4px"
        , style "overflow-x" "scroll"
        , style "overflow-y" "hidden"
        , style "-webkit-overflow-scrolling" "touch"
        , style "scrollbar-width" "auto"
        , style "scrollbar-color" "#888 #222"
        ]
        [ div
            [ style "display" "flex"
            , style "align-items" "flex-start"
            , style "width" "max-content"
            , style "min-width" "100%"
            ]
            content
        ]


viewGoldCounter : Model -> Html Msg
viewGoldCounter model =
    let
        isPaused =
            model.simulationSpeed == Pause
    in
    div
        [ style "position" "absolute"
        , style "bottom" "190px"
        , style "right" "20px"
        , style "display" "flex"
        , style "align-items" "center"
        , style "gap" "8px"
        , style "background-color" "rgba(0, 0, 0, 0.7)"
        , style "padding" "8px 12px"
        , style "border-radius" "4px"
        , style "border" "2px solid #FFD700"
        ]
        [ div
            [ style "width" "20px"
            , style "height" "20px"
            , style "border-radius" "50%"
            , style "background-color" "#FFD700"
            , style "border" "2px solid #FFA500"
            ]
            []
        , div
            [ style "color" "#FFD700"
            , style "font-family" "monospace"
            , style "font-size" "18px"
            , style "font-weight" "bold"
            ]
            [ text (String.fromInt model.gold) ]
        , if isPaused then
            div
                [ style "color" "#FF6B6B"
                , style "font-family" "monospace"
                , style "font-size" "12px"
                , style "font-weight" "bold"
                ]
                [ text "PAUSED" ]

          else
            text ""
        ]


viewMinimap : Model -> Html Msg
viewMinimap model =
    let
        minimapWidth =
            200

        minimapHeight =
            150

        padding =
            10

        scale =
            min ((toFloat minimapWidth - padding * 2) / model.mapConfig.width) ((toFloat minimapHeight - padding * 2) / model.mapConfig.height)

        ( winWidth, winHeight ) =
            model.windowSize

        viewportIndicatorX =
            padding + (model.camera.x * scale)

        viewportIndicatorY =
            padding + (model.camera.y * scale)

        viewportIndicatorWidth =
            toFloat winWidth * scale

        viewportIndicatorHeight =
            toFloat winHeight * scale

        cursor =
            case model.dragState of
                DraggingViewport _ ->
                    "grabbing"

                DraggingMinimap _ ->
                    "grabbing"

                NotDragging ->
                    "grab"
    in
    div
        [ style "position" "absolute"
        , style "bottom" "20px"
        , style "right" "20px"
        , style "width" (String.fromInt minimapWidth ++ "px")
        , style "height" (String.fromInt minimapHeight ++ "px")
        , style "background-color" "#333"
        , style "border" "2px solid #fff"
        , style "overflow" "visible"
        , style "cursor" cursor
        , stopPropagationOn "mousedown" (decodeMinimapMouseEvent MinimapMouseDown)
        ]
        [ div
            [ style "width" (String.fromFloat (model.mapConfig.width * scale) ++ "px")
            , style "height" (String.fromFloat (model.mapConfig.height * scale) ++ "px")
            , style "background-color" "#1a6b1a"
            , style "position" "relative"
            , style "left" (String.fromFloat padding ++ "px")
            , style "top" (String.fromFloat padding ++ "px")
            , style "border" "1px solid #fff"
            ]
            (List.map (viewMinimapBuilding scale model.gridConfig.buildGridSize) model.buildings
                ++ List.map (viewMinimapUnit scale) model.units
                ++ [ div
                        [ style "position" "absolute"
                        , style "left" (String.fromFloat (model.camera.x * scale) ++ "px")
                        , style "top" (String.fromFloat (model.camera.y * scale) ++ "px")
                        , style "width" (String.fromFloat viewportIndicatorWidth ++ "px")
                        , style "height" (String.fromFloat viewportIndicatorHeight ++ "px")
                        , style "border" "2px solid #ff0000"
                        , style "background-color" "rgba(255, 255, 255, 0.2)"
                        , style "pointer-events" "none"
                        ]
                        []
                   ]
            )
        ]


viewMinimapBuilding : Float -> Float -> Building -> Html Msg
viewMinimapBuilding scale buildGridSize building =
    let
        worldX =
            toFloat building.gridX * buildGridSize

        worldY =
            toFloat building.gridY * buildGridSize

        buildingSizeCells =
            buildingSizeToGridCells building.size

        worldWidth =
            toFloat buildingSizeCells * buildGridSize

        worldHeight =
            toFloat buildingSizeCells * buildGridSize

        minimapX =
            worldX * scale

        minimapY =
            worldY * scale

        minimapWidth =
            worldWidth * scale

        minimapHeight =
            worldHeight * scale

        buildingColor =
            case building.owner of
                Player ->
                    "#7FFFD4"

                Enemy ->
                    "#FF0000"
    in
    div
        [ style "position" "absolute"
        , style "left" (String.fromFloat minimapX ++ "px")
        , style "top" (String.fromFloat minimapY ++ "px")
        , style "width" (String.fromFloat minimapWidth ++ "px")
        , style "height" (String.fromFloat minimapHeight ++ "px")
        , style "background-color" buildingColor
        , style "pointer-events" "none"
        ]
        []


viewMinimapUnit : Float -> Unit -> Html Msg
viewMinimapUnit scale unit =
    case unit.location of
        OnMap worldX worldY ->
            let
                minimapX =
                    worldX * scale

                minimapY =
                    worldY * scale

                -- Unit dot size on minimap
                dotSize =
                    3

                unitColor =
                    case unit.owner of
                        Player ->
                            "#7FFFD4"

                        Enemy ->
                            "#FF0000"
            in
            div
                [ style "position" "absolute"
                , style "left" (String.fromFloat (minimapX - dotSize / 2) ++ "px")
                , style "top" (String.fromFloat (minimapY - dotSize / 2) ++ "px")
                , style "width" (String.fromFloat dotSize ++ "px")
                , style "height" (String.fromFloat dotSize ++ "px")
                , style "background-color" unitColor
                , style "border-radius" "50%"
                , style "pointer-events" "none"
                ]
                []

        Garrisoned _ ->
            text ""


viewTooltip : Model -> Html Msg
viewTooltip model =
    case model.tooltipHover of
        Just tooltipState ->
            if tooltipState.hoverTime >= 500 then
                -- Show tooltip after 500ms
                case tooltipState.elementId of
                    "building-Test Building" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 100) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "8px 12px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            ]
                            [ div [ style "font-weight" "bold", style "margin-bottom" "4px" ]
                                [ text "Test Building" ]
                            , div [ style "color" "#aaa" ]
                                [ text ("HP: " ++ String.fromInt testBuildingTemplate.maxHp) ]
                            , div [ style "color" "#aaa" ]
                                [ text ("Size: 2×2") ]
                            , div [ style "color" "#aaa" ]
                                [ text ("Garrison: " ++ String.fromInt testBuildingTemplate.garrisonSlots) ]
                            ]

                    "building-Castle" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 120) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "8px 12px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            ]
                            [ div [ style "font-weight" "bold", style "margin-bottom" "4px" ]
                                [ text "Castle" ]
                            , div [ style "color" "#aaa" ]
                                [ text ("HP: " ++ String.fromInt castleTemplate.maxHp) ]
                            , div [ style "color" "#aaa" ]
                                [ text "Size: 4×4" ]
                            , div [ style "color" "#aaa" ]
                                [ text ("Garrison: " ++ String.fromInt castleTemplate.garrisonSlots ++ " henchmen") ]
                            , div [ style "color" "#FFD700", style "margin-top" "4px" ]
                                [ text "Mission-critical building" ]
                            ]

                    "building-House" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 100) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "8px 12px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            ]
                            [ div [ style "font-weight" "bold", style "margin-bottom" "4px" ]
                                [ text "House" ]
                            , div [ style "color" "#aaa" ]
                                [ text ("HP: " ++ String.fromInt houseTemplate.maxHp) ]
                            , div [ style "color" "#aaa" ]
                                [ text "Size: 2×2" ]
                            , div [ style "color" "#FFD700", style "margin-top" "4px" ]
                                [ text "Generates gold" ]
                            ]

                    "building-Warrior's Guild" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 100) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "8px 12px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            ]
                            [ div [ style "font-weight" "bold", style "margin-bottom" "4px" ]
                                [ text "Warrior's Guild" ]
                            , div [ style "color" "#aaa" ]
                                [ text ("HP: " ++ String.fromInt warriorsGuildTemplate.maxHp) ]
                            , div [ style "color" "#aaa" ]
                                [ text "Size: 3×3" ]
                            , div [ style "color" "#FFD700", style "margin-top" "4px" ]
                                [ text "Trains warriors, generates gold" ]
                            ]

                    "tag-Building" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "This is a building" ]

                    "tag-Hero" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "This is a hero" ]

                    "tag-Henchman" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "This is a henchman" ]

                    "tag-Guild" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "This building produces and houses Heroes" ]

                    "tag-Objective" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "If this dies, the player loses the game" ]

                    "tag-Coffer" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "This building has a Gold Coffer" ]

                    "behavior-Idle" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "The building is not performing any actions" ]

                    "behavior-Under Construction" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "The building is under construction" ]

                    "behavior-Spawn House" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "The Castle is periodically spawning Houses for the kingdom" ]

                    "behavior-Generate Gold" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "The building is generating gold into its coffer" ]

                    "behavior-Thinking" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "The unit is pausing before deciding on next action" ]

                    "behavior-Finding Target" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "The unit is calculating a path to a random destination" ]

                    "behavior-Moving" ->
                        div
                            [ style "position" "fixed"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            , style "transform" "translateX(-50%)"
                            , style "background-color" "rgba(0, 0, 0, 0.9)"
                            , style "border" "2px solid #666"
                            , style "border-radius" "4px"
                            , style "padding" "6px 10px"
                            , style "color" "#fff"
                            , style "font-family" "monospace"
                            , style "font-size" "11px"
                            , style "pointer-events" "none"
                            , style "z-index" "1000"
                            , style "white-space" "nowrap"
                            ]
                            [ text "The unit is following its path to the destination" ]

                    _ ->
                        -- Check if it's a garrison tooltip
                        if String.startsWith "garrison-" tooltipState.elementId then
                            let
                                buildingIdStr =
                                    String.dropLeft 9 tooltipState.elementId

                                maybeBuildingId =
                                    String.toInt buildingIdStr

                                maybeBuilding =
                                    case maybeBuildingId of
                                        Just buildingId ->
                                            List.filter (\b -> b.id == buildingId) model.buildings
                                                |> List.head

                                        Nothing ->
                                            Nothing
                            in
                            case maybeBuilding of
                                Just building ->
                                    div
                                        [ style "position" "fixed"
                                        , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                                        , style "top" (String.fromFloat (tooltipState.mouseY - 80) ++ "px")
                                        , style "transform" "translateX(-50%)"
                                        , style "background-color" "rgba(0, 0, 0, 0.9)"
                                        , style "border" "2px solid #666"
                                        , style "border-radius" "4px"
                                        , style "padding" "8px 12px"
                                        , style "color" "#fff"
                                        , style "font-family" "monospace"
                                        , style "font-size" "11px"
                                        , style "pointer-events" "none"
                                        , style "z-index" "1000"
                                        ]
                                        [ div [ style "font-weight" "bold", style "margin-bottom" "4px" ]
                                            [ text "Garrison" ]
                                        , div [ style "color" "#aaa" ]
                                            [ text ("Current: " ++ String.fromInt building.garrisonOccupied) ]
                                        , div [ style "color" "#aaa" ]
                                            [ text ("Capacity: " ++ String.fromInt building.garrisonSlots) ]
                                        , div [ style "color" "#aaa" ]
                                            [ text "Next unit: Not implemented" ]
                                        ]

                                Nothing ->
                                    text ""

                        else
                            text ""

            else
                text ""

        Nothing ->
            text ""


viewPreGameOverlay : Model -> Html Msg
viewPreGameOverlay model =
    case model.gameState of
        PreGame ->
            div
                [ style "position" "fixed"
                , style "top" "20px"
                , style "right" "20px"
                , style "background-color" "rgba(0, 0, 0, 0.8)"
                , style "border" "3px solid #FFD700"
                , style "border-radius" "8px"
                , style "padding" "16px 24px"
                , style "color" "#FFD700"
                , style "font-family" "monospace"
                , style "font-size" "18px"
                , style "font-weight" "bold"
                , style "pointer-events" "none"
                , style "z-index" "1000"
                ]
                [ text "Site your Castle" ]

        _ ->
            text ""


viewGameOverOverlay : Model -> Html Msg
viewGameOverOverlay model =
    case model.gameState of
        GameOver ->
            div
                [ style "position" "fixed"
                , style "top" "0"
                , style "left" "0"
                , style "width" "100vw"
                , style "height" "100vh"
                , style "background-color" "rgba(0, 0, 0, 0.9)"
                , style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "color" "#f00"
                , style "font-family" "monospace"
                , style "font-size" "64px"
                , style "font-weight" "bold"
                , style "z-index" "2000"
                , style "pointer-events" "none"
                ]
                [ text "GAME OVER" ]

        _ ->
            text ""


decodeMinimapMouseEvent : (Float -> Float -> Msg) -> D.Decoder ( Msg, Bool )
decodeMinimapMouseEvent msg =
    D.map2 (\x y -> ( msg x y, True ))
        (D.field "clientX" D.float)
        (D.field "clientY" D.float)
