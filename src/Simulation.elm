module Simulation exposing (simulationTick)
import BuildingBehavior exposing (updateBuildingBehavior)
import Dict
import GameHelpers exposing (createHenchman, recalculateAllPaths, updateUnitMovement)
import GameStrings
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
            ( updatedBuildings, henchmenToSpawn, goldGenerated ) = List.foldl
                    (\building ( accBuildings, accHenchmenSpawn, accGold ) ->
                        let
                            ( behaviorUpdatedBuilding, buildingGold ) = updateBuildingBehavior deltaSeconds building
                            ( garrisonUpdatedBuilding, unitsToSpawn ) = updateGarrisonSpawning deltaSeconds behaviorUpdatedBuilding
                        in
                        ( garrisonUpdatedBuilding :: accBuildings, unitsToSpawn ++ accHenchmenSpawn, accGold + buildingGold )
                    )
                    ( [], [], 0 )
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
                                    allUnits
                            hpGain = List.length repairingPeasants * 5
                            newHp = min building.maxHp (building.hp + hpGain)
                            isConstructionComplete =
                                building.behavior == UnderConstruction && newHp >= building.maxHp
                            ( completedBehavior, completedTags, completedDuration ) =
                                if isConstructionComplete then
                                    if building.buildingType == GameStrings.buildingTypeWarriorsGuild then
                                        ( GenerateGold
                                        , [ BuildingTag, GuildTag, CofferTag ]
                                        , 15.0 + toFloat (modBy 30000 (building.id * 1000)) / 1000.0
                                        )
                                    else if building.buildingType == GameStrings.buildingTypeHouse then
                                        ( GenerateGold
                                        , [ BuildingTag, CofferTag ]
                                        , 15.0 + toFloat (modBy 30000 (building.id * 1000)) / 1000.0
                                        )
                                    else
                                        ( building.behavior, building.tags, building.behaviorDuration )
                                else
                                    ( building.behavior, building.tags, building.behaviorDuration )
                            newTimer =
                                if isConstructionComplete then
                                    0
                                else
                                    building.behaviorTimer
                        in
                        { building
                            | hp = newHp
                            , behavior = completedBehavior
                            , tags = completedTags
                            , behaviorDuration = completedDuration
                            , behaviorTimer = newTimer
                        }
                    )
                    updatedBuildings
            newGameState =
                if List.any (\b -> List.member ObjectiveTag b.tags && b.hp <= 0) buildingsAfterRepairs then
                    GameOver
                else
                    model.gameState
            -- Get IDs of units that need paths
            unitIdsNeedingPaths = List.map .id unitsNeedingPaths
            unitsWithPaths = List.map
                    (\unit ->
                        -- Only generate path if this unit is in unitsNeedingPaths
                        if List.member unit.id unitIdsNeedingPaths then
                            case ( unit.location, unit.targetDestination ) of
                                ( OnMap x y, Just targetCell ) ->
                                    let
                                        newPath =
                                            calculateUnitPath model.gridConfig model.mapConfig updatedOccupancy x y targetCell
                                        _ = Debug.log "[SIM] PathGen"
                                            { unitId = unit.id
                                            , from = ( floor (x / 32), floor (y / 32) )
                                            , to = targetCell
                                            , pathLength = List.length newPath
                                            , pathEmpty = List.isEmpty newPath
                                            }
                                    in
                                    { unit | path = newPath }
                                _ -> unit
                        else
                            unit
                    )
                    allUnits
        in
        { model
            | accumulatedTime = remainingTime
            , simulationFrameCount = model.simulationFrameCount + 1
            , lastSimulationDeltas = newSimulationDeltas
            , units = unitsWithPaths
            , buildings = buildingsAfterRepairs
            , buildingOccupancy = model.buildingOccupancy
            , pathfindingOccupancy = updatedOccupancy
            , tooltipHover = updatedTooltipHover
            , nextUnitId = nextUnitIdAfterSpawning
            , nextBuildingId = model.nextBuildingId
            , gameState = newGameState
            , gold = model.gold + goldGenerated
        }
    else
        { model | accumulatedTime = newAccumulatedTime, tooltipHover = updatedTooltipHover }
