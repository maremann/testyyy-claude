module View.Viewport exposing
    ( viewBuildingPreview
    , viewBuildings
    , viewDecorativeShapes
    , viewMainViewport
    , viewSelectedUnitPath
    , viewTerrain
    , viewUnits
    )
import Grid exposing (getBuildingEntrance, isValidBuildingPlacement)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (on)
import Json.Decode as D
import Message exposing (Msg(..))
import Types exposing (..)
viewMainViewport : Model -> String -> Float -> Float -> Html Msg
viewMainViewport model cursor viewportWidth viewportHeight =
    let
        handleMouseDown =
            case model.buildMode of
                Just _ -> on "mousedown" (D.succeed PlaceBuilding)
                Nothing ->
                    on "mousedown" (D.map2 MouseDown (D.field "clientX" D.float) (D.field "clientY" D.float))
        handleMouseMove =
            case model.buildMode of
                Just _ -> on "mousemove"
                        (D.map2
                            (\clientX clientY ->
                                let
                                    worldX = model.camera.x + clientX
                                    worldY = model.camera.y + clientY
                                in
                                WorldMouseMove worldX worldY
                            )
                            (D.field "clientX" D.float)
                            (D.field "clientY" D.float)
                        )
                Nothing -> Html.Attributes.class ""
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
        , viewBuildingPreview model
        ]
viewTerrain : Model -> Float -> Float -> Html Msg
viewTerrain model viewportWidth viewportHeight =
    let
        terrainLeft = 0 - model.camera.x
        terrainTop = 0 - model.camera.y
        terrainWidth = model.mapConfig.width
        terrainHeight = model.mapConfig.height
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
viewDecorativeShapes model viewportWidth viewportHeight = div []
        (List.map (viewShape model) model.decorativeShapes)
viewShape : Model -> DecorativeShape -> Html Msg
viewShape model shape =
    let
        screenX = shape.x - model.camera.x
        screenY = shape.y - model.camera.y
        ( shapeStyle, shapeRadius ) =
            case shape.shapeType of
                Circle -> ( [ class "rounded-full" ], shape.size / 2 )
                Rectangle -> ( [], 0 )
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
viewBuildings model = div []
        (List.map (viewBuilding model) model.buildings)
viewBuilding : Model -> Building -> Html Msg
viewBuilding model building =
    let
        worldX = toFloat building.gridX * model.gridConfig.buildGridSize
        worldY = toFloat building.gridY * model.gridConfig.buildGridSize
        screenX = worldX - model.camera.x
        screenY = worldY - model.camera.y
        sizeCells = buildingSizeToGridCells building.size
        buildingSizePx = toFloat sizeCells * model.gridConfig.buildGridSize
        buildingColor =
            case building.buildingType of
                "Test Building" -> "#8B4513"
                _ -> "#666"
        isSelected =
            case model.selected of
                Just (BuildingSelected id) -> id == building.id
                _ -> False
        ( entranceGridX, entranceGridY ) = getBuildingEntrance building
        entranceOffsetX =
            toFloat (entranceGridX - building.gridX) * model.gridConfig.buildGridSize
        entranceOffsetY =
            toFloat (entranceGridY - building.gridY) * model.gridConfig.buildGridSize
        entranceTileSize = model.gridConfig.buildGridSize
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
            healthPercent = toFloat building.hp / toFloat building.maxHp
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
viewUnits model = div []
        (List.filterMap
            (\unit ->
                case unit.location of
                    OnMap x y -> Just (viewUnit model unit x y)
                    Garrisoned _ -> Nothing
            )
            model.units
        )
viewUnit : Model -> Unit -> Float -> Float -> Html Msg
viewUnit model unit worldX worldY =
    let
        screenX = worldX - model.camera.x
        screenY = worldY - model.camera.y
        visualDiameter = model.gridConfig.pathfindingGridSize / 2
        visualRadius = visualDiameter / 2
        selectionDiameter = visualDiameter * 2
        selectionRadius = selectionDiameter / 2
        isSelected =
            case model.selected of
                Just (UnitSelected id) -> id == unit.id
                _ -> False
    in
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
            healthPercent = toFloat unit.hp / toFloat unit.maxHp
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
                maybeUnit = List.filter (\u -> u.id == unitId) model.units
                        |> List.head
            in
            case maybeUnit of
                Just unit -> div []
                        (List.map
                            (\( cellX, cellY ) ->
                                let
                                    worldX =
                                        toFloat cellX * model.gridConfig.pathfindingGridSize + model.gridConfig.pathfindingGridSize / 2
                                    worldY =
                                        toFloat cellY * model.gridConfig.pathfindingGridSize + model.gridConfig.pathfindingGridSize / 2
                                    screenX = worldX - model.camera.x
                                    screenY = worldY - model.camera.y
                                    dotSize = 6
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
                Nothing -> text ""
        _ -> text ""
viewBuildingPreview : Model -> Html Msg
viewBuildingPreview model =
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
                        && model.gold >= template.cost
                worldPosX = toFloat centeredGridX * model.gridConfig.buildGridSize
                worldPosY = toFloat centeredGridY * model.gridConfig.buildGridSize
                screenX = worldPosX - model.camera.x
                screenY = worldPosY - model.camera.y
                buildingSizePx = toFloat sizeCells * model.gridConfig.buildGridSize
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
        _ -> div [] []
