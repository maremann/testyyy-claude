module View.SelectionPanel exposing (viewSelectionPanel)
import BehaviorEngine.UnitStates as UnitStates
import BuildingTemplates exposing (castleTemplate, houseTemplate, testBuildingTemplate, warriorsGuildTemplate)
import GameStrings
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, placeholder, style, value)
import Html.Events exposing (on, onClick, onInput, onMouseLeave)
import Json.Decode as D
import Message exposing (Msg(..))
import Types exposing (..)


-- Helper Functions

formatCastleGuardBehavior : UnitStates.CastleGuardPatrolState -> String
formatCastleGuardBehavior state =
    let
        strategicStr = case state.currentStrategic of
            UnitStates.DefendTerritory -> "Defend Territory"
            UnitStates.WithoutHome -> "Without Home"

        tacticalStr = case state.currentTactical of
            Nothing -> "None"
            Just UnitStates.RestInGarrison -> "Rest in Garrison"
            Just UnitStates.PlanPatrolRoute -> "Plan Patrol"
            Just UnitStates.PatrolRoute -> "Patrolling"
            Just UnitStates.CircleBuilding -> "Circle Building"
            Just UnitStates.EngageMonster -> "Engage Monster"
            Just UnitStates.ResumePatrol -> "Resume Patrol"
            Just UnitStates.ReturnToCastle -> "Return to Castle"
            Just UnitStates.TacticalIdle -> "Idle"

        operationalStr = case state.currentOperational of
            Nothing -> "None"
            Just UnitStates.Sleep -> "Sleeping"
            Just UnitStates.SelectPatrolBuildings -> "Selecting Targets"
            Just UnitStates.GetCurrentPatrolTarget -> "Getting Target"
            Just UnitStates.MoveToBuilding -> "Moving"
            Just UnitStates.CirclePerimeter -> "Circling"
            Just UnitStates.IncrementPatrolIndex -> "Next Building"
            Just UnitStates.CheckCircleComplete -> "Checking Circle"
            Just UnitStates.FindCastle -> "Finding Castle"
            Just UnitStates.MoveToMonster -> "Moving to Monster"
            Just UnitStates.AttackMonster -> "Attacking"
            Just UnitStates.CheckMonsterDefeated -> "Checking Monster"
            Just UnitStates.ExitGarrison -> "Exiting Garrison"
            Just UnitStates.EnterGarrison -> "Entering Garrison"
            Just UnitStates.OperationalIdle -> "Idle"

        patrolInfo = if List.isEmpty state.patrolRoute then
                ""
            else
                " [" ++ String.fromInt (state.patrolIndex + 1) ++ "/" ++ String.fromInt (List.length state.patrolRoute) ++ "]"
    in
    strategicStr ++ " > " ++ tacticalStr ++ " > " ++ operationalStr ++ patrolInfo


