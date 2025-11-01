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


type alias Model =
    { camera : Camera
    , dragState : DragState
    , windowSize : ( Int, Int )
    , decorativeShapes : List DecorativeShape
    , mapConfig : MapConfig
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
    }


type Selectable
    = GlobalButtonDebug
    | GlobalButtonBuild
    | BuildingSelected Int


type BuildingSize
    = Small
    | Medium
    | Large
    | Huge


type BuildingOwner
    = Player
    | Enemy


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
    }


type alias BuildingTemplate =
    { name : String
    , size : BuildingSize
    , cost : Int
    , maxHp : Int
    , garrisonSlots : Int
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
isValidBuildingPlacement : Int -> Int -> BuildingSize -> MapConfig -> GridConfig -> Dict ( Int, Int ) Int -> Bool
isValidBuildingPlacement gridX gridY size mapConfig gridConfig buildingOccupancy =
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
            }

        cellsWithSpacing =
            getBuildingGridCellsWithSpacing tempBuilding

        notOccupied =
            not (areBuildGridCellsOccupied cellsWithSpacing buildingOccupancy)
    in
    inBounds && notOccupied



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
                            isValidBuildingPlacement centeredGridX centeredGridY template.size model.mapConfig model.gridConfig model.buildingOccupancy

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
                                }

                            newBuildingOccupancy =
                                addBuildingGridOccupancy newBuilding model.buildingOccupancy

                            newPathfindingOccupancy =
                                addBuildingOccupancy model.gridConfig newBuilding model.pathfindingOccupancy
                        in
                        ( { model
                            | buildings = newBuilding :: model.buildings
                            , buildingOccupancy = newBuildingOccupancy
                            , pathfindingOccupancy = newPathfindingOccupancy
                            , nextBuildingId = model.nextBuildingId + 1
                            , gold = model.gold - template.cost
                            , buildMode = Nothing
                          }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ToggleBuildingOccupancy ->
            ( { model | showBuildingOccupancy = not model.showBuildingOccupancy }, Cmd.none )


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
            E.onResize WindowResize

        DraggingViewport _ ->
            Sub.batch
                [ E.onResize WindowResize
                , E.onMouseMove (D.map2 MouseMove (D.field "clientX" D.float) (D.field "clientY" D.float))
                , E.onMouseUp (D.succeed MouseUp)
                ]

        DraggingMinimap _ ->
            Sub.batch
                [ E.onResize WindowResize
                , E.onMouseMove (D.map2 MinimapMouseMove (D.field "clientX" D.float) (D.field "clientY" D.float))
                , E.onMouseUp (D.succeed MouseUp)
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
        , viewGrids model viewportWidth viewportHeight
        , viewPathfindingOccupancy model viewportWidth viewportHeight
        , viewBuildingOccupancy model viewportWidth viewportHeight
        , viewBuildingPreview model
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
                    isValidBuildingPlacement centeredGridX centeredGridY template.size model.mapConfig model.gridConfig model.buildingOccupancy
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

        debugInfoSection =
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

        debugGoldSection =
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
                [ div []
                    [ text "Set Gold:" ]
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

        buildContent =
            div
                [ style "display" "flex"
                , style "gap" "8px"
                , style "padding" "8px"
                ]
                [ buildingOption testBuildingTemplate
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
                , div
                    [ style "font-size" "9px"
                    , style "color" "#888"
                    ]
                    [ text ("HP: " ++ String.fromInt template.maxHp) ]
                , div
                    [ style "font-size" "9px"
                    , style "color" "#888"
                    ]
                    [ text ("Garrison: " ++ String.fromInt template.garrisonSlots) ]
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
                    div
                        [ style "padding" "12px"
                        , style "color" "#fff"
                        , style "font-family" "monospace"
                        , style "font-size" "11px"
                        , style "display" "flex"
                        , style "flex-direction" "column"
                        , style "gap" "6px"
                        ]
                        [ div
                            [ style "font-weight" "bold"
                            , style "font-size" "12px"
                            ]
                            [ text building.buildingType ]
                        , div []
                            [ text ("HP: " ++ String.fromInt building.hp ++ "/" ++ String.fromInt building.maxHp) ]
                        , div []
                            [ text ("Garrison: " ++ String.fromInt building.garrisonOccupied ++ "/" ++ String.fromInt building.garrisonSlots) ]
                        , div []
                            [ text ("Owner: " ++ (case building.owner of
                                Player -> "Player"
                                Enemy -> "Enemy"
                                ))
                            ]
                        ]

                Nothing ->
                    div
                        [ style "padding" "12px"
                        , style "color" "#f00"
                        , style "font-size" "12px"
                        ]
                        [ text "Building not found" ]

        content =
            case model.selected of
                Nothing ->
                    [ noSelectionContent ]

                Just GlobalButtonDebug ->
                    [ debugInfoSection, debugGridSection, debugGoldSection ]

                Just GlobalButtonBuild ->
                    [ buildContent ]

                Just (BuildingSelected buildingId) ->
                    [ buildingSelectedContent buildingId ]
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


decodeMinimapMouseEvent : (Float -> Float -> Msg) -> D.Decoder ( Msg, Bool )
decodeMinimapMouseEvent msg =
    D.map2 (\x y -> ( msg x y, True ))
        (D.field "clientX" D.float)
        (D.field "clientY" D.float)
