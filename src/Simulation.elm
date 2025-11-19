module Simulation exposing (simulationTick)
import BuildingBehavior exposing (updateBuildingBehavior)
import Dict
import GameHelpers exposing (createHenchman, recalculateAllPaths, updateUnitMovement)
import Grid exposing (addBuildingGridOccupancy, addBuildingOccupancy, addUnitOccupancy, findAdjacentHouseLocation, removeUnitOccupancy)
import Pathfinding exposing (calculateUnitPath)
import Types exposing (..)
import UnitBehavior exposing (updateGarrisonSpawning, updateUnitBehavior)
simulationTick : Float -> Model -> Model
simulationTick delta model =
    let
        updatedTooltipHover =
            case model.tooltipHover of
                Just tooltipState ->
                    Just { tooltipState | hoverTime = tooltipState.hoverTime + delta }
                Nothing -> Nothing
        isPaused = delta > 1000 || model.simulationSpeed == Pause
        speedMultiplier =
            case model.simulationSpeed of
                Pause -> 0
                Speed1x -> 1
                Speed2x -> 2
                Speed10x -> 10
                Speed100x -> 100
        newAccumulatedTime =
            if isPaused then
                model.accumulatedTime
            else
                model.accumulatedTime + (delta * toFloat speedMultiplier)
        simulationTimestep = 50.0
        shouldSimulate = newAccumulatedTime >= simulationTimestep && not isPaused
    in
    if shouldSimulate then
        let
            newSimulationDeltas = (newAccumulatedTime :: model.lastSimulationDeltas)
                    |> List.take 3
            remainingTime = newAccumulatedTime - simulationTimestep
            deltaSeconds = simulationTimestep / 1000.0
            ( updatedUnits, updatedOccupancy, unitsNeedingPaths ) = List.foldl
                    (\unit ( accUnits, accOccupancy, accNeedingPaths ) ->
                        case unit.location of
                            OnMap oldX oldY ->
                                let
                                    ( behaviorUpdatedUnit, shouldGeneratePath ) = updateUnitBehavior deltaSeconds model.buildings unit
                                    occupancyWithoutUnit = removeUnitOccupancy model.gridConfig oldX oldY accOccupancy
                                    movedUnit =
                                        updateUnitMovement model.gridConfig model.mapConfig occupancyWithoutUnit deltaSeconds behaviorUpdatedUnit
                                    newOccupancyForUnit =
                                        case movedUnit.location of
                                            OnMap newX newY ->
                                                addUnitOccupancy model.gridConfig newX newY occupancyWithoutUnit
                                            Garrisoned _ -> occupancyWithoutUnit
                                    needsPath =
                                        if shouldGeneratePath then
                                            movedUnit :: accNeedingPaths
                                        else
                                            accNeedingPaths
                                in
                                ( movedUnit :: accUnits, newOccupancyForUnit, needsPath )
                            Garrisoned _ ->
                                let
                                    ( behaviorUpdatedUnit, shouldGeneratePath ) = updateUnitBehavior deltaSeconds model.buildings unit
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
            ( updatedBuildings, buildingsNeedingHouseSpawn, henchmenToSpawn ) = List.foldl
                    (\building ( accBuildings, accNeedingHouseSpawn, accHenchmenSpawn ) ->
                        let
                            ( behaviorUpdatedBuilding, shouldSpawnHouse ) = updateBuildingBehavior deltaSeconds building
                            ( garrisonUpdatedBuilding, unitsToSpawn ) = updateGarrisonSpawning deltaSeconds behaviorUpdatedBuilding
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
            ( newHenchmen, nextUnitIdAfterSpawning ) = List.foldl
                    (\( unitType, buildingId ) ( accUnits, currentUnitId ) ->
                        case List.filter (\b -> b.id == buildingId) updatedBuildings |> List.head of
                            Just homeBuilding ->
                                let
                                    newUnit =
                                        createHenchman unitType currentUnitId buildingId homeBuilding
                                in
                                ( newUnit :: accUnits, currentUnitId + 1 )
                            Nothing -> ( accUnits, currentUnitId )
                    )
                    ( [], model.nextUnitId )
                    henchmenToSpawn
            allUnits = updatedUnits ++ newHenchmen
            ( ( buildingsAfterHouseSpawn, buildingOccupancyAfterHouses ), ( pathfindingOccupancyAfterHouses, nextBuildingIdAfterHouses ) ) = List.foldl
                    (\castleBuilding ( ( accBuildings, accBuildOcc ), ( accPfOcc, currentBuildingId ) ) ->
                        case findAdjacentHouseLocation model.mapConfig model.gridConfig accBuildings accBuildOcc of
                            Just ( gridX, gridY ) ->
                                let
                                    newHouse = { id = currentBuildingId
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
                                    newBuildOcc = addBuildingGridOccupancy newHouse accBuildOcc
                                    newPfOcc = addBuildingOccupancy model.gridConfig newHouse accPfOcc
                                in
                                ( ( newHouse :: accBuildings, newBuildOcc ), ( newPfOcc, currentBuildingId + 1 ) )
                            Nothing ->
                                ( ( accBuildings, accBuildOcc ), ( accPfOcc, currentBuildingId ) )
                    )
                    ( ( updatedBuildings, model.buildingOccupancy ), ( updatedOccupancy, model.nextBuildingId ) )
                    buildingsNeedingHouseSpawn
            unitsAfterHouseSpawn =
                if List.isEmpty buildingsNeedingHouseSpawn then
                    allUnits
                else
                    recalculateAllPaths model.gridConfig model.mapConfig pathfindingOccupancyAfterHouses allUnits
            buildingsAfterRepairs = List.map
                    (\building ->
                        let
                            repairingPeasants = List.filter
                                    (\unit ->
                                        case ( unit.behavior, unit.location ) of
                                            ( Repairing, OnMap x y ) ->
                                                let
                                                    buildGridSize = 64
                                                    buildingMinX = toFloat building.gridX * toFloat buildGridSize
                                                    buildingMinY = toFloat building.gridY * toFloat buildGridSize
                                                    buildingSize =
                                                        toFloat (buildingSizeToGridCells building.size) * toFloat buildGridSize
                                                    buildingMaxX = buildingMinX + buildingSize
                                                    buildingMaxY = buildingMinY + buildingSize
                                                    isNear = (x >= buildingMinX - 48 && x <= buildingMaxX + 48)
                                                            && (y >= buildingMinY - 48 && y <= buildingMaxY + 48)
                                                    canBuild = unit.behaviorTimer >= 0.15
                                                in
                                                isNear && canBuild && building.hp < building.maxHp
                                            _ -> False
                                    )
                                    unitsAfterHouseSpawn
                            hpGain = List.length repairingPeasants * 5
                            newHp = min building.maxHp (building.hp + hpGain)
                            isConstructionComplete =
                                building.behavior == UnderConstruction && newHp >= building.maxHp
                            ( completedBehavior, completedTags, completedDuration ) =
                                if isConstructionComplete then
                                    case building.buildingType of
                                        "Warrior's Guild" -> ( GenerateGold
                                            , [ BuildingTag, GuildTag, CofferTag ]
                                            , 15.0 + toFloat (modBy 30000 (building.id * 1000)) / 1000.0
                                            )
                                        "House" -> ( GenerateGold
                                            , [ BuildingTag, CofferTag ]
                                            , 15.0 + toFloat (modBy 30000 (building.id * 1000)) / 1000.0
                                            )
                                        _ ->
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
            newGameState =
                if List.any (\b -> List.member ObjectiveTag b.tags && b.hp <= 0) buildingsAfterRepairs then
                    GameOver
                else
                    model.gameState
            unitsWithPaths = List.map
                    (\unit ->
                        case ( unit.location, unit.targetDestination ) of
                            ( OnMap x y, Just targetCell ) ->
                                let
                                    newPath =
                                        calculateUnitPath model.gridConfig model.mapConfig pathfindingOccupancyAfterHouses x y targetCell
                                in
                                { unit | path = newPath }
                            _ -> unit
                    )
                    unitsAfterHouseSpawn
        in
        { model
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
    else
        { model | accumulatedTime = newAccumulatedTime, tooltipHover = updatedTooltipHover }