viewSelectionPanel : Model -> Float -> Html Msg
viewSelectionPanel model panelWidth =
    let
        panelHeight = 120
        debugTabbedContent : Model -> Html Msg
        debugTabbedContent m =
            let
                tabButton tab label =
                    let
                        isActive = m.debugTab == tab
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
                tabsColumn = div
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
                        StatsTab -> debugStatsContent m
                        VisualizationTab -> debugVisualizationContent
                        ControlsTab -> debugControlsContent
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
                checkbox isChecked label onClick = div
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
                        isSelected = model.simulationSpeed == speed
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
        debugGridSection = div
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
                canAfford = model.gold >= template.cost
                isActive =
                    case model.buildMode of
                        Just activeTemplate -> activeTemplate.name == template.name
                        Nothing -> False
                sizeLabel =
                    case template.size of
                        Small -> "1×1"
                        Medium -> "2×2"
                        Large -> "3×3"
                        Huge -> "4×4"
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
                PreGame -> div
                        [ class "flex gap-8 p-8"
                        ]
                        [ buildingOption castleTemplate ]
                Playing -> div
                        [ class "flex gap-8 p-8"
                        ]
                        [ buildingOption testBuildingTemplate
                        , buildingOption warriorsGuildTemplate
                        ]
                GameOver -> div
                        [ class "p-12 text-red font-mono text-14 font-bold"
                        ]
                        [ text GameStrings.uiGameOver ]
        noSelectionContent = div
                [ class "p-12 italic flex items-center text-14"
                , style "color" "#888"
                , style "height" "100%"
                ]
                [ text "No selection" ]
        buildingSelectedContent buildingId =
            let
                maybeBuilding = List.filter (\b -> b.id == buildingId) model.buildings
                        |> List.head
            in
            case maybeBuilding of
                Just building ->
                    let
                        tagToString tag =
                            case tag of
                                BuildingTag -> GameStrings.tagBuilding
                                HeroTag -> GameStrings.tagHero
                                HenchmanTag -> GameStrings.tagHenchman
                                GuildTag -> GameStrings.tagGuild
                                ObjectiveTag -> GameStrings.tagObjective
                                CofferTag -> GameStrings.tagCoffer
                        tabButton label tab = div
                                [ class "py-6 px-12 cursor-pointer rounded-top text-10 font-bold select-none"
                                , style "background-color" (if model.buildingTab == tab then "#555" else "#333")
                                , Html.Events.onClick (SetBuildingTab tab)
                                ]
                                [ text label ]
                        tabContent =
                            case model.buildingTab of
                                MainTab -> div
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
                                                                (\tag -> div
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
                                                    Player -> GameStrings.ownerPlayer
                                                    Enemy -> GameStrings.ownerEnemy
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
                                                    (\slot -> div
                                                            [ class "text-10 text-muted"
                                                            , style "padding-left" "8px"
                                                            ]
                                                            [ text ("  " ++ slot.unitType ++ ": " ++ String.fromInt slot.currentCount ++ "/" ++ String.fromInt slot.maxCount) ]
                                                    )
                                                    building.garrisonConfig
                                            )
                                        ]
                                InfoTab -> div
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
                                                        Idle -> GameStrings.buildingBehaviorIdle
                                                        UnderConstruction -> GameStrings.buildingBehaviorUnderConstruction
                                                        GenerateGold -> GameStrings.buildingBehaviorGenerateGold
                                                        BuildingDead -> GameStrings.unitBehaviorDead
                                                        BuildingDebugError msg -> "Error: " ++ msg
                                                        )) x y)
                                                        (D.field "clientX" D.float)
                                                        (D.field "clientY" D.float)
                                                    )
                                                , Html.Events.onMouseLeave TooltipLeave
                                                ]
                                                [ text ("Behavior: " ++ (case building.behavior of
                                                    Idle -> GameStrings.buildingBehaviorIdle
                                                    UnderConstruction -> GameStrings.buildingBehaviorUnderConstruction
                                                    GenerateGold -> GameStrings.buildingBehaviorGenerateGold
                                                    BuildingDead -> GameStrings.unitBehaviorDead
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
                                                    (\slot -> div
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
                Nothing -> div
                        [ class "p-12 text-red text-12"
                        ]
                        [ text "Building not found" ]
        unitSelectedContent unitId =
            let
                maybeUnit = List.filter (\u -> u.id == unitId) model.units
                        |> List.head
            in
            case maybeUnit of
                Just unit ->
                    let
                        tagToString tag =
                            case tag of
                                BuildingTag -> GameStrings.tagBuilding
                                HeroTag -> GameStrings.tagHero
                                HenchmanTag -> GameStrings.tagHenchman
                                GuildTag -> GameStrings.tagGuild
                                ObjectiveTag -> GameStrings.tagObjective
                                CofferTag -> GameStrings.tagCoffer
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
                                [ text (unit.unitType ++ " #" ++ String.fromInt unit.id) ]
                            , div
                                [ class "text-9 text-aaa flex gap-4"
                                ]
                                ([ text "[" ]
                                    ++ (unit.tags
                                            |> List.map
                                                (\tag -> div
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
                                    Player -> GameStrings.ownerPlayer
                                    Enemy -> GameStrings.ownerEnemy
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
                                        Dead -> GameStrings.unitBehaviorDead
                                        DebugError msg -> "Error: " ++ msg
                                        WithoutHome -> GameStrings.unitBehaviorWithoutHome
                                        LookingForTask -> GameStrings.unitBehaviorLookingForTask
                                        GoingToSleep -> GameStrings.unitBehaviorGoingToSleep
                                        Sleeping -> GameStrings.unitBehaviorSleeping
                                        LookForBuildRepairTarget -> GameStrings.unitBehaviorLookingForBuildRepair
                                        MovingToBuildRepairTarget -> GameStrings.unitBehaviorMovingToBuilding
                                        Repairing -> GameStrings.unitBehaviorRepairing
                                        LookForTaxTarget -> GameStrings.unitBehaviorLookingForTaxTarget
                                        CollectingTaxes -> GameStrings.unitBehaviorCollectingTaxes
                                        ReturnToCastle -> GameStrings.unitBehaviorReturningToCastle
                                        DeliveringGold -> GameStrings.unitBehaviorDeliveringGold
                                        CastleGuardPatrol state -> formatCastleGuardBehavior state
                                        )) x y)
                                        (D.field "clientX" D.float)
                                        (D.field "clientY" D.float)
                                    )
                                , Html.Events.onMouseLeave TooltipLeave
                                ]
                                [ text ("Behavior: " ++ (case unit.behavior of
                                    Dead -> GameStrings.unitBehaviorDead
                                    DebugError msg -> "Error: " ++ msg
                                    WithoutHome -> GameStrings.unitBehaviorWithoutHome
                                    LookingForTask -> GameStrings.unitBehaviorLookingForTask
                                    GoingToSleep -> GameStrings.unitBehaviorGoingToSleep
                                    Sleeping -> GameStrings.unitBehaviorSleeping
                                    LookForBuildRepairTarget -> GameStrings.unitBehaviorLookingForBuildRepair
                                    MovingToBuildRepairTarget -> GameStrings.unitBehaviorMovingToBuilding
                                    Repairing -> GameStrings.unitBehaviorRepairing
                                    LookForTaxTarget -> GameStrings.unitBehaviorLookingForTaxTarget
                                    CollectingTaxes -> GameStrings.unitBehaviorCollectingTaxes
                                    ReturnToCastle -> GameStrings.unitBehaviorReturningToCastle
                                    DeliveringGold -> GameStrings.unitBehaviorDeliveringGold
                                    CastleGuardPatrol state -> formatCastleGuardBehavior state
                                    ))
                                ]
                            ]
                        ]
                Nothing -> div
                        [ class "p-12 text-red text-12"
                        ]
                        [ text "Unit not found" ]
        content =
            case model.selected of
                Nothing -> [ noSelectionContent ]
                Just GlobalButtonDebug -> [ debugTabbedContent model ]
                Just GlobalButtonBuild -> [ buildContent ]
                Just (BuildingSelected buildingId) -> [ buildingSelectedContent buildingId ]
                Just (UnitSelected unitId) -> [ unitSelectedContent unitId ]
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
