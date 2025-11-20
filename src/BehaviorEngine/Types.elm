module BehaviorEngine.Types exposing (..)

import Dict exposing (Dict)
import Types exposing (Building, Unit, UnitBehavior)


-- PRIORITY SYSTEM

type Priority
    = Critical
    | High
    | Normal
    | Low
    | Background


priorityToInt : Priority -> Int
priorityToInt priority =
    case priority of
        Critical -> 5
        High -> 4
        Normal -> 3
        Low -> 2
        Background -> 1


comparePriority : Priority -> Priority -> Order
comparePriority a b =
    compare (priorityToInt a) (priorityToInt b)


canInterrupt : Priority -> Priority -> Bool
canInterrupt newPriority currentPriority =
    priorityToInt newPriority > priorityToInt currentPriority


-- ACTION RESULTS

type ActionResult
    = NoResult
    | BuildingFound Int
    | NoBuildingFound
    | UnitFound Int
    | NoUnitFound
    | PathComplete
    | PathBlocked
    | Arrived
    | NotArrived
    | GoldCollected Int
    | NoGoldAvailable
    | GoldDeposited Int
    | RepairComplete
    | RepairInProgress
    | TimerExpired
    | HealthCritical
    | HealthOK
    | HomeDestroyed
    | HomeExists
    | LootDetected Int Float  -- value, distance
    | NoLootDetected
    | ThreatDetected Int Float  -- enemy id, distance
    | NoThreatDetected
    | Success
    | Failure String


-- OPERATIONAL ACTIONS

type OperationalAction
    = NoAction
    | Sleep
    | WaitFor Float
    | ExitGarrison
    | EnterGarrison
    | FollowPath
    | FindNearestDamagedBuilding
    | FindBuildingWithGold
    | FindHomeBuilding
    | FindCastle
    | CheckArrival
    | RepairBuilding Int  -- target building id
    | CollectGoldFrom Int  -- target building id
    | DepositGold
    | AttackUnit Int  -- target unit id
    | PatrolArea


-- TACTICAL ACTIONS (Higher level, delegate to operational)

type TacticalAction
    = TacticalNoAction
    | RestInGarrison
    | CollectTaxes
    | RepairBuildings
    | ConstructBuilding
    | HuntMonster Int
    | FleeToSafety
    | EngageEnemy Int
    | PatrolPerimeter
    | ExploreArea


-- STRATEGIC ACTIONS (Highest level, delegate to tactical)

type StrategicAction
    = StrategicIdle
    | BuildEconomy
    | DefendTerritory
    | Retreat
    | ScoutArea


-- CONDITIONS

type Condition
    = Always
    | Never
    | ActionResultEquals ActionResult
    | ActionResultMatches (ActionResult -> Bool)
    | TimerExpired_
    | After Float
    | HPBelow Float
    | HPAbove Float
    | HasGold
    | NoGold
    | IsGarrisoned
    | IsOnMap
    | AtTarget
    | NearBuilding Int
    | HomeDestroyed_
    | HomeExists_
    | And Condition Condition
    | Or Condition Condition
    | Not Condition


-- AWARENESS TYPES

type AwarenessType
    = PassiveAwareness PassiveAwarenessType
    | ActiveAwareness ActiveAwarenessType


type PassiveAwarenessType
    = WatchForThreats
    | ScanForLoot
    | ObserveAllies
    | TrackBuildingHealth
    | MonitorGoldAvailability


type ActiveAwarenessType
    = MonitorCriticalHealth  -- HP < 20%
    | DetectLegendaryLoot     -- Value > 1000, distance < 100
    | CheckHomeBuildingExists -- Home destroyed
    | DetectAmbush            -- Multiple enemies surrounding
    | MissionCriticalEvent    -- Castle under attack


-- AWARENESS STATE

type alias AwarenessState =
    { passiveData : PassiveAwarenessData
    , activeTriggered : Maybe ActiveTrigger
    }


type alias PassiveAwarenessData =
    { nearestEnemy : Maybe Int  -- enemy unit id
    , enemyDistance : Maybe Float
    , threatLevel : ThreatLevel
    , nearestLoot : Maybe ( Int, Float )  -- value, distance
    , nearbyAllies : List Int
    , damagedBuildings : List Int
    , buildingsWithGold : List Int
    }


type ThreatLevel
    = NoThreat
    | LowThreat
    | MediumThreat
    | HighThreat
    | CriticalThreat


type alias ActiveTrigger =
    { triggerType : ActiveAwarenessType
    , forcedBehavior : TacticalAction
    , priority : Priority
    }


-- GOALS

type alias Goal =
    { goalId : String
    , description : String
    , progress : Float  -- 0.0 to 1.0
    , target : Float
    , current : Float
    , utilityModifiers : List ( TacticalAction, Float )  -- action, multiplier
    , completed : Bool
    }


-- BEHAVIOR DEFINITIONS

type alias OperationalDefinition =
    { operationalId : String
    , description : String
    , action : OperationalAction
    , duration : Maybe Float  -- Nothing = until condition met
    , successCondition : Condition
    , failureCondition : Condition
    , priority : Priority
    }


type alias TacticalDefinition =
    { tacticalId : String
    , description : String
    , action : TacticalAction
    , priority : Priority
    , operationalSequence : List String  -- operational ids in order
    , currentStep : Int  -- which operational we're on
    , awarenessTypes : List AwarenessType
    , successCondition : Condition
    , failureCondition : Condition
    }


