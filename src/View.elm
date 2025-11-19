module View exposing (view)
import BuildingTemplates exposing (castleTemplate, houseTemplate, testBuildingTemplate, warriorsGuildTemplate)
import Dict
import GameStrings
import Grid exposing (getBuildingEntrance, getCityActiveArea, getCitySearchArea, isPathfindingCellOccupied, isValidBuildingPlacement)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style, placeholder, value)
import Html.Events exposing (on, onClick, onInput, onMouseLeave, stopPropagationOn)
import Json.Decode as D
import Message exposing (Msg(..))
import Types exposing (..)
import View.Debug exposing (viewBuildingOccupancy, viewCityActiveArea, viewCitySearchArea, viewGrids, viewPathfindingOccupancy, viewUnitRadii)
import View.SelectionPanel exposing (viewSelectionPanel)
import View.Viewport exposing (viewBuildingPreview, viewBuildings, viewDecorativeShapes, viewMainViewport, viewSelectedUnitPath, viewTerrain, viewUnits)
view : Model -> Html Msg
view model =
    let
        ( winWidth, winHeight ) = model.windowSize
        aspectRatio = 4 / 3
        viewportWidth = toFloat winWidth
        viewportHeight = toFloat winHeight
        cursor =
            case model.dragState of
                DraggingViewport _ -> "grabbing"
                DraggingMinimap _ -> "grabbing"
                NotDragging -> "grab"
        minimapWidth = 204
        minimapMargin = 20
        globalButtonsWidth = 120
        globalButtonsBorder = 4
        globalButtonsMargin = 20
        panelGap = 10
        selectionPanelBorder = 4
        selectionPanelMinWidth = 100
        selectionPanelMaxWidth = 700
        initialAvailableWidth =
            toFloat winWidth - toFloat (minimapWidth + minimapMargin) - toFloat selectionPanelBorder
        trialSelectionPanelWidth =
            clamp (toFloat selectionPanelMinWidth) (toFloat selectionPanelMaxWidth) initialAvailableWidth
        totalPanelsWidth =
            globalButtonsWidth + globalButtonsBorder + panelGap + round trialSelectionPanelWidth + selectionPanelBorder
        canStickToPanel =
            totalPanelsWidth <= (winWidth - minimapWidth - minimapMargin - globalButtonsMargin)
        selectionPanelWidth =
            if canStickToPanel then
                trialSelectionPanelWidth
            else
                let
                    reducedAvailableWidth =
                        toFloat winWidth - toFloat (minimapWidth + minimapMargin + selectionPanelBorder + panelGap + globalButtonsWidth + globalButtonsBorder + globalButtonsMargin + panelGap)
                in
                clamp (toFloat selectionPanelMinWidth) (toFloat selectionPanelMaxWidth) reducedAvailableWidth
        globalButtonsLeft =
            if canStickToPanel then
                toFloat winWidth - toFloat (minimapWidth + minimapMargin) - selectionPanelWidth - toFloat selectionPanelBorder - toFloat panelGap - toFloat globalButtonsWidth - toFloat globalButtonsBorder
            else
                toFloat globalButtonsMargin
    in
    div
        [ class "root-container"
        ]
        [ viewMainViewport model cursor viewportWidth viewportHeight
        , viewGrids model viewportWidth viewportHeight
        , viewPathfindingOccupancy model viewportWidth viewportHeight
        , viewBuildingOccupancy model viewportWidth viewportHeight
        , viewCitySearchArea model viewportWidth viewportHeight
        , viewCityActiveArea model viewportWidth viewportHeight
        , viewUnitRadii model
        , viewGoldCounter model
        , viewGlobalButtonsPanel model globalButtonsLeft
        , viewSelectionPanel model selectionPanelWidth
        , viewMinimap model
        , viewTooltip model
        , viewPreGameOverlay model
        , viewGameOverOverlay model
        ]
viewGlobalButtonsPanel : Model -> Float -> Html Msg
viewGlobalButtonsPanel model leftPosition =
    let
        panelSize = 120
        button label selectable isSelected = div
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
        [ button GameStrings.uiDebug GlobalButtonDebug (model.selected == Just GlobalButtonDebug)
        , button GameStrings.uiBuild GlobalButtonBuild (model.selected == Just GlobalButtonBuild)
        ]
