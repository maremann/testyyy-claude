module BehaviorEngine.Units.HouseBuilding exposing
    ( HouseBuildingState
    , initHouseBuildingState
    , updateHouseBuilding
    )

{-| House Behavior Implementation

Generated from behavior specification.

@docs HouseBuildingState, initHouseBuildingState, updateHouseBuilding
-}

import BehaviorEngine.Types exposing (..)
import BehaviorEngine.Actions as Actions
import Types exposing (..)

{-| State data for House
-}
type alias HouseBuildingState =
    { currentStrategic : StrategicHouseBuilding
    , currentTactical : Maybe TacticalHouseBuilding
    , currentOperational : Maybe OperationalHouseBuilding
    , patrolRoute : List Int
    , patrolIndex : Int
    , perimeterPoints : List ( Int, Int )
    , perimeterIndex : Int
    , engagedTarget : Maybe Int
    , interruptState : Maybe InterruptState
    }


type alias InterruptState =
    { previousTactical : TacticalHouseBuilding
    , previousOperationalIndex : Int
    }

{-| Strategic behaviors for House
-}
type StrategicHouseBuilding
    = Exist
    | WithoutHome

{-| Tactical behaviors for House
-}
type TacticalHouseBuilding
    = GenerateIncome
    | TacticalIdle

{-| Operational behaviors for House
-}
type OperationalHouseBuilding
    = IncrementGoldTimer
    | AddGoldToCoffer
    | OperationalIdle

{-| Initialize state for House
-}
initHouseBuildingState : HouseBuildingState
initHouseBuildingState =
    { currentStrategic = Exist
    , currentTactical = Nothing
    , currentOperational = Nothing
    , patrolRoute = []
    , patrolIndex = 0
    , perimeterPoints = []
    , perimeterIndex = 0
    , engagedTarget = Nothing
    , interruptState = Nothing
    }

{-| Main update function for House
-}
updateHouseBuilding : BehaviorContext -> HouseBuildingState -> ( Unit, HouseBuildingState, Bool )
updateHouseBuilding context state =
    let
        -- Check active awareness (interrupts)
        activeAwareness = checkActiveAwarenessHouseBuilding context state

        -- Handle interrupt if triggered
        ( interruptedState, wasInterrupted ) =
            case activeAwareness of
                Just trigger ->
                    handleInterruptHouseBuilding state trigger

                Nothing ->
                    ( state, False )

        -- Execute current behavior
        ( updatedUnit, updatedState, needsPath ) =
            if wasInterrupted then
                executeStrategicHouseBuilding context interruptedState
            else
                executeStrategicHouseBuilding context state
    in
    ( updatedUnit, updatedState, needsPath )

-- STRATEGIC BEHAVIOR HANDLERS

executeStrategicHouseBuilding : BehaviorContext -> HouseBuildingState -> ( Unit, HouseBuildingState, Bool )
executeStrategicHouseBuilding context state =
    case state.currentStrategic of
        Exist ->
            handleStrategicExist context state

        WithoutHome ->
            -- Unit is homeless, no actions
            ( context.unit, state, False )


handleStrategicExist : BehaviorContext -> HouseBuildingState -> ( Unit, HouseBuildingState, Bool )
handleStrategicExist context state =
    -- Delegates to tactical behaviors: GenerateIncome
    case state.currentTactical of
        Nothing ->
            -- Start with first tactical delegate
            let
                newState = { state | currentTactical = Just GenerateIncome }
            in
            executeTacticalHouseBuilding context newState

        Just tactical ->
            executeTacticalHouseBuilding context state


-- TACTICAL BEHAVIOR HANDLERS

executeTacticalHouseBuilding : BehaviorContext -> HouseBuildingState -> ( Unit, HouseBuildingState, Bool )
executeTacticalHouseBuilding context state =
    case state.currentTactical of
        Nothing ->
            ( context.unit, state, False )

        Just GenerateIncome ->
            handleTacticalGenerateIncome context state

        Just TacticalIdle ->
            ( context.unit, state, False )


handleTacticalGenerateIncome : BehaviorContext -> HouseBuildingState -> ( Unit, HouseBuildingState, Bool )
handleTacticalGenerateIncome context state =
    -- Operational sequence: IncrementGoldTimer, AddGoldToCoffer...
    -- Success: Continuous (never completes)
    -- Failure: None
    case state.currentOperational of
        Nothing ->
            -- Start with first operational step
            let
                firstOp = IncrementGoldTimer
                newState = { state | currentOperational = Just firstOp }
            in
            executeOperationalHouseBuilding context newState

        Just operational ->
            executeOperationalHouseBuilding context state

        Just TacticalIdle ->
            ( context.unit, state, False )


-- OPERATIONAL BEHAVIOR HANDLERS

executeOperationalHouseBuilding : BehaviorContext -> HouseBuildingState -> ( Unit, HouseBuildingState, Bool )
executeOperationalHouseBuilding context state =
    case state.currentOperational of
        Nothing ->
            ( context.unit, state, False )

        Just IncrementGoldTimer ->
            handleOperationalIncrementGoldTimer context state

        Just AddGoldToCoffer ->
            handleOperationalAddGoldToCoffer context state

        Just OperationalIdle ->
            ( context.unit, state, False )


handleOperationalIncrementGoldTimer : BehaviorContext -> HouseBuildingState -> ( Unit, HouseBuildingState, Bool )
handleOperationalIncrementGoldTimer context state =
    -- Action: IncrementTimer
    -- Success: timer >= building.behaviorDuration
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalAddGoldToCoffer : BehaviorContext -> HouseBuildingState -> ( Unit, HouseBuildingState, Bool )
handleOperationalAddGoldToCoffer context state =
    -- Action: AddGoldToCoffer
    -- Success: Always
    -- TODO: Implement operational logic
    ( context.unit, state, False )


-- AWARENESS FUNCTIONS

checkActiveAwarenessHouseBuilding : BehaviorContext -> HouseBuildingState -> Maybe ActiveAwarenessTrigger
checkActiveAwarenessHouseBuilding context state =
    -- Active awareness types: 
    Nothing



handleInterruptHouseBuilding : HouseBuildingState -> ActiveAwarenessTrigger -> ( HouseBuildingState, Bool )
handleInterruptHouseBuilding state trigger =
    -- Save current state for potential resume
    let
        interruptState =
            case state.currentTactical of
                Just tactical ->
                    Just { previousTactical = tactical, previousOperationalIndex = 0 }

                Nothing ->
                    Nothing

        newState =
            { state
                | currentTactical = Just trigger.forcedTactical
                , currentOperational = Nothing
                , interruptState = interruptState
            }
    in
    ( newState, True )


type alias ActiveAwarenessTrigger =
    { awarenessType : String
    , forcedTactical : TacticalHouseBuilding
    , priority : Priority
    }
