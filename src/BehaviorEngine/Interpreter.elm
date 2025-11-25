module BehaviorEngine.Interpreter exposing
    ( updateUnitBehavior
    )

import BehaviorEngine.Actions as Actions
import BehaviorEngine.Types exposing (..)
import BehaviorEngine.Units.CastleGuardPatrol as CastleGuardPatrol
import GameHelpers exposing (exitGarrison)
import Grid
import Types exposing (..)


-- MAIN ENTRY POINT

updateUnitBehavior : Float -> List Building -> Unit -> ( Unit, Bool )
updateUnitBehavior deltaSeconds buildings unit =
    let
        context =
            { unit = unit
            , buildings = buildings
            , deltaSeconds = deltaSeconds
            , awareness = emptyAwarenessState
            , goals = []  -- TODO: Load from unit
            }

        -- Step 1: Update passive awareness
        passiveData = Actions.updatePassiveAwareness context
        contextWithAwareness = { context | awareness = { passiveData = passiveData, activeTriggered = Nothing } }

        -- Step 2: Check active awareness (critical interrupts)
        activeAwarenessTrigger = Actions.checkActiveAwareness contextWithAwareness
        contextWithActive = { contextWithAwareness | awareness = { passiveData = passiveData, activeTriggered = activeAwarenessTrigger } }

        -- Step 3: If active awareness triggered, handle interrupt
        ( finalUnit, needsPath ) =
            case activeAwarenessTrigger of
                Just trigger ->
                    handleActiveTrigger contextWithActive trigger

                Nothing ->
                    -- No active trigger, continue with normal behavior
                    executeNormalBehavior contextWithActive
    in
    ( finalUnit, needsPath )


-- HANDLE ACTIVE AWARENESS TRIGGER

handleActiveTrigger : BehaviorContext -> ActiveTrigger -> ( Unit, Bool )
handleActiveTrigger context trigger =
    case trigger.triggerType of
        MonitorCriticalHealth ->
            -- Force flee to safety
            case context.unit.homeBuilding of
                Just homeBuildingId ->
                    case List.filter (\b -> b.id == homeBuildingId) context.buildings |> List.head of
                        Just homeBuilding ->
                            let
                                unit = context.unit
                                buildGridSize = 64
                                entranceX = toFloat homeBuilding.gridX * toFloat buildGridSize + toFloat buildGridSize / 2
                                entranceY = toFloat homeBuilding.gridY * toFloat buildGridSize + toFloat buildGridSize / 2
                                targetCellX = floor (entranceX / 32)
                                targetCellY = floor (entranceY / 32)
                                updatedUnit = { unit | targetDestination = Just ( targetCellX, targetCellY ) }
                            in
                            ( updatedUnit, True )

                        Nothing ->
                            let
                                unit = context.unit
                                updatedUnit = { unit | behavior = WithoutHome }
                            in
                            ( updatedUnit, False )

                Nothing ->
                    let
                        unit = context.unit
                        updatedUnit = { unit | behavior = WithoutHome }
                    in
                    ( updatedUnit, False )

        CheckHomeBuildingExists ->
            -- Home destroyed, set to WithoutHome
            let
                unit = context.unit
                updatedUnit = { unit | behavior = WithoutHome, homeBuilding = Nothing }
            in
            ( updatedUnit, False )

        _ ->
            -- Other triggers not implemented yet
            ( context.unit, False )


-- EXECUTE NORMAL BEHAVIOR

