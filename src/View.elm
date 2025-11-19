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
                        [ class "button font-mono text-10 font-bold py-6 px-12"
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
                        , class "rounded-3"
                        , Html.Events.onClick (SetDebugTab tab)
                        ]
                        [ text label ]

                tabsColumn =
                    div
                        [ class "flex flex-col gap-4 p-8"
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
                [ class "flex"
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
                [ class "p-12 font-mono text-11 flex gap-16 text-green"
                ]
                [ div
                    [ class "flex flex-col gap-6"
                    ]
                    [ div []
                        [ text "Camera: ("
                        , text (String.fromFloat m.camera.x)
                        , text ", "
                        , text (String.fromFloat m.camera.y)
                        , text ")"
                        ]
                    , div
                        [ class "text-muted"
                        ]
                        []
                    , div
                        [ class "text-gold text-12 font-bold"
                        ]
                        []
                    ]
                ]

        debugVisualizationContent =
            let
                checkbox isChecked label onClick =
                    div
                        [ class "flex items-center gap-8 cursor-pointer"
                        , Html.Events.onClick onClick
                        ]
                        [ div
                            [ class "square-14 border-neon-green rounded-sm"
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
                [ class "p-12 font-mono text-11 flex gap-16 text-green"
                ]
                [ div
                    [ class "flex flex-col gap-6"
                    ]
                    [ checkbox model.showBuildGrid "Build Grid" ToggleBuildGrid
                    , checkbox model.showPathfindingGrid "Pathfinding Grid" TogglePathfindingGrid
                    ]
                , div
                    [ class "flex flex-col gap-6"
                    ]
                    [ checkbox model.showPathfindingOccupancy "PF Occupancy" TogglePathfindingOccupancy
                    , checkbox model.showBuildingOccupancy "Build Occupancy" ToggleBuildingOccupancy
                    ]
                , div
                    [ class "flex flex-col gap-6"
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
                        [ class "flex items-center gap-6 cursor-pointer"
                        , Html.Events.onClick (SetSimulationSpeed speed)
                        ]
                        [ div
                            [ class "square-12 rounded-full border-neon-green flex items-center justify-center"
                            ]
                            [ if isSelected then
                                div
                                    [ class "square-6 rounded-full bg-neon-green"
                                    ]
                                    []

                              else
                                text ""
                            ]
                        , text label
                        ]
            in
            div
                [ class "p-12 font-mono text-11 flex gap-16 text-green"
                ]
                [ div
                    [ class "flex flex-col gap-6"
                    ]
                    [ div [] [ text "Speed:" ]
                    , speedRadio Pause "0x"
                    , speedRadio Speed1x "1x"
                    , speedRadio Speed2x "2x"
                    , speedRadio Speed10x "10x"
                    , speedRadio Speed100x "100x"
                    ]
                , div
                    [ class "flex flex-col gap-10"
                    ]
                    [ div
                        [ class "flex flex-col gap-6"
                        ]
                        [ div [] [ text "Gold:" ]
                        , div
                            [ class "flex gap-4"
                            ]
                            [ Html.input
                                [ Html.Attributes.type_ "text"
                                , Html.Attributes.value model.goldInputValue
                                , Html.Attributes.placeholder "Amount"
                                , Html.Events.onInput GoldInputChanged
                                , class "w-80 p-4 bg-222 text-neon-green border-neon-1 rounded-sm"
                                , class "font-mono text-11"
                                ]
                                []
                            , div
                                [ class "py-4 px-8 bg-neon-green text-000 rounded-sm cursor-pointer font-bold text-10"
                                , Html.Events.onClick SetGoldFromInput
                                ]
                                [ text "SET" ]
                            ]
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
                [ class "p-12 font-mono text-11 flex flex-col gap-6 text-neon-green shrink-0"
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
                [ class "p-12 font-mono text-11 flex flex-col gap-6"
                , style "color" "#0f0"
                , style "flex-shrink" "0"
                , style "border-left" "1px solid #0f0"
                ]
                [ div
                    [ class "flex items-center gap-8 cursor-pointer"
                    , Html.Events.onClick ToggleBuildGrid
                    ]
                    [ div
                        [ class "square-14 border-2 border-neon rounded-sm"
                        , Html.Attributes.classList
                            [ ( "bg-neon", model.showBuildGrid ) ]
                        ]
                        []
                    , text "Build Grid"
                    ]
                , div
                    [ class "flex items-center gap-8 cursor-pointer"
                    , Html.Events.onClick TogglePathfindingGrid
                    ]
                    [ div
                        [ class "square-14 border-2 border-neon rounded-sm"
                        , Html.Attributes.classList
                            [ ( "bg-neon", model.showPathfindingGrid ) ]
                        ]
                        []
                    , text "Pathfinding Grid"
                    ]
                , div
                    [ class "flex items-center gap-8 cursor-pointer"
                    , Html.Events.onClick TogglePathfindingOccupancy
                    ]
                    [ div
                        [ class "square-14 border-2 border-neon rounded-sm"
                        , Html.Attributes.classList
                            [ ( "bg-neon", model.showPathfindingOccupancy ) ]
                        ]
                        []
                    , text "PF Occupancy"
                    ]
                , div
                    [ class "flex items-center gap-8 cursor-pointer"
                    , Html.Events.onClick ToggleBuildingOccupancy
                    ]
                    [ div
                        [ class "square-14 border-2 border-neon rounded-sm"
                        , Html.Attributes.classList
                            [ ( "bg-neon", model.showBuildingOccupancy ) ]
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
                [ class "flex flex-col items-center gap-4 p-8 rounded shrink-0 rel border-2"
                , Html.Attributes.classList
                    [ ("bg-333", canAfford)
                    , ("bg-222", not canAfford)
                    , ("border-dark", not canAfford)
                    , ("cursor-pointer", canAfford)
                    , ("cursor-not-allowed", not canAfford)
                    , ("opacity-50", not canAfford)
                    ]
                , clickHandler
                , on "mouseenter"
                    (D.map2 (\x y -> TooltipEnter ("building-" ++ template.name) x y)
                        (D.field "clientX" D.float)
                        (D.field "clientY" D.float)
                    )
                , Html.Events.onMouseLeave TooltipLeave
                ]
                [ div
                    [ class "text-12 text-fff font-bold"
                    ]
                    [ text template.name ]
                , div
                    [ class "text-10 text-muted"
                    ]
                    [ text sizeLabel ]
                , div
                    [ class "text-gold text-12 font-bold"
                    ]
                    [ text (String.fromInt template.cost ++ "g") ]
                , if isActive then
                    div
                        [ class "abs pe-none rounded bg-white-alpha-3"
                        , style "inset" "0"
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
                        [ class "flex gap-8 p-8"
                        ]
                        [ buildingOption castleTemplate ]

                Playing ->
                    -- Show all buildings except Castle
                    div
                        [ class "flex gap-8 p-8"
                        ]
                        [ buildingOption testBuildingTemplate
                        , buildingOption warriorsGuildTemplate
                        ]

                GameOver ->
                    -- Show nothing during game over
                    div
                        [ class "p-12 text-red font-mono text-14 font-bold"
                        ]
                        [ text "GAME OVER" ]

        noSelectionContent =
            div
                [ class "p-12 italic flex items-center text-14"
                , style "color" "#888"
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
                                [ class "py-6 px-12 cursor-pointer rounded-top text-10 font-bold select-none"
                                , style "background-color" (if model.buildingTab == tab then "#555" else "#333")
                                , Html.Events.onClick (SetBuildingTab tab)
                                ]
                                [ text label ]

                        tabContent =
                            case model.buildingTab of
                                MainTab ->
                                    div
                                        [ class "flex gap-16 items-start"
                                        ]
                                        [ -- Column 1: Name, HP, Owner
                                          div
                                            [ class "flex flex-col gap-4"
                                            ]
                                            [ div
                                                [ class "font-bold text-12"
                                                ]
                                                [ text (building.buildingType ++
                                                    (if building.behavior == UnderConstruction then
                                                        " (under construction)"
                                                     else
                                                        ""
                                                    ))
                                                ]
                                            , div
                                                [ class "text-9 text-muted flex gap-4"
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
                                            [ class "flex flex-col gap-4"
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
                                                            [ class "text-10 text-muted"
                                                            , style "padding-left" "8px"
                                                            ]
                                                            [ text ("  " ++ slot.unitType ++ ": " ++ String.fromInt slot.currentCount ++ "/" ++ String.fromInt slot.maxCount) ]
                                                    )
                                                    building.garrisonConfig
                                            )
                                        ]

                                InfoTab ->
                                    div
                                        [ class "flex gap-16 items-start"
                                        ]
                                        [ -- Column 1: Behavior, Timer, Coffer
                                          div
                                            [ class "flex flex-col gap-8"
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
                                                [ class "text-10 text-aaa"
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
                                            [ class "flex flex-col gap-4"
                                            ]
                                            (if not (List.isEmpty building.garrisonConfig) then
                                                [ div []
                                                    [ text "Garrison Cooldowns:" ]
                                                ]
                                                ++ List.map
                                                    (\slot ->
                                                        div
                                                            [ class "text-10 text-muted"
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
                        [ class "flex flex-col"
                        ]
                        [ -- Tab buttons
                          div
                            [ class "flex gap-4 pt-8 pr-8 pl-8 pb-0"
                            ]
                            [ tabButton "Main" MainTab
                            , tabButton "Info" InfoTab
                            ]
                        , -- Tab content
                          div
                            [ class "p-12 font-mono text-11"
                            , style "color" "#fff"
                            ]
                            [ tabContent ]
                        ]

                Nothing ->
                    div
                        [ class "p-12 text-red text-12"
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
                        [ class "p-12 font-mono text-11 flex gap-16 text-fff"
                        ]
                        [ -- Column 1: Name and HP
                          div
                            [ class "flex flex-col gap-4"
                            ]
                            [ div
                                [ class "font-bold text-12"
                                ]
                                [ text unit.unitType ]
                            , div
                                [ class "text-9 text-aaa flex gap-4"
                                ]
                                ([ text "[" ]
                                    ++ (unit.tags
                                            |> List.map
                                                (\tag ->
                                                    div
                                                        [ class "cursor-help"
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
                            [ class "flex flex-col gap-4"
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
                                [ class "cursor-help"
                                , on "mouseenter"
                                    (D.map2 (\x y -> TooltipEnter ("behavior-" ++ (case unit.behavior of
                                        Dead -> "Dead"
                                        DebugError msg -> "Error: " ++ msg
                                        WithoutHome -> "Without Home"
                                        LookingForTask -> "Looking for Task"
                                        GoingToSleep -> "Going to Sleep"
                                        Sleeping -> "Sleeping"
                                        LookForBuildRepairTarget -> "Looking for Build/Repair"
                                        MovingToBuildRepairTarget -> "Moving to Building"
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
                                    Dead -> "Dead"
                                    DebugError msg -> "Error: " ++ msg
                                    WithoutHome -> "Without Home"
                                    LookingForTask -> "Looking for Task"
                                    GoingToSleep -> "Going to Sleep"
                                    Sleeping -> "Sleeping"
                                    LookForBuildRepairTarget -> "Looking for Build/Repair"
                                    MovingToBuildRepairTarget -> "Moving to Building"
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
                        [ class "p-12 text-red text-12"
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
        [ class "panel abs bottom-20 right-224"
        , style "width" (String.fromFloat panelWidth ++ "px")
        , style "height" (String.fromInt panelHeight ++ "px")
        , style "overflow-x" "scroll"
        , style "overflow-y" "hidden"
        , style "-webkit-overflow-scrolling" "touch"
        , style "scrollbar-width" "auto"
        , style "scrollbar-color" "#888 #222"
        ]
        [ div
            [ class "flex items-start w-max"
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
