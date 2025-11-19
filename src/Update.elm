module Update exposing (update, subscriptions, init, generateShapes)

import Browser.Dom as Dom
import Browser.Events as E
import BuildingBehavior exposing (updateBuildingBehavior)
import BuildingTemplates exposing (castleTemplate, houseTemplate, randomUnitColor, warriorsGuildTemplate)
import Dict
import GameHelpers exposing (createHenchman, randomNearbyCell, recalculateAllPaths, updateUnitMovement)
import Grid exposing (..)
import Json.Decode as D
import Message exposing (Msg(..))
import Pathfinding exposing (calculateUnitPath, findPath)
import Random
import Task
import Types exposing (..)
import UnitBehavior exposing (updateGarrisonSpawning, updateUnitBehavior)


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
                            -- Check if this is Castle (builds immediately) or construction site
                            isCastle =
                                template.name == "Castle"

                            -- Determine building-specific properties
                            ( buildingBehavior, buildingTags ) =
                                if isCastle then
                                    ( SpawnHouse, [ BuildingTag, ObjectiveTag ] )

                                else
                                    -- All other buildings start as construction sites
                                    ( UnderConstruction, [ BuildingTag ] )

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
                                if isCastle then
                                    [ { unitType = "Castle Guard", maxCount = 2, currentCount = 1, spawnTimer = 0 }
                                    , { unitType = "Tax Collector", maxCount = 1, currentCount = 1, spawnTimer = 0 }
                                    , { unitType = "Peasant", maxCount = 3, currentCount = 1, spawnTimer = 0 }
                                    ]

                                else
                                    []

                            -- Calculate initial HP (10% for construction sites, 100% for Castle)
                            initialHp =
                                if isCastle then
                                    template.maxHp

                                else
                                    max 1 (template.maxHp // 10)

                            -- Calculate initial garrison occupied count
                            initialGarrisonOccupied =
                                List.foldl (\slot acc -> acc + slot.currentCount) 0 initialGarrisonConfig

                            newBuilding =
                                { id = model.nextBuildingId
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

                            -- Create initial garrison units for Castle
                            ( initialUnits, nextUnitIdAfterInitial ) =
                                if isCastle then
                                    let
                                        unitsToCreate =
                                            [ ( "Castle Guard", model.nextUnitId )
                                            , ( "Tax Collector", model.nextUnitId + 1 )
                                            , ( "Peasant", model.nextUnitId + 2 )
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

                            -- Recalculate paths for all units due to occupancy change
                            updatedUnits =
                                recalculateAllPaths model.gridConfig model.mapConfig newPathfindingOccupancy (model.units ++ initialUnits)

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


        SetDebugTab tab ->
            ( { model | debugTab = tab }, Cmd.none )

        SetBuildingTab tab ->
            ( { model | buildingTab = tab }, Cmd.none )

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
                                                updateUnitBehavior deltaSeconds model.buildings unit

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
                                        let
                                            -- Update behavior state for garrisoned units too
                                            ( behaviorUpdatedUnit, shouldGeneratePath ) =
                                                updateUnitBehavior deltaSeconds model.buildings unit

                                            -- Collect units that need path generation (if they exited garrison)
                                            needsPath =
                                                if shouldGeneratePath then
                                                    behaviorUpdatedUnit :: accNeedingPaths

                                                else
                                                    accNeedingPaths
                                        in
                                        ( behaviorUpdatedUnit :: accUnits, accOccupancy, needsPath )
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

                    -- Apply building repairs from Peasants
                    buildingsAfterRepairs =
                        List.map
                            (\building ->
                                let
                                    -- Find all peasants repairing this building
                                    repairingPeasants =
                                        List.filter
                                            (\unit ->
                                                case ( unit.behavior, unit.location ) of
                                                    ( Repairing, OnMap x y ) ->
                                                        let
                                                            buildGridSize =
                                                                64

                                                            buildingMinX =
                                                                toFloat building.gridX * toFloat buildGridSize

                                                            buildingMinY =
                                                                toFloat building.gridY * toFloat buildGridSize

                                                            buildingSize =
                                                                toFloat (buildingSizeToGridCells building.size) * toFloat buildGridSize

                                                            buildingMaxX =
                                                                buildingMinX + buildingSize

                                                            buildingMaxY =
                                                                buildingMinY + buildingSize

                                                            isNear =
                                                                (x >= buildingMinX - 48 && x <= buildingMaxX + 48)
                                                                    && (y >= buildingMinY - 48 && y <= buildingMaxY + 48)

                                                            canBuild =
                                                                unit.behaviorTimer >= 0.15
                                                        in
                                                        isNear && canBuild && building.hp < building.maxHp

                                                    _ ->
                                                        False
                                            )
                                            unitsAfterHouseSpawn

                                    -- Each peasant adds 5 HP
                                    hpGain =
                                        List.length repairingPeasants * 5

                                    newHp =
                                        min building.maxHp (building.hp + hpGain)

                                    -- Check if construction is complete
                                    isConstructionComplete =
                                        building.behavior == UnderConstruction && newHp >= building.maxHp

                                    -- Determine completed building properties based on building type
                                    ( completedBehavior, completedTags, completedDuration ) =
                                        if isConstructionComplete then
                                            case building.buildingType of
                                                "Warrior's Guild" ->
                                                    ( GenerateGold
                                                    , [ BuildingTag, GuildTag, CofferTag ]
                                                    , 15.0 + toFloat (modBy 30000 (building.id * 1000)) / 1000.0
                                                    )

                                                "House" ->
                                                    ( GenerateGold
                                                    , [ BuildingTag, CofferTag ]
                                                    , 15.0 + toFloat (modBy 30000 (building.id * 1000)) / 1000.0
                                                    )

                                                _ ->
                                                    -- Default: keep as-is (shouldn't happen)
                                                    ( building.behavior, building.tags, building.behaviorDuration )

                                        else
                                            ( building.behavior, building.tags, building.behaviorDuration )
                                in
                                { building
                                    | hp = newHp
                                    , behavior = completedBehavior
                                    , tags = completedTags
                                    , behaviorDuration = completedDuration
                                    , behaviorTimer = 0
                                }
                            )
                            buildingsAfterHouseSpawn

                    -- Check for Game Over (Castle destroyed)
                    newGameState =
                        if List.any (\b -> List.member ObjectiveTag b.tags && b.hp <= 0) buildingsAfterRepairs then
                            GameOver
                        else
                            model.gameState

                    -- Calculate paths for units that requested them
                    unitsWithPaths =
                        List.map
                            (\unit ->
                                case ( unit.location, unit.targetDestination ) of
                                    ( OnMap x y, Just targetCell ) ->
                                        let
                                            newPath =
                                                calculateUnitPath model.gridConfig model.mapConfig pathfindingOccupancyAfterHouses x y targetCell
                                        in
                                        { unit | path = newPath }

                                    _ ->
                                        unit
                            )
                            unitsAfterHouseSpawn
                in
                ( { model
                    | accumulatedTime = remainingTime
                    , simulationFrameCount = model.simulationFrameCount + 1
                    , lastSimulationDeltas = newSimulationDeltas
                    , units = unitsWithPaths
                    , buildings = buildingsAfterRepairs
                    , buildingOccupancy = buildingOccupancyAfterHouses
                    , pathfindingOccupancy = pathfindingOccupancyAfterHouses
                    , tooltipHover = updatedTooltipHover
                    , nextUnitId = nextUnitIdAfterSpawning
                    , nextBuildingId = nextBuildingIdAfterHouses
                    , gameState = newGameState
                  }
                , Cmd.none
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