executeNormalBehavior : BehaviorContext -> ( Unit, Bool )
executeNormalBehavior context =
    -- For now, use simple state machine based on current UnitBehavior
    -- This will be replaced with full behavior tree evaluation when Registry is generated
    case context.unit.behavior of
        Dead ->
            ( context.unit, False )

        DebugError _ ->
            ( context.unit, False )

        WithoutHome ->
            let
                unit = context.unit
                newTimer = unit.behaviorTimer + context.deltaSeconds
            in
            if newTimer >= unit.behaviorDuration then
                ( { unit | behavior = Dead, behaviorTimer = 0 }, False )
            else
                ( { unit | behaviorTimer = newTimer }, False )

        Sleeping ->
            let
                ( updatedUnit, result, needsPath ) = Actions.executeOperationalAction context Sleep
                newTimer = updatedUnit.behaviorTimer + context.deltaSeconds
            in
            if newTimer >= 1.0 then
                -- Wake up and look for task
                ( { updatedUnit | behavior = LookingForTask, behaviorTimer = 0 }, False )
            else
                ( { updatedUnit | behaviorTimer = newTimer }, False )

        LookingForTask ->
            -- Decide what to do based on unit type
            let
                unit = context.unit
            in
            if unit.unitType == "Peasant" then
                ( { unit | behavior = LookForBuildRepairTarget, behaviorTimer = 0 }, False )
            else if unit.unitType == "Tax Collector" then
                ( { unit | behavior = LookForTaxTarget, behaviorTimer = 0 }, False )
            else if unit.unitType == "Castle Guard" then
                ( { unit | behavior = GoingToSleep, behaviorTimer = 0 }, False )
            else
                ( { unit | behavior = GoingToSleep, behaviorTimer = 0 }, False )

        GoingToSleep ->
            let
                unit = context.unit
            in
            case unit.location of
                Garrisoned _ ->
                    ( { unit | behavior = Sleeping, behaviorTimer = 0 }, False )

                OnMap _ _ ->
                    let
                        ( updatedUnit, result, needsPath ) = Actions.executeOperationalAction context EnterGarrison
                    in
                    case result of
                        Success ->
                            ( { updatedUnit | behavior = Sleeping, behaviorTimer = 0 }, False )

                        HomeDestroyed ->
                            ( { updatedUnit | behavior = WithoutHome, homeBuilding = Nothing, behaviorTimer = 0, behaviorDuration = 15.0 }, False )

                        NotArrived ->
                            ( updatedUnit, needsPath )

                        _ ->
                            ( updatedUnit, needsPath )

        LookForBuildRepairTarget ->
            case context.unit.location of
                Garrisoned buildingId ->
                    -- Exit garrison first
                    case List.filter (\b -> b.id == buildingId) context.buildings |> List.head of
                        Just homeBuilding ->
                            let
                                exitedUnit = exitGarrison homeBuilding context.unit
                                contextWithExited = { context | unit = exitedUnit }
                                ( searchedUnit, result, needsPath ) = Actions.executeOperationalAction contextWithExited FindNearestDamagedBuilding
                            in
                            case result of
                                BuildingFound _ ->
                                    ( { searchedUnit | behavior = MovingToBuildRepairTarget, behaviorTimer = 0 }, needsPath )

                                NoBuildingFound ->
                                    ( { searchedUnit | behavior = GoingToSleep, behaviorTimer = 0 }, False )

                                _ ->
                                    ( searchedUnit, needsPath )

                        Nothing ->
                            let
                                unit = context.unit
                            in
                            ( { unit | behavior = WithoutHome }, False )

                OnMap _ _ ->
                    let
                        ( searchedUnit, result, needsPath ) = Actions.executeOperationalAction context FindNearestDamagedBuilding
                    in
                    case result of
                        BuildingFound _ ->
                            ( { searchedUnit | behavior = MovingToBuildRepairTarget, behaviorTimer = 0 }, needsPath )

                        NoBuildingFound ->
                            ( { searchedUnit | behavior = GoingToSleep, behaviorTimer = 0 }, False )

                        _ ->
                            ( searchedUnit, needsPath )

        MovingToBuildRepairTarget ->
            let
                ( checkedUnit, result, needsPath ) = Actions.executeOperationalAction context CheckArrival
            in
            case result of
                Arrived ->
                    ( { checkedUnit | behavior = Repairing, behaviorTimer = 0 }, False )

                _ ->
                    ( checkedUnit, False )

        Repairing ->
            let
                unit = context.unit
                newTimer = unit.behaviorTimer + context.deltaSeconds
            in
            if newTimer >= 0.15 then
                -- Check if building still needs repair
                case context.awareness.passiveData.damagedBuildings of
                    [] ->
                        ( { unit | behavior = LookForBuildRepairTarget, behaviorTimer = 0 }, False )

                    _ ->
                        ( { unit | behaviorTimer = 0 }, False )
            else
                ( { unit | behaviorTimer = newTimer }, False )

        LookForTaxTarget ->
            -- Tax collector behavior (placeholder)
            let
                unit = context.unit
            in
            ( { unit | behavior = GoingToSleep, behaviorTimer = 0 }, False )

        CollectingTaxes ->
            ( context.unit, False )

        ReturnToCastle ->
            ( context.unit, False )

        DeliveringGold ->
            ( context.unit, False )

        -- New behavior tree system
        CastleGuardPatrol guardState ->
            let
                ( updatedUnit, updatedState, needsPath ) =
                    CastleGuardPatrol.updateCastleGuardPatrol context guardState
            in
            ( { updatedUnit | behavior = CastleGuardPatrol updatedState }, needsPath )


-- CONDITION EVALUATION (for future behavior tree use)

evaluateCondition : Condition -> BehaviorContext -> ActionResult -> Bool
evaluateCondition condition context lastResult =
    case condition of
        Always ->
            True

        Never ->
            False

        ActionResultEquals expected ->
            lastResult == expected

        ActionResultMatches predicate ->
            predicate lastResult

        TimerExpired_ ->
            context.unit.behaviorTimer >= context.unit.behaviorDuration

        After duration ->
            context.unit.behaviorTimer >= duration

        HPBelow threshold ->
            toFloat context.unit.hp < (toFloat context.unit.maxHp * threshold)

        HPAbove threshold ->
            toFloat context.unit.hp > (toFloat context.unit.maxHp * threshold)

        HasGold ->
            context.unit.carriedGold > 0

        NoGold ->
            context.unit.carriedGold == 0

        IsGarrisoned ->
            case context.unit.location of
                Garrisoned _ -> True
                _ -> False

        IsOnMap ->
            case context.unit.location of
                OnMap _ _ -> True
                _ -> False

        AtTarget ->
            case context.unit.targetDestination of
                Nothing -> True
                Just _ -> False

        NearBuilding buildingId ->
            case context.unit.location of
                OnMap x y ->
                    case List.filter (\b -> b.id == buildingId) context.buildings |> List.head of
                        Just building ->
                            let
                                buildGridSize = 64
                                bx = toFloat building.gridX * toFloat buildGridSize
                                by = toFloat building.gridY * toFloat buildGridSize
                                dist = sqrt ((x - bx) ^ 2 + (y - by) ^ 2)
                            in
                            dist < 100

                        Nothing ->
                            False

                _ ->
                    False

        HomeDestroyed_ ->
            case context.unit.homeBuilding of
                Nothing -> True
                Just id -> not (List.any (\b -> b.id == id) context.buildings)

        HomeExists_ ->
            case context.unit.homeBuilding of
                Nothing -> False
                Just id -> List.any (\b -> b.id == id) context.buildings

        And cond1 cond2 ->
            evaluateCondition cond1 context lastResult && evaluateCondition cond2 context lastResult

        Or cond1 cond2 ->
            evaluateCondition cond1 context lastResult || evaluateCondition cond2 context lastResult

        Not cond ->
            not (evaluateCondition cond context lastResult)
