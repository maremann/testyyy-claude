module BehaviorEngine.Units.CastleGuardPatrol exposing
    ( CastleGuardPatrolState
    , initCastleGuardPatrolState
    , updateCastleGuardPatrol
    )

{-| Castle Guard Behavior Implementation

Generated from behavior specification.

@docs CastleGuardPatrolState, initCastleGuardPatrolState, updateCastleGuardPatrol
-}

import BehaviorEngine.Types exposing (..)
import BehaviorEngine.Actions as Actions
import Types exposing (..)

{-| State data for Castle Guard
-}
type alias CastleGuardPatrolState =
    { currentStrategic : StrategicCastleGuardPatrol
    , currentTactical : Maybe TacticalCastleGuardPatrol
    , currentOperational : Maybe OperationalCastleGuardPatrol
    , patrolRoute : List Int
    , patrolIndex : Int
    , perimeterPoints : List ( Int, Int )
    , perimeterIndex : Int
    , engagedTarget : Maybe Int
    , interruptState : Maybe InterruptState
    }


type alias InterruptState =
    { previousTactical : TacticalCastleGuardPatrol
    , previousOperationalIndex : Int
    }

{-| Strategic behaviors for Castle Guard
-}
type StrategicCastleGuardPatrol
    | DefendTerritory
    | WithoutHome

{-| Tactical behaviors for Castle Guard
-}
type TacticalCastleGuardPatrol
    | RestInGarrison
    | PlanPatrolRoute
    | PatrolRoute
    | CircleBuilding
    | EngageMonster
    | ResumePatrol
    | ReturnToCastle
    | TacticalIdle

{-| Operational behaviors for Castle Guard
-}
type OperationalCastleGuardPatrol
    | Sleep
    | SelectPatrolBuildings
    | GetCurrentPatrolTarget
    | MoveToBuilding
    | CirclePerimeter
    | IncrementPatrolIndex
    | CheckCircleComplete
    | FindCastle
    | MoveToMonster
    | AttackMonster
    | CheckMonsterDefeated
    | ExitGarrison
    | EnterGarrison
    | OperationalIdle

{-| Initialize state for Castle Guard
-}
initCastleGuardPatrolState : CastleGuardPatrolState
initCastleGuardPatrolState =
    { currentStrategic = DefendTerritory
    , currentTactical = Nothing
    , currentOperational = Nothing
    , patrolRoute = []
    , patrolIndex = 0
    , perimeterPoints = []
    , perimeterIndex = 0
    , engagedTarget = Nothing
    , interruptState = Nothing
    }

{-| Main update function for Castle Guard
-}
updateCastleGuardPatrol : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
updateCastleGuardPatrol context state =
    let
        -- Check active awareness (interrupts)
        activeAwareness = checkActiveAwarenessCastleGuardPatrol context state

        -- Handle interrupt if triggered
        ( interruptedState, wasInterrupted ) =
            case activeAwareness of
                Just trigger ->
                    handleInterruptCastleGuardPatrol state trigger

                Nothing ->
                    ( state, False )

        -- Execute current behavior
        ( updatedUnit, updatedState, needsPath ) =
            if wasInterrupted then
                executeStrategicCastleGuardPatrol context interruptedState
            else
                executeStrategicCastleGuardPatrol context state
    in
    ( updatedUnit, updatedState, needsPath )

-- STRATEGIC BEHAVIOR HANDLERS

executeStrategicCastleGuardPatrol : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
executeStrategicCastleGuardPatrol context state =
    case state.currentStrategic of
        DefendTerritory ->
            handleStrategicDefendTerritory context state

        WithoutHome ->
            -- Unit is homeless, no actions
            ( context.unit, state, False )


handleStrategicDefendTerritory : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleStrategicDefendTerritory context state =
    -- Delegates to tactical behaviors: EngageMonster, PatrolRoute, ReturnToCastle
    case state.currentTactical of
        Nothing ->
            -- Start with first tactical delegate
            let
                newState = { state | currentTactical = Just EngageMonster }
            in
            executeTacticalCastleGuardPatrol context newState

        Just tactical ->
            executeTacticalCastleGuardPatrol context state


-- TACTICAL BEHAVIOR HANDLERS

