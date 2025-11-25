module BehaviorEngine.Units.CastleBuilding exposing
    ( CastleBuildingState
    , initCastleBuildingState
    , updateCastleBuilding
    )

{-| Castle Behavior Implementation

Generated from behavior specification.

@docs CastleBuildingState, initCastleBuildingState, updateCastleBuilding
-}

import BehaviorEngine.Types exposing (..)
import BehaviorEngine.Actions as Actions
import Types exposing (..)

{-| State data for Castle
-}
type alias CastleBuildingState =
    { currentStrategic : StrategicCastleBuilding
    , currentTactical : Maybe TacticalCastleBuilding
    , currentOperational : Maybe OperationalCastleBuilding
    , patrolRoute : List Int
    , patrolIndex : Int
    , perimeterPoints : List ( Int, Int )
    , perimeterIndex : Int
    , engagedTarget : Maybe Int
    , interruptState : Maybe InterruptState
    }


type alias InterruptState =
    { previousTactical : TacticalCastleBuilding
    , previousOperationalIndex : Int
    }

{-| Strategic behaviors for Castle
-}
type StrategicCastleBuilding
    = Exist
    | WithoutHome

{-| Tactical behaviors for Castle
-}
type TacticalCastleBuilding
    = GenerateIncome
    | TacticalIdle

{-| Operational behaviors for Castle
-}
type OperationalCastleBuilding
    = IncrementGoldTimer
    | AddGoldToPlayer
    | OperationalIdle

{-| Initialize state for Castle
-}
initCastleBuildingState : CastleBuildingState
initCastleBuildingState =
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

{-| Main update function for Castle
-}
updateCastleBuilding : BehaviorContext -> CastleBuildingState -> ( Unit, CastleBuildingState, Bool )
updateCastleBuilding context state =
    let
        -- Check active awareness (interrupts)
        activeAwareness = checkActiveAwarenessCastleBuilding context state

        -- Handle interrupt if triggered
        ( interruptedState, wasInterrupted ) =
            case activeAwareness of
                Just trigger ->
                    handleInterruptCastleBuilding state trigger

                Nothing ->
                    ( state, False )

        -- Execute current behavior
        ( updatedUnit, updatedState, needsPath ) =
            if wasInterrupted then
                executeStrategicCastleBuilding context interruptedState
            else
                executeStrategicCastleBuilding context state
    in
    ( updatedUnit, updatedState, needsPath )

-- STRATEGIC BEHAVIOR HANDLERS

executeStrategicCastleBuilding : BehaviorContext -> CastleBuildingState -> ( Unit, CastleBuildingState, Bool )
executeStrategicCastleBuilding context state =
    case state.currentStrategic of
        Exist ->
            handleStrategicExist context state

        WithoutHome ->
            -- Unit is homeless, no actions
            ( context.unit, state, False )


handleStrategicExist : BehaviorContext -> CastleBuildingState -> ( Unit, CastleBuildingState, Bool )
handleStrategicExist context state =
    -- Delegates to tactical behaviors: GenerateIncome
    case state.currentTactical of
        Nothing ->
            -- Start with first tactical delegate
            let
                newState = { state | currentTactical = Just GenerateIncome }
            in
            executeTacticalCastleBuilding context newState

        Just tactical ->
            executeTacticalCastleBuilding context state


-- TACTICAL BEHAVIOR HANDLERS

executeTacticalCastleBuilding : BehaviorContext -> CastleBuildingState -> ( Unit, CastleBuildingState, Bool )
executeTacticalCastleBuilding context state =
    case state.currentTactical of
        Nothing ->
            ( context.unit, state, False )

        Just GenerateIncome ->
            handleTacticalGenerateIncome context state

        Just TacticalIdle ->
            ( context.unit, state, False )


handleTacticalGenerateIncome : BehaviorContext -> CastleBuildingState -> ( Unit, CastleBuildingState, Bool )
handleTacticalGenerateIncome context state =
    -- Operational sequence: IncrementGoldTimer, AddGoldToPlayer...
    -- Success: Continuous (never completes)
    -- Failure: None
    case state.currentOperational of
        Nothing ->
            -- Start with first operational step
            let
                firstOp = IncrementGoldTimer
                newState = { state | currentOperational = Just firstOp }
            in
            executeOperationalCastleBuilding context newState

        Just operational ->
            executeOperationalCastleBuilding context state

        Just TacticalIdle ->
            ( context.unit, state, False )


-- OPERATIONAL BEHAVIOR HANDLERS

executeOperationalCastleBuilding : BehaviorContext -> CastleBuildingState -> ( Unit, CastleBuildingState, Bool )
executeOperationalCastleBuilding context state =
    case state.currentOperational of
        Nothing ->
            ( context.unit, state, False )

        Just IncrementGoldTimer ->
            handleOperationalIncrementGoldTimer context state

        Just AddGoldToPlayer ->
            handleOperationalAddGoldToPlayer context state

        Just OperationalIdle ->
            ( context.unit, state, False )


handleOperationalIncrementGoldTimer : BehaviorContext -> CastleBuildingState -> ( Unit, CastleBuildingState, Bool )
handleOperationalIncrementGoldTimer context state =
    -- Action: IncrementTimer
    -- Success: timer >= building.behaviorDuration
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalAddGoldToPlayer : BehaviorContext -> CastleBuildingState -> ( Unit, CastleBuildingState, Bool )
handleOperationalAddGoldToPlayer context state =
    -- Action: AddGoldToPlayer
    -- Success: Always
    -- TODO: Implement operational logic
    ( context.unit, state, False )


-- AWARENESS FUNCTIONS

checkActiveAwarenessCastleBuilding : BehaviorContext -> CastleBuildingState -> Maybe ActiveAwarenessTrigger
checkActiveAwarenessCastleBuilding context state =
    -- Active awareness types: 
    Nothing



handleInterruptCastleBuilding : CastleBuildingState -> ActiveAwarenessTrigger -> ( CastleBuildingState, Bool )
handleInterruptCastleBuilding state trigger =
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
    , forcedTactical : TacticalCastleBuilding
    , priority : Priority
    }
