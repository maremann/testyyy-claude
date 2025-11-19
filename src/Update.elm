module Update exposing (update, subscriptions, init, generateShapes)
import Browser.Dom as Dom
import Browser.Events as E
import BuildingTemplates exposing (castleTemplate, houseTemplate, randomUnitColor, warriorsGuildTemplate)
import Camera exposing (MinimapConfig, centerCameraOnMinimapClick, constrainCamera, getMinimapScale, isClickOnViewbox, minimapClickOffset, minimapDragToCamera)
import Dict
import GameHelpers exposing (createHenchman, recalculateAllPaths)
import GameStrings
import Grid exposing (..)
import Json.Decode as D
import Message exposing (Msg(..))
import Pathfinding exposing (findPath)
import Random
import Simulation exposing (simulationTick)
import Task
import Types exposing (..)
init : () -> ( Model, Cmd Msg )
init _ =
    let
        mapConfig = { width = 4992
            , height = 4992
            , boundary = 500
            }
        gridConfig = { buildGridSize = 64
            , pathfindingGridSize = 32
            }
        initialModel = { camera = { x = 2496, y = 2496 }
            , dragState = NotDragging
            , windowSize = ( 800, 600 )
            , decorativeShapes = []
            , mapConfig = mapConfig
            , gameState = PreGame
            , gold = 50000
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
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WindowResize width height -> ( { model | windowSize = ( width, height ) }, Cmd.none )
        MouseDown x y ->
            ( { model | dragState = DraggingViewport { x = x, y = y } }, Cmd.none )
        MouseMove x y ->
            case model.dragState of
                DraggingViewport startPos ->
                    let
                        dx = startPos.x - x
                        dy = startPos.y - y
                        newCamera = constrainCamera model.mapConfig model.windowSize
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
                _ -> ( model, Cmd.none )
        MouseUp -> ( { model | dragState = NotDragging }, Cmd.none )
        MinimapMouseDown clientX clientY ->
            let
                ( winWidth, winHeight ) = model.windowSize
                minimapWidth = 200
                minimapHeight = 150
                minimapLeft = toFloat winWidth - 20 - 204 + 2
                minimapTop = toFloat winHeight - 20 - 154 + 2
                offsetX = clamp 0 (toFloat minimapWidth) (clientX - minimapLeft)
                offsetY = clamp 0 (toFloat minimapHeight) (clientY - minimapTop)
                minimapConfig = { width = 200
                    , height = 150
                    , padding = 10
                    }
                clickedOnViewbox = isClickOnViewbox model minimapConfig offsetX offsetY
                ( newCamera, dragOffset ) =
                    if clickedOnViewbox then
                        ( model.camera, minimapClickOffset model minimapConfig offsetX offsetY )
                    else
                        let
                            centered =
                                centerCameraOnMinimapClick model minimapConfig offsetX offsetY
                                    |> constrainCamera model.mapConfig model.windowSize
                            scale = getMinimapScale minimapConfig model.mapConfig
                            centerOffset = { x = toFloat winWidth * scale / 2
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
                        ( winWidth, winHeight ) = model.windowSize
                        minimapWidth = 200
                        minimapHeight = 150
                        minimapLeft = toFloat winWidth - 20 - 204 + 2
                        minimapTop = toFloat winHeight - 20 - 154 + 2
                        offsetX = clamp 0 (toFloat minimapWidth) (clientX - minimapLeft)
                        offsetY = clamp 0 (toFloat minimapHeight) (clientY - minimapTop)
                        newCamera = minimapDragToCamera model offset offsetX offsetY
                                |> constrainCamera model.mapConfig model.windowSize
                    in
                    ( { model | camera = newCamera }, Cmd.none )
                _ -> ( model, Cmd.none )
        ShapesGenerated shapes -> ( { model | decorativeShapes = shapes }, Cmd.none )
        GotViewport viewport ->
            let
                width = round viewport.viewport.width
                height = round viewport.viewport.height
            in
            ( { model | windowSize = ( width, height ) }, Cmd.none )
        SelectThing thing ->
            let
                newBuildMode =
                    case thing of
                        GlobalButtonBuild -> model.buildMode
                        _ -> Nothing
            in
            ( { model | selected = Just thing, buildMode = newBuildMode }, Cmd.none )
        ToggleBuildGrid ->
            ( { model | showBuildGrid = not model.showBuildGrid }, Cmd.none )
        TogglePathfindingGrid ->
            ( { model | showPathfindingGrid = not model.showPathfindingGrid }, Cmd.none )
        GoldInputChanged value -> ( { model | goldInputValue = value }, Cmd.none )
        SetGoldFromInput ->
            case String.toInt model.goldInputValue of
                Just amount ->
                    ( { model | gold = amount, goldInputValue = "" }, Cmd.none )
                Nothing -> ( model, Cmd.none )
        TogglePathfindingOccupancy ->
            ( { model | showPathfindingOccupancy = not model.showPathfindingOccupancy }, Cmd.none )
        EnterBuildMode template -> ( { model | buildMode = Just template }, Cmd.none )
        ExitBuildMode -> ( { model | buildMode = Nothing }, Cmd.none )
        WorldMouseMove worldX worldY ->
            ( { model | mouseWorldPos = Just ( worldX, worldY ) }, Cmd.none )
        PlaceBuilding ->
            case ( model.buildMode, model.mouseWorldPos ) of
                ( Just template, Just ( worldX, worldY ) ) ->
                    let
                        gridX = floor (worldX / model.gridConfig.buildGridSize)
                        gridY = floor (worldY / model.gridConfig.buildGridSize)
                        sizeCells = buildingSizeToGridCells template.size
                        centeredGridX = gridX - (sizeCells // 2)
                        centeredGridY = gridY - (sizeCells // 2)
                        isValid =
                            isValidBuildingPlacement centeredGridX centeredGridY template.size model.mapConfig model.gridConfig model.buildingOccupancy model.buildings
                        canAfford = model.gold >= template.cost
                    in
                    if isValid && canAfford then
                        let
                            isCastle = template.name == GameStrings.buildingTypeCastle
                            ( buildingBehavior, buildingTags ) =
                                if isCastle then
                                    ( SpawnHouse, [ BuildingTag, ObjectiveTag ] )
                                else
                                    ( UnderConstruction, [ BuildingTag ] )
                            initialDuration =
                                case buildingBehavior of
                                    SpawnHouse ->
                                        30.0 + toFloat (modBy 15000 (model.nextBuildingId * 1000)) / 1000.0
                                    GenerateGold ->
                                        15.0 + toFloat (modBy 30000 (model.nextBuildingId * 1000)) / 1000.0
                                    _ -> 0
                            initialGarrisonConfig =
                                if isCastle then
                                    [ { unitType = GameStrings.unitTypeCastleGuard, maxCount = 2, currentCount = 1, spawnTimer = 0 }
                                    , { unitType = GameStrings.unitTypeTaxCollector, maxCount = 1, currentCount = 1, spawnTimer = 0 }
                                    , { unitType = GameStrings.unitTypePeasant, maxCount = 3, currentCount = 1, spawnTimer = 0 }
                                    ]
                                else
                                    []
                            initialHp =
                                if isCastle then
                                    template.maxHp
                                else
                                    max 1 (template.maxHp // 10)
                            initialGarrisonOccupied =
                                List.foldl (\slot acc -> acc + slot.currentCount) 0 initialGarrisonConfig
                            newBuilding = { id = model.nextBuildingId
                                , owner = Player
                                , gridX = centeredGridX
                                , gridY = centeredGridY
                                , size = template.size
                                , hp = initialHp
                                , maxHp = template.maxHp
                                , garrisonSlots = template.garrisonSlots
                                , garrisonOccupied = initialGarrisonOccupied
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
                            ( initialUnits, nextUnitIdAfterInitial ) =
                                if isCastle then
                                    let
                                        unitsToCreate = [ ( GameStrings.unitTypeCastleGuard, model.nextUnitId )
                                            , ( GameStrings.unitTypeTaxCollector, model.nextUnitId + 1 )
                                            , ( GameStrings.unitTypePeasant, model.nextUnitId + 2 )
                                            ]
                                    in
                                    ( List.map
                                        (\( unitType, unitId ) ->
                                            createHenchman unitType unitId model.nextBuildingId newBuilding
                                        )
                                        unitsToCreate
                                    , model.nextUnitId + 3
                                    )
                                else
                                    ( [], model.nextUnitId )
                            updatedUnits =
                                recalculateAllPaths model.gridConfig model.mapConfig newPathfindingOccupancy (model.units ++ initialUnits)
                            newGameState =
                                if model.gameState == PreGame && template.name == GameStrings.buildingTypeCastle then
                                    Playing
                                else
                                    model.gameState
                        in
                        ( { model
                            | buildings = newBuilding :: model.buildings
                            , buildingOccupancy = newBuildingOccupancy
                            , pathfindingOccupancy = newPathfindingOccupancy
                            , nextBuildingId = model.nextBuildingId + 1
                            , nextUnitId = nextUnitIdAfterInitial
                            , gold = model.gold - template.cost
                            , buildMode = Nothing
                            , units = updatedUnits
                            , gameState = newGameState
                          }
                        , Cmd.none
                        )
                    else
                        ( model, Cmd.none )
                _ -> ( model, Cmd.none )
        ToggleBuildingOccupancy ->
            ( { model | showBuildingOccupancy = not model.showBuildingOccupancy }, Cmd.none )
        ToggleCityActiveArea ->
            ( { model | showCityActiveArea = not model.showCityActiveArea }, Cmd.none )
        ToggleCitySearchArea ->
            ( { model | showCitySearchArea = not model.showCitySearchArea }, Cmd.none )
        TooltipEnter elementId x y ->
            ( { model | tooltipHover = Just { elementId = elementId, hoverTime = 0, mouseX = x, mouseY = y } }, Cmd.none )
        TooltipLeave -> ( { model | tooltipHover = Nothing }, Cmd.none )
        SetSimulationSpeed speed -> ( { model | simulationSpeed = speed }, Cmd.none )
        SetDebugTab tab -> ( { model | debugTab = tab }, Cmd.none )
        SetBuildingTab tab -> ( { model | buildingTab = tab }, Cmd.none )
        Frame delta -> ( simulationTick delta model, Cmd.none )
generateShapes : Int -> MapConfig -> Random.Generator (List DecorativeShape)
generateShapes count config = Random.list count (generateShape config)
generateShape : MapConfig -> Random.Generator DecorativeShape
generateShape config = Random.map5 DecorativeShape
        (Random.float 0 config.width)
        (Random.float 0 config.height)
        (Random.float 20 80)
        generateShapeType
        generateColor
generateShapeType : Random.Generator ShapeType
generateShapeType = Random.uniform Circle [ Rectangle ]
generateColor : Random.Generator String
generateColor =
    Random.uniform "#8B4513" [ "#A0522D", "#D2691E", "#CD853F", "#DEB887", "#228B22", "#006400" ]
subscriptions : Model -> Sub Msg
subscriptions model =
    case model.dragState of
        NotDragging -> Sub.batch
                [ E.onResize WindowResize
                , E.onAnimationFrameDelta Frame
                ]
        DraggingViewport _ -> Sub.batch
                [ E.onResize WindowResize
                , E.onMouseMove (D.map2 MouseMove (D.field "clientX" D.float) (D.field "clientY" D.float))
                , E.onMouseUp (D.succeed MouseUp)
                , E.onAnimationFrameDelta Frame
                ]
        DraggingMinimap _ -> Sub.batch
                [ E.onResize WindowResize
                , E.onMouseMove (D.map2 MinimapMouseMove (D.field "clientX" D.float) (D.field "clientY" D.float))
                , E.onMouseUp (D.succeed MouseUp)
                , E.onAnimationFrameDelta Frame
                ]