executeTacticalCastleGuardPatrol : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
executeTacticalCastleGuardPatrol context state =
    case state.currentTactical of
        Nothing ->
            ( context.unit, state, False )

        Just RestInGarrison ->
            handleTacticalRestInGarrison context state

        Just PlanPatrolRoute ->
            handleTacticalPlanPatrolRoute context state

        Just PatrolRoute ->
            handleTacticalPatrolRoute context state

        Just CircleBuilding ->
            handleTacticalCircleBuilding context state

        Just EngageMonster ->
            handleTacticalEngageMonster context state

        Just ResumePatrol ->
            handleTacticalResumePatrol context state

        Just ReturnToCastle ->
            handleTacticalReturnToCastle context state

        Just TacticalIdle ->
            ( context.unit, state, False )


handleTacticalRestInGarrison : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleTacticalRestInGarrison context state =
    -- Operational sequence: Sleep, PlanPatrolRoute, ExitGarrison...
    -- Success: HP = maxHP OR timer > 5s
    -- Failure: 
    case state.currentOperational of
        Nothing ->
            -- Start with first operational step
            let
                firstOp = Sleep
                newState = { state | currentOperational = Just firstOp }
            in
            executeOperationalCastleGuardPatrol context newState

        Just operational ->
            executeOperationalCastleGuardPatrol context state

handleTacticalPlanPatrolRoute : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleTacticalPlanPatrolRoute context state =
    -- Operational sequence: SelectPatrolBuildings, SetPatrolIndex...
    -- Success: Patrol route with 1-3 buildings created
    -- Failure: No buildings available
    case state.currentOperational of
        Nothing ->
            -- Start with first operational step
            let
                firstOp = SelectPatrolBuildings
                newState = { state | currentOperational = Just firstOp }
            in
            executeOperationalCastleGuardPatrol context newState

        Just operational ->
            executeOperationalCastleGuardPatrol context state

handleTacticalPatrolRoute : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleTacticalPatrolRoute context state =
    -- Operational sequence: GetCurrentPatrolTarget, MoveToBuilding, CircleBuilding...
    -- Success: All buildings in patrol route visited
    -- Failure: Patrol target building destroyed
    case state.currentOperational of
        Nothing ->
            -- Start with first operational step
            let
                firstOp = GetCurrentPatrolTarget
                newState = { state | currentOperational = Just firstOp }
            in
            executeOperationalCastleGuardPatrol context newState

        Just operational ->
            executeOperationalCastleGuardPatrol context state

handleTacticalCircleBuilding : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleTacticalCircleBuilding context state =
    -- Operational sequence: CalculateBuildingPerimeter, MoveToPerimeterPoint, CheckCircleComplete...
    -- Success: Full circle completed
    -- Failure: Building destroyed mid-circle
    case state.currentOperational of
        Nothing ->
            -- Start with first operational step
            let
                firstOp = CalculateBuildingPerimeter
                newState = { state | currentOperational = Just firstOp }
            in
            executeOperationalCastleGuardPatrol context newState

        Just operational ->
            executeOperationalCastleGuardPatrol context state

handleTacticalEngageMonster : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleTacticalEngageMonster context state =
    -- Operational sequence: MoveToMonster, AttackMonster, CheckMonsterDefeated...
    -- Success: Monster defeated
    -- Failure: Guard HP reaches 0
    case state.currentOperational of
        Nothing ->
            -- Start with first operational step
            let
                firstOp = MoveToMonster
                newState = { state | currentOperational = Just firstOp }
            in
            executeOperationalCastleGuardPatrol context newState

        Just operational ->
            executeOperationalCastleGuardPatrol context state

handleTacticalResumePatrol : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleTacticalResumePatrol context state =
    -- Operational sequence: CheckPatrolState, If patrol route exists → PatrolRoute, If no patrol route → PlanPatrolRoute...
    -- Success: Always succeeds
    -- Failure: 
    case state.currentOperational of
        Nothing ->
            -- Start with first operational step
            let
                firstOp = CheckPatrolState
                newState = { state | currentOperational = Just firstOp }
            in
            executeOperationalCastleGuardPatrol context newState

        Just operational ->
            executeOperationalCastleGuardPatrol context state

handleTacticalReturnToCastle : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleTacticalReturnToCastle context state =
    -- Operational sequence: FindCastle, MoveToBuilding, EnterGarrison...
    -- Success: Entered castle garrison
    -- Failure: Castle destroyed
    case state.currentOperational of
        Nothing ->
            -- Start with first operational step
            let
                firstOp = FindCastle
                newState = { state | currentOperational = Just firstOp }
            in
            executeOperationalCastleGuardPatrol context newState

        Just operational ->
            executeOperationalCastleGuardPatrol context state

        Just TacticalIdle ->
            ( context.unit, state, False )