type alias StrategicDefinition =
    { strategicId : String
    , description : String
    , action : StrategicAction
    , priority : Priority
    , tacticalChildren : List TacticalSelector  -- tactical options with conditions
    , awarenessTypes : List AwarenessType
    , transitionConditions : List ( Condition, String )  -- condition, target strategic id
    }


type alias TacticalSelector =
    { tacticalId : String
    , condition : Condition  -- when this tactical should be selected
    , baseUtility : Float
    }


-- BEHAVIOR CONTEXT

type alias BehaviorContext =
    { unit : Unit
    , buildings : List Building
    , deltaSeconds : Float
    , awareness : AwarenessState
    , goals : List Goal
    }


-- BEHAVIOR STATE (what unit currently has)

type alias BehaviorState =
    { strategic : String  -- current strategic id
    , tactical : String   -- current tactical id
    , operational : String  -- current operational id
    , operationalStep : Int  -- which step in tactical sequence
    , currentPriority : Priority
    , timer : Float
    , lastActionResult : ActionResult
    }


-- BEHAVIOR EXECUTION RESULT

type BehaviorExecutionResult
    = ContinueCurrent BehaviorState  -- Keep going with current behavior
    | AdvanceToNext BehaviorState    -- Move to next operational in sequence
    | CompleteTactical ActionResult  -- Tactical complete, report to strategic
    | ForceInterrupt BehaviorState   -- Priority interrupt or active awareness
    | ErrorState String              -- Something went wrong


-- UTILITY CALCULATION

type alias UtilityScore =
    { tacticalId : String
    , baseUtility : Float
    , goalModifier : Float
    , awarenessModifier : Float
    , finalUtility : Float
    }


calculateUtility : TacticalAction -> List Goal -> PassiveAwarenessData -> Float -> UtilityScore
calculateUtility action goals awareness baseUtility =
    let
        -- Calculate goal modifier
        goalMod =
            goals
                |> List.concatMap .utilityModifiers
                |> List.filter (\( a, _ ) -> a == action)
                |> List.map Tuple.second
                |> List.foldl (*) 1.0

        -- Calculate awareness modifier
        awarenessMod =
            case action of
                FleeToSafety ->
                    case awareness.threatLevel of
                        CriticalThreat -> 3.0
                        HighThreat -> 2.0
                        MediumThreat -> 1.5
                        _ -> 1.0

                CollectTaxes ->
                    if List.isEmpty awareness.buildingsWithGold then
                        0.1
                    else
                        1.0 + (toFloat (List.length awareness.buildingsWithGold) * 0.1)

                RepairBuildings ->
                    if List.isEmpty awareness.damagedBuildings then
                        0.1
                    else
                        1.0 + (toFloat (List.length awareness.damagedBuildings) * 0.2)

                _ ->
                    1.0

        finalUtil = baseUtility * goalMod * awarenessMod
    in
    { tacticalId = tacticalActionToString action
    , baseUtility = baseUtility
    , goalModifier = goalMod
    , awarenessModifier = awarenessMod
    , finalUtility = finalUtil
    }


-- HELPER FUNCTIONS

tacticalActionToString : TacticalAction -> String
tacticalActionToString action =
    case action of
        TacticalNoAction -> "NoAction"
        RestInGarrison -> "RestInGarrison"
        CollectTaxes -> "CollectTaxes"
        RepairBuildings -> "RepairBuildings"
        ConstructBuilding -> "ConstructBuilding"
        HuntMonster _ -> "HuntMonster"
        FleeToSafety -> "FleeToSafety"
        EngageEnemy _ -> "EngageEnemy"
        PatrolPerimeter -> "PatrolPerimeter"
        ExploreArea -> "ExploreArea"


operationalActionToString : OperationalAction -> String
operationalActionToString action =
    case action of
        NoAction -> "NoAction"
        Sleep -> "Sleep"
        WaitFor _ -> "WaitFor"
        ExitGarrison -> "ExitGarrison"
        EnterGarrison -> "EnterGarrison"
        FollowPath -> "FollowPath"
        FindNearestDamagedBuilding -> "FindNearestDamagedBuilding"
        FindBuildingWithGold -> "FindBuildingWithGold"
        FindHomeBuilding -> "FindHomeBuilding"
        FindCastle -> "FindCastle"
        CheckArrival -> "CheckArrival"
        RepairBuilding _ -> "RepairBuilding"
        CollectGoldFrom _ -> "CollectGoldFrom"
        DepositGold -> "DepositGold"
        AttackUnit _ -> "AttackUnit"
        PatrolArea -> "PatrolArea"


strategicActionToString : StrategicAction -> String
strategicActionToString action =
    case action of
        StrategicIdle -> "Idle"
        BuildEconomy -> "BuildEconomy"
        DefendTerritory -> "DefendTerritory"
        Retreat -> "Retreat"
        ScoutArea -> "ScoutArea"


-- EMPTY/DEFAULT VALUES

emptyAwarenessState : AwarenessState
emptyAwarenessState =
    { passiveData =
        { nearestEnemy = Nothing
        , enemyDistance = Nothing
        , threatLevel = NoThreat
        , nearestLoot = Nothing
        , nearbyAllies = []
        , damagedBuildings = []
        , buildingsWithGold = []
        }
    , activeTriggered = Nothing
    }


defaultBehaviorState : BehaviorState
defaultBehaviorState =
    { strategic = "Idle"
    , tactical = "RestInGarrison"
    , operational = "Sleep"
    , operationalStep = 0
    , currentPriority = Background
    , timer = 0.0
    , lastActionResult = NoResult
    }
