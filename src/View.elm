module View exposing (view)

import BuildingTemplates exposing (castleTemplate, houseTemplate, testBuildingTemplate, warriorsGuildTemplate)
import Dict
import Grid exposing (getBuildingEntrance, getCityActiveArea, getCitySearchArea, isPathfindingCellOccupied, isValidBuildingPlacement)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style, placeholder, value)
import Html.Events exposing (on, onClick, onInput, onMouseLeave, stopPropagationOn)
import Json.Decode as D
import Message exposing (Msg(..))
import Types exposing (..)
import View.SelectionPanel exposing (viewSelectionPanel)


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
        [ class "root-container"
        ]
        [ viewMainViewport model cursor viewportWidth viewportHeight
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
        [ class "main-viewport"
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
        [ class "abs"
        , style "left" (String.fromFloat terrainLeft ++ "px")
        , style "top" (String.fromFloat terrainTop ++ "px")
        , style "width" (String.fromFloat terrainWidth ++ "px")
        , style "height" (String.fromFloat terrainHeight ++ "px")
        , class "bg-map"
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
                    ( [ class "rounded-full" ], shape.size / 2 )

                Rectangle ->
                    ( [], 0 )
    in
    div
        ([ class "abs"
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
        [ class "abs flex items-center justify-center text-white text-12 font-bold cursor-pointer select-none"
        , style "left" (String.fromFloat screenX ++ "px")
        , style "top" (String.fromFloat screenY ++ "px")
        , style "width" (String.fromFloat buildingSizePx ++ "px")
        , style "height" (String.fromFloat buildingSizePx ++ "px")
        , style "background-color" buildingColor
        , class "border-333"
        , Html.Events.onClick (SelectThing (BuildingSelected building.id))
        ]
        [ text (building.buildingType ++
            (if building.behavior == UnderConstruction then
                " (under construction)"
             else
                ""
            ))
        , -- Entrance overlay
          div
            [ class "abs pe-none"
            , style "left" (String.fromFloat entranceOffsetX ++ "px")
            , style "top" (String.fromFloat entranceOffsetY ++ "px")
            , style "width" (String.fromFloat entranceTileSize ++ "px")
            , style "height" (String.fromFloat entranceTileSize ++ "px")
            , class "bg-brown-entrance border-entrance"
            ]
            []
        , if isSelected then
            div
                [ class "abs pe-none rounded bg-gold-selection"
                , style "inset" "0"
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
            [ class "bar bottom--8"
            , style "height" "4px"
            ]
            [ div
                [ class "bar__fill"
                , style "width" (String.fromFloat (healthPercent * 100) ++ "%")
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
        [ class "abs cursor-pointer select-none flex items-center justify-center"
        , style "left" (String.fromFloat (screenX - selectionRadius) ++ "px")
        , style "top" (String.fromFloat (screenY - selectionRadius) ++ "px")
        , style "width" (String.fromFloat selectionDiameter ++ "px")
        , style "height" (String.fromFloat selectionDiameter ++ "px")
        , Html.Events.onClick (SelectThing (UnitSelected unit.id))
        ]
        [ -- Inner visual representation (smaller)
          div
            [ class "rounded-full flex items-center justify-center text-white font-bold pe-none border-333 text-8"
            , style "width" (String.fromFloat visualDiameter ++ "px")
            , style "height" (String.fromFloat visualDiameter ++ "px")
            , style "background-color" unit.color
            ]
            [ text (case unit.unitType of
                "Peasant" -> "P"
                "Tax Collector" -> "T"
                "Castle Guard" -> "G"
                _ -> "?"
            ) ]
        , if isSelected then
            div
                [ class "abs pe-none rounded-full bg-gold-selection"
                , style "width" (String.fromFloat visualDiameter ++ "px")
                , style "height" (String.fromFloat visualDiameter ++ "px")
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
            [ class "bar"
            , style "bottom" (String.fromFloat (selectionRadius - visualRadius - 6) ++ "px")
            , style "height" "3px"
            ]
            [ div
                [ class "bar__fill"
                , style "width" (String.fromFloat (healthPercent * 100) ++ "%")
                ]
                []
            ]
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
                                    [ class "abs pe-none rounded-full bg-gold border border-gold opacity-80"
                                    , style "left" (String.fromFloat (screenX - dotSize / 2) ++ "px")
                                    , style "top" (String.fromFloat (screenY - dotSize / 2) ++ "px")
                                    , style "width" (String.fromFloat dotSize ++ "px")
                                    , style "height" (String.fromFloat dotSize ++ "px")
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
                        [ class "abs pe-none w-1"
                        , style "left" (String.fromFloat (toFloat x - model.camera.x) ++ "px")
                        , style "top" (String.fromFloat terrainTop ++ "px")
                        , style "height" (String.fromFloat model.mapConfig.height ++ "px")
                        , style "background-color" color
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
                        [ class "abs pe-none h-1"
                        , style "left" (String.fromFloat terrainLeft ++ "px")
                        , style "top" (String.fromFloat (toFloat y - model.camera.y) ++ "px")
                        , style "width" (String.fromFloat model.mapConfig.width ++ "px")
                        , style "background-color" color
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
                    [ class "abs pe-none"
                    , style "left" (String.fromFloat screenX ++ "px")
                    , style "top" (String.fromFloat screenY ++ "px")
                    , style "width" (String.fromFloat gridSize ++ "px")
                    , style "height" (String.fromFloat gridSize ++ "px")
                    , class "bg-dark-blue"
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
                    [ class "abs pe-none"
                    , style "left" (String.fromFloat screenX ++ "px")
                    , style "top" (String.fromFloat screenY ++ "px")
                    , style "width" (String.fromFloat gridSize ++ "px")
                    , style "height" (String.fromFloat gridSize ++ "px")
                    , class "bg-orange-alpha"
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
                    [ class "abs pe-none"
                    , style "left" (String.fromFloat screenX ++ "px")
                    , style "top" (String.fromFloat screenY ++ "px")
                    , style "width" (String.fromFloat gridSize ++ "px")
                    , style "height" (String.fromFloat gridSize ++ "px")
                    , class "bg-green-alpha-2"
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
                    [ class "abs pe-none"
                    , style "left" (String.fromFloat screenX ++ "px")
                    , style "top" (String.fromFloat screenY ++ "px")
                    , style "width" (String.fromFloat gridSize ++ "px")
                    , style "height" (String.fromFloat gridSize ++ "px")
                    , class "bg-green-alpha-1"
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
                                        [ class "abs pe-none rounded-full"
                                        , style "left" (String.fromFloat (screenX - unit.activeRadius) ++ "px")
                                        , style "top" (String.fromFloat (screenY - unit.activeRadius) ++ "px")
                                        , style "width" (String.fromFloat (unit.activeRadius * 2) ++ "px")
                                        , style "height" (String.fromFloat (unit.activeRadius * 2) ++ "px")
                                        , class "border-yellow-alpha-6"
                                        ]
                                        []

                                -- Search radius circle
                                searchCircle =
                                    div
                                        [ class "abs pe-none rounded-full"
                                        , style "left" (String.fromFloat (screenX - unit.searchRadius) ++ "px")
                                        , style "top" (String.fromFloat (screenY - unit.searchRadius) ++ "px")
                                        , style "width" (String.fromFloat (unit.searchRadius * 2) ++ "px")
                                        , style "height" (String.fromFloat (unit.searchRadius * 2) ++ "px")
                                        , class "border-yellow-alpha-3"
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
                [ class "abs pe-none"
                , style "left" (String.fromFloat screenX ++ "px")
                , style "top" (String.fromFloat screenY ++ "px")
                , style "width" (String.fromFloat buildingSizePx ++ "px")
                , style "height" (String.fromFloat buildingSizePx ++ "px")
                , style "background-color" previewColor
                , class "border-white-alpha flex items-center justify-center text-fff text-14 font-bold"
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
                [ class
                    ("button text-12 font-bold"
                        ++ (if isSelected then
                                " button--selected"
                            else
                                ""
                           )
                    )
                , class "w-full h-36"
                , Html.Events.onClick (SelectThing selectable)
                ]
                [ text label ]
    in
    div
        [ class "panel panel-col p-8 gap-6 abs bottom-20"
        , style "left" (String.fromFloat leftPosition ++ "px")
        , style "width" (String.fromInt panelSize ++ "px")
        , style "height" (String.fromInt panelSize ++ "px")
        ]
        [ button "Debug" GlobalButtonDebug (model.selected == Just GlobalButtonDebug)
        , button "Build" GlobalButtonBuild (model.selected == Just GlobalButtonBuild)
        ]


viewGoldCounter : Model -> Html Msg
viewGoldCounter model =
    let
        isPaused =
            model.simulationSpeed == Pause
    in
    div
        [ class "flex items-center gap-8 rounded border-2 border-gold abs py-8 px-12 bottom-190 right-20 bg-black-alpha-7"
        ]
        [ div
            [ class "square-20 rounded-full bg-gold border-2 border-gold"
            ]
            []
        , div
            [ class "text-gold font-mono font-bold text-18"
            ]
            [ text (String.fromInt model.gold) ]
        , if isPaused then
            div
                [ class "font-mono font-bold text-12 text-red-6b"
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
        [ class "abs bottom-20 right-20 overflow-visible bg-333 border-fff"
        , style "width" (String.fromInt minimapWidth ++ "px")
        , style "height" (String.fromInt minimapHeight ++ "px")
        , style "cursor" cursor
        , stopPropagationOn "mousedown" (decodeMinimapMouseEvent MinimapMouseDown)
        ]
        [ div
            [ style "width" (String.fromFloat (model.mapConfig.width * scale) ++ "px")
            , style "height" (String.fromFloat (model.mapConfig.height * scale) ++ "px")
            , class "bg-map rel border-fff-1"
            , style "left" (String.fromFloat padding ++ "px")
            , style "top" (String.fromFloat padding ++ "px")
            ]
            (List.map (viewMinimapBuilding scale model.gridConfig.buildGridSize) model.buildings
                ++ List.map (viewMinimapUnit scale) model.units
                ++ [ div
                    [ class "abs pe-none minimap-viewport"
                    , style "left" (String.fromFloat (model.camera.x * scale) ++ "px")
                    , style "top" (String.fromFloat (model.camera.y * scale) ++ "px")
                    , style "width" (String.fromFloat viewportIndicatorWidth ++ "px")
                    , style "height" (String.fromFloat viewportIndicatorHeight ++ "px")
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
        [ class "abs"
        , style "left" (String.fromFloat minimapX ++ "px")
        , style "top" (String.fromFloat minimapY ++ "px")
        , style "width" (String.fromFloat minimapWidth ++ "px")
        , style "height" (String.fromFloat minimapHeight ++ "px")
        , style "background-color" buildingColor
        , class "pe-none"
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
                [ class "abs pe-none"
                , style "left" (String.fromFloat (minimapX - dotSize / 2) ++ "px")
                , style "top" (String.fromFloat (minimapY - dotSize / 2) ++ "px")
                , style "width" (String.fromFloat dotSize ++ "px")
                , style "height" (String.fromFloat dotSize ++ "px")
                , style "background-color" unitColor
                , class "rounded-full"
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
                            [ class "tooltip pe-none py-8 px-12"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 100) ++ "px")
                            ]
                            [ div [ class "font-bold", style "margin-bottom" "4px" ] [ text "Test Building" ]
                            , div [ class "text-muted" ] [ text ("HP: " ++ String.fromInt testBuildingTemplate.maxHp) ]
                            , div [ class "text-muted" ] [ text ("Size: 2×2") ]
                            , div [ class "text-muted" ] [ text ("Garrison: " ++ String.fromInt testBuildingTemplate.garrisonSlots) ]
                            ]

                    "building-Castle" ->
                        div
                            [ class "tooltip pe-none py-8 px-12"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 120) ++ "px")
                            ]
                            [ div [ class "font-bold", style "margin-bottom" "4px" ] [ text "Castle" ]
                            , div [ class "text-muted" ] [ text ("HP: " ++ String.fromInt castleTemplate.maxHp) ]
                            , div [ class "text-muted" ] [ text "Size: 4×4" ]
                            , div [ class "text-muted" ] [ text ("Garrison: " ++ String.fromInt castleTemplate.garrisonSlots ++ " henchmen") ]
                            , div [ class "text-gold", style "margin-top" "4px" ] [ text "Mission-critical building" ]
                            ]

                    "building-House" ->
                        div
                            [ class "tooltip pe-none py-8 px-12"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 100) ++ "px")
                            ]
                            [ div [ class "font-bold", style "margin-bottom" "4px" ] [ text "House" ]
                            , div [ class "text-muted" ] [ text ("HP: " ++ String.fromInt houseTemplate.maxHp) ]
                            , div [ class "text-muted" ] [ text "Size: 2×2" ]
                            , div [ class "text-gold", style "margin-top" "4px" ] [ text "Generates gold" ]
                            ]

                    "building-Warrior's Guild" ->
                        div
                            [ class "tooltip pe-none py-8 px-12"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 100) ++ "px")
                            ]
                            [ div [ class "font-bold", style "margin-bottom" "4px" ] [ text "Warrior's Guild" ]
                            , div [ class "text-muted" ] [ text ("HP: " ++ String.fromInt warriorsGuildTemplate.maxHp) ]
                            , div [ class "text-muted" ] [ text "Size: 3×3" ]
                            , div [ class "text-gold", style "margin-top" "4px" ] [ text "Trains warriors, generates gold" ]
                            ]

                    "tag-Building" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "This is a building" ]

                    "tag-Hero" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "This is a hero" ]

                    "tag-Henchman" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "This is a henchman" ]

                    "tag-Guild" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "This building produces and houses Heroes" ]

                    "tag-Objective" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "If this dies, the player loses the game" ]

                    "tag-Coffer" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "This building has a Gold Coffer" ]

                    "behavior-Idle" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The building is not performing any actions" ]

                    "behavior-Under Construction" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The building is under construction" ]

                    "behavior-Spawn House" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The Castle is periodically spawning Houses for the kingdom" ]

                    "behavior-Generate Gold" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The building is generating gold into its coffer" ]

                    "behavior-Thinking" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The unit is pausing before deciding on next action" ]

                    "behavior-Finding Target" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The unit is calculating a path to a random destination" ]

                    "behavior-Moving" ->
                        div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
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
                                        [ class "tooltip pe-none py-8 px-12"
                                        , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                                        , style "top" (String.fromFloat (tooltipState.mouseY - 80) ++ "px")
                                        ]
                                        [ div [ class "font-bold", style "margin-bottom" "4px" ] [ text "Garrison" ]
                                        , div [ class "text-muted" ] [ text ("Current: " ++ String.fromInt building.garrisonOccupied) ]
                                        , div [ class "text-muted" ] [ text ("Capacity: " ++ String.fromInt building.garrisonSlots) ]
                                        , div [ class "text-muted" ] [ text "Next unit: Not implemented" ]
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
                [ class "panel font-mono font-bold text-gold pe-none fix right-20 border-gold py-16 px-24 border-gold-3 text-18"
                , style "top" "20px"
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
                [ class "overlay pe-none bg-black-alpha-9"
                ]
                [ div
                    [ class "font-mono font-bold text-red text-64"
                    ]
                    [ text "GAME OVER" ]
                ]

        _ ->
            text ""


decodeMinimapMouseEvent : (Float -> Float -> Msg) -> D.Decoder ( Msg, Bool )
decodeMinimapMouseEvent msg =
    D.map2 (\x y -> ( msg x y, True ))
        (D.field "clientX" D.float)
        (D.field "clientY" D.float)
