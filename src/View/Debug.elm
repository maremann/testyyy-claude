module View.Debug exposing
    ( viewBuildingOccupancy
    , viewCityActiveArea
    , viewCitySearchArea
    , viewGrids
    , viewPathfindingOccupancy
    , viewUnitRadii
    )

import Dict
import Grid exposing (getCityActiveArea, getCitySearchArea, isPathfindingCellOccupied)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Message exposing (Msg(..))
import Types exposing (..)


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


