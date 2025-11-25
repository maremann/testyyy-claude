module BehaviorEngine.UnitStates exposing (..)


-- Castle Guard Patrol State

type alias CastleGuardPatrolState =
    { currentStrategic : StrategicCastleGuardPatrol
    , currentTactical : Maybe TacticalCastleGuardPatrol
    , currentOperational : Maybe OperationalCastleGuardPatrol
    , patrolRoute : List Int
    , patrolIndex : Int
    , perimeterPoints : List ( Int, Int )
    , perimeterIndex : Int
    , engagedTarget : Maybe Int
    , interruptState : Maybe CastleGuardInterruptState
    }


type alias CastleGuardInterruptState =
    { previousTactical : TacticalCastleGuardPatrol
    , previousOperationalIndex : Int
    }


type StrategicCastleGuardPatrol
    = DefendTerritory
    | WithoutHome


type TacticalCastleGuardPatrol
    = RestInGarrison
    | PlanPatrolRoute
    | PatrolRoute
    | CircleBuilding
    | EngageMonster
    | ResumePatrol
    | ReturnToCastle
    | TacticalIdle


type OperationalCastleGuardPatrol
    = Sleep
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


type alias CastleGuardActiveAwarenessTrigger =
    { awarenessType : String
    , forcedTactical : TacticalCastleGuardPatrol
    , priorityLevel : Int
    }


-- Initial state

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