viewGoldCounter : Model -> Html Msg
viewGoldCounter model =
    let
        isPaused = model.simulationSpeed == Pause
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
                [ text GameStrings.uiPaused ]
          else
            text ""
        ]
viewMinimap : Model -> Html Msg
viewMinimap model =
    let
        minimapWidth = 200
        minimapHeight = 150
        padding = 10
        scale =
            min ((toFloat minimapWidth - padding * 2) / model.mapConfig.width) ((toFloat minimapHeight - padding * 2) / model.mapConfig.height)
        ( winWidth, winHeight ) = model.windowSize
        viewportIndicatorX = padding + (model.camera.x * scale)
        viewportIndicatorY = padding + (model.camera.y * scale)
        viewportIndicatorWidth = toFloat winWidth * scale
        viewportIndicatorHeight = toFloat winHeight * scale
        cursor =
            case model.dragState of
                DraggingViewport _ -> "grabbing"
                DraggingMinimap _ -> "grabbing"
                NotDragging -> "grab"
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
        worldX = toFloat building.gridX * buildGridSize
        worldY = toFloat building.gridY * buildGridSize
        buildingSizeCells = buildingSizeToGridCells building.size
        worldWidth = toFloat buildingSizeCells * buildGridSize
        worldHeight = toFloat buildingSizeCells * buildGridSize
        minimapX = worldX * scale
        minimapY = worldY * scale
        minimapWidth = worldWidth * scale
        minimapHeight = worldHeight * scale
        buildingColor =
            case building.owner of
                Player -> "#7FFFD4"
                Enemy -> "#FF0000"
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
                minimapX = worldX * scale
                minimapY = worldY * scale
                dotSize = 3
                unitColor =
                    case unit.owner of
                        Player -> "#7FFFD4"
                        Enemy -> "#FF0000"
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
        Garrisoned _ -> text ""