-- OPERATIONAL BEHAVIOR HANDLERS

executeOperationalCastleGuardPatrol : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
executeOperationalCastleGuardPatrol context state =
    case state.currentOperational of
        Nothing ->
            ( context.unit, state, False )

        Just Sleep ->
            handleOperationalSleep context state

        Just SelectPatrolBuildings ->
            handleOperationalSelectPatrolBuildings context state

        Just GetCurrentPatrolTarget ->
            handleOperationalGetCurrentPatrolTarget context state

        Just MoveToBuilding ->
            handleOperationalMoveToBuilding context state

        Just CirclePerimeter ->
            handleOperationalCirclePerimeter context state

        Just IncrementPatrolIndex ->
            handleOperationalIncrementPatrolIndex context state

        Just CheckCircleComplete ->
            handleOperationalCheckCircleComplete context state

        Just FindCastle ->
            handleOperationalFindCastle context state

        Just MoveToMonster ->
            handleOperationalMoveToMonster context state

        Just AttackMonster ->
            handleOperationalAttackMonster context state

        Just CheckMonsterDefeated ->
            handleOperationalCheckMonsterDefeated context state

        Just ExitGarrison ->
            handleOperationalExitGarrison context state

        Just EnterGarrison ->
            handleOperationalEnterGarrison context state

        Just OperationalIdle ->
            ( context.unit, state, False )


handleOperationalSleep : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalSleep context state =
    -- Action: Sleep (heals 10% maxHP per second)
    -- Success: HP = maxHP OR timer > 5s
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalSelectPatrolBuildings : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalSelectPatrolBuildings context state =
    -- Action: FindPlayerBuildings
    -- Success: 1-3 buildings selected
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalGetCurrentPatrolTarget : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalGetCurrentPatrolTarget context state =
    -- Action: LookupPatrolRoute
    -- Success: Building exists at index
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalMoveToBuilding : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalMoveToBuilding context state =
    -- Action: FollowPath
    -- Success: Within 32 pixels of building
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalCirclePerimeter : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalCirclePerimeter context state =
    -- Action: FollowPerimeterPath
    -- Success: Visited all perimeter points
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalIncrementPatrolIndex : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalIncrementPatrolIndex context state =
    -- Action: IncrementCounter
    -- Success: 
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalCheckCircleComplete : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalCheckCircleComplete context state =
    -- Action: CheckCounter
    -- Success: 
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalFindCastle : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalFindCastle context state =
    -- Action: FindBuildingByType
    -- Success: Castle found
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalMoveToMonster : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalMoveToMonster context state =
    -- Action: FollowPath
    -- Success: Within melee range of monster
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalAttackMonster : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalAttackMonster context state =
    -- Action: MeleeAttack
    -- Success: Monster HP reduced
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalCheckMonsterDefeated : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalCheckMonsterDefeated context state =
    -- Action: CheckUnitHP
    -- Success: 
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalExitGarrison : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalExitGarrison context state =
    -- Action: NoAction
    -- Success: Now on map at castle entrance
    -- TODO: Implement operational logic
    ( context.unit, state, False )

handleOperationalEnterGarrison : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalEnterGarrison context state =
    -- Action: NoAction
    -- Success: Now garrisoned in castle
    -- TODO: Implement operational logic
    ( context.unit, state, False )


-- AWARENESS FUNCTIONS

checkActiveAwarenessCastleGuardPatrol : BehaviorContext -> CastleGuardPatrolState -> Maybe ActiveAwarenessTrigger
checkActiveAwarenessCastleGuardPatrol context state =
    -- Active awareness types: WatchForMonsters
    if checkWatchForMonsters context then
        Just
            { awarenessType = "WatchForMonsters"
            , forcedTactical = EngageMonster
            , priority = Critical
            }
    else
        Nothing


checkWatchForMonsters : BehaviorContext -> Bool
checkWatchForMonsters context =
    -- Continuously scan for enemy units
    -- Trigger: Enemy unit within search radius
    -- TODO: Implement awareness check
    False


handleInterruptCastleGuardPatrol : CastleGuardPatrolState -> ActiveAwarenessTrigger -> ( CastleGuardPatrolState, Bool )
handleInterruptCastleGuardPatrol state trigger =
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
    , forcedTactical : TacticalCastleGuardPatrol
    , priority : Priority
    }