viewTooltip : Model -> Html Msg
viewTooltip model =
    case model.tooltipHover of
        Just tooltipState ->
            if tooltipState.hoverTime >= 500 then
                case tooltipState.elementId of
                    "building-Test Building" -> div
                            [ class "tooltip pe-none py-8 px-12"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 100) ++ "px")
                            ]
                            [ div [ class "font-bold", style "margin-bottom" "4px" ] [ text GameStrings.buildingTypeTestBuilding ]
                            , div [ class "text-muted" ] [ text ("HP: " ++ String.fromInt testBuildingTemplate.maxHp) ]
                            , div [ class "text-muted" ] [ text ("Size: 2×2") ]
                            , div [ class "text-muted" ] [ text ("Garrison: " ++ String.fromInt testBuildingTemplate.garrisonSlots) ]
                            ]
                    "building-Castle" -> div
                            [ class "tooltip pe-none py-8 px-12"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 120) ++ "px")
                            ]
                            [ div [ class "font-bold", style "margin-bottom" "4px" ] [ text GameStrings.buildingTypeCastle ]
                            , div [ class "text-muted" ] [ text ("HP: " ++ String.fromInt castleTemplate.maxHp) ]
                            , div [ class "text-muted" ] [ text "Size: 4×4" ]
                            , div [ class "text-muted" ] [ text ("Garrison: " ++ String.fromInt castleTemplate.garrisonSlots ++ " henchmen") ]
                            , div [ class "text-gold", style "margin-top" "4px" ] [ text "Mission-critical building" ]
                            ]
                    "building-House" -> div
                            [ class "tooltip pe-none py-8 px-12"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 100) ++ "px")
                            ]
                            [ div [ class "font-bold", style "margin-bottom" "4px" ] [ text GameStrings.buildingTypeHouse ]
                            , div [ class "text-muted" ] [ text ("HP: " ++ String.fromInt houseTemplate.maxHp) ]
                            , div [ class "text-muted" ] [ text "Size: 2×2" ]
                            , div [ class "text-gold", style "margin-top" "4px" ] [ text "Generates gold" ]
                            ]
                    "building-Warrior's Guild" -> div
                            [ class "tooltip pe-none py-8 px-12"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 100) ++ "px")
                            ]
                            [ div [ class "font-bold", style "margin-bottom" "4px" ] [ text GameStrings.buildingTypeWarriorsGuild ]
                            , div [ class "text-muted" ] [ text ("HP: " ++ String.fromInt warriorsGuildTemplate.maxHp) ]
                            , div [ class "text-muted" ] [ text "Size: 3×3" ]
                            , div [ class "text-gold", style "margin-top" "4px" ] [ text "Trains warriors, generates gold" ]
                            ]
                    "tag-Building" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "This is a building" ]
                    "tag-Hero" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "This is a hero" ]
                    "tag-Henchman" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "This is a henchman" ]
                    "tag-Guild" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "This building produces and houses Heroes" ]
                    "tag-Objective" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "If this dies, the player loses the game" ]
                    "tag-Coffer" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "This building has a Gold Coffer" ]
                    "behavior-Idle" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The building is not performing any actions" ]
                    "behavior-Under Construction" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The building is under construction" ]
                    "behavior-Spawn House" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The Castle is periodically spawning Houses for the kingdom" ]
                    "behavior-Generate Gold" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The building is generating gold into its coffer" ]
                    "behavior-Thinking" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The unit is pausing before deciding on next action" ]
                    "behavior-Finding Target" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The unit is calculating a path to a random destination" ]
                    "behavior-Moving" -> div
                            [ class "tooltip pe-none"
                            , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                            , style "top" (String.fromFloat (tooltipState.mouseY - 50) ++ "px")
                            ]
                            [ text "The unit is following its path to the destination" ]
                    _ ->
                        if String.startsWith "garrison-" tooltipState.elementId then
                            let
                                buildingIdStr = String.dropLeft 9 tooltipState.elementId
                                maybeBuildingId = String.toInt buildingIdStr
                                maybeBuilding =
                                    case maybeBuildingId of
                                        Just buildingId -> List.filter (\b -> b.id == buildingId) model.buildings
                                                |> List.head
                                        Nothing -> Nothing
                            in
                            case maybeBuilding of
                                Just building -> div
                                        [ class "tooltip pe-none py-8 px-12"
                                        , style "left" (String.fromFloat tooltipState.mouseX ++ "px")
                                        , style "top" (String.fromFloat (tooltipState.mouseY - 80) ++ "px")
                                        ]
                                        [ div [ class "font-bold", style "margin-bottom" "4px" ] [ text "Garrison" ]
                                        , div [ class "text-muted" ] [ text ("Current: " ++ String.fromInt building.garrisonOccupied) ]
                                        , div [ class "text-muted" ] [ text ("Capacity: " ++ String.fromInt building.garrisonSlots) ]
                                        , div [ class "text-muted" ] [ text "Next unit: Not implemented" ]
                                        ]
                                Nothing -> text ""
                        else
                            text ""
            else
                text ""
        Nothing -> text ""
viewPreGameOverlay : Model -> Html Msg
viewPreGameOverlay model =
    case model.gameState of
        PreGame -> div
                [ class "panel font-mono font-bold text-gold pe-none fix right-20 border-gold py-16 px-24 border-gold-3 text-18"
                , style "top" "20px"
                , style "z-index" "1000"
                ]
                [ text GameStrings.uiSiteYourCastle ]
        _ -> text ""
viewGameOverOverlay : Model -> Html Msg
viewGameOverOverlay model =
    case model.gameState of
        GameOver -> div
                [ class "overlay pe-none bg-black-alpha-9"
                ]
                [ div
                    [ class "font-mono font-bold text-red text-64"
                    ]
                    [ text GameStrings.uiGameOver ]
                ]
        _ -> text ""
decodeMinimapMouseEvent : (Float -> Float -> Msg) -> D.Decoder ( Msg, Bool )
decodeMinimapMouseEvent msg = D.map2 (\x y -> ( msg x y, True ))
        (D.field "clientX" D.float)
        (D.field "clientY" D.float)
