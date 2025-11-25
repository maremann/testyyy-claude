module BehaviorEngine.Units.CastleGuardPatrol exposing
    ( updateCastleGuardPatrol
    )

{-| Castle Guard Behavior Implementation

Generated from behavior specification.

@docs updateCastleGuardPatrol
-}

import BehaviorEngine.Types as BT exposing (ActionResult(..), BehaviorContext, OperationalAction, Priority(..))
import BehaviorEngine.UnitStates exposing
    ( CastleGuardPatrolState
    , StrategicCastleGuardPatrol(..)
    , TacticalCastleGuardPatrol(..)
    , OperationalCastleGuardPatrol(..)
    , CastleGuardActiveAwarenessTrigger
    )
import BehaviorEngine.Actions as Actions
import Grid exposing (getBuildingEntrance)
import Types exposing (Building, BuildingOwner(..), Unit, UnitLocation(..), buildingSizeToGridCells)

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
            -- Determine initial tactical based on unit location
            let
                initialTactical =
                    case context.unit.location of
                        Garrisoned _ ->
                            -- Unit is in garrison, start with RestInGarrison
                            RestInGarrison

                        OnMap _ _ ->
                            -- Unit is on map, check if has patrol route
                            if List.isEmpty state.patrolRoute then
                                -- No patrol route, plan one
                                PlanPatrolRoute
                            else
                                -- Has patrol route, continue patrolling
                                PatrolRoute

                newState = { state | currentTactical = Just initialTactical }
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
    -- Operational sequence: CirclePerimeter, CheckCircleComplete...
    -- Success: Full circle completed
    -- Failure: Building destroyed mid-circle
    case state.currentOperational of
        Nothing ->
            -- Start with first operational step
            let
                firstOp = CirclePerimeter
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
    -- Check if patrol route exists
    if List.isEmpty state.patrolRoute then
        -- No patrol route, plan one
        ( context.unit
        , { state | currentTactical = Just PlanPatrolRoute, currentOperational = Nothing }
        , False
        )
    else
        -- Has patrol route, continue patrolling
        ( context.unit
        , { state | currentTactical = Just PatrolRoute, currentOperational = Nothing }
        , False
        )

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
    -- Success: timer >= 5s (minimum rest period)
    let
        ( updatedUnit, result, needsPath ) = Actions.executeOperationalAction context BT.Sleep
        newTimer = updatedUnit.behaviorTimer + context.deltaSeconds
    in
    if newTimer >= 5.0 then
        -- Sleep complete, exit garrison next
        ( { updatedUnit | behaviorTimer = 0 }
        , { state | currentOperational = Just ExitGarrison }
        , False
        )
    else
        ( { updatedUnit | behaviorTimer = newTimer }, state, needsPath )

handleOperationalSelectPatrolBuildings : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalSelectPatrolBuildings context state =
    -- Action: FindPlayerBuildings
    -- Success: 1-3 buildings selected
    let
        ( updatedUnit, result, needsPath ) = Actions.executeOperationalAction context BT.SelectPatrolBuildings
        _ = Debug.log "[CG] SelectPatrolBuildings" { result = result, needsPath = needsPath }
    in
    case result of
        PatrolRouteCreated buildingIds ->
            let
                _ = Debug.log "[CG] PatrolRouteCreated" { buildingIds = buildingIds, count = List.length buildingIds }
            in
            ( updatedUnit
            , { state
                | patrolRoute = buildingIds
                , patrolIndex = 0
                , currentTactical = Just PatrolRoute
                , currentOperational = Nothing
              }
            , needsPath
            )

        NoBuildingFound ->
            let
                _ = Debug.log "[CG] NoBuildingFound" "Returning to castle"
            in
            -- No buildings to patrol, go back to sleep
            ( updatedUnit
            , { state | currentTactical = Just ReturnToCastle, currentOperational = Nothing }
            , False
            )

        _ ->
            ( updatedUnit, state, needsPath )

handleOperationalGetCurrentPatrolTarget : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalGetCurrentPatrolTarget context state =
    -- Action: LookupPatrolRoute
    -- Success: Building exists at index
    let
        _ = Debug.log "[CG] GetCurrentPatrolTarget" { patrolIndex = state.patrolIndex, routeLength = List.length state.patrolRoute }
    in
    case List.drop state.patrolIndex state.patrolRoute |> List.head of
        Just buildingId ->
            -- Found building, verify it still exists
            case List.filter (\b -> b.id == buildingId) context.buildings |> List.head of
                Just building ->
                    let
                        unit = context.unit
                        buildGridSize = 64
                        pathGridSize = 32

                        -- Calculate building center in world coordinates
                        sizeCells = buildingSizeToGridCells building.size
                        buildingCenterX = toFloat building.gridX * toFloat buildGridSize + (toFloat sizeCells * toFloat buildGridSize / 2)
                        buildingCenterY = toFloat building.gridY * toFloat buildGridSize + (toFloat sizeCells * toFloat buildGridSize / 2)

                        -- Get unit's current position
                        ( unitX, unitY ) = case unit.location of
                            OnMap x y -> ( x, y )
                            Garrisoned _ -> ( buildingCenterX, buildingCenterY )  -- Shouldn't happen, but fallback

                        -- Calculate vector from building center to unit
                        dx = unitX - buildingCenterX
                        dy = unitY - buildingCenterY

                        -- Calculate opposite side (negate the vector and extend it)
                        buildingRadius = toFloat sizeCells * toFloat buildGridSize / 2
                        distance = sqrt (dx * dx + dy * dy)
                        normalizedDx = if distance > 0 then dx / distance else 1
                        normalizedDy = if distance > 0 then dy / distance else 0

                        -- Target is on opposite side, outside the building
                        targetWorldX = buildingCenterX - normalizedDx * (buildingRadius + 48)
                        targetWorldY = buildingCenterY - normalizedDy * (buildingRadius + 48)
                        targetCellX = floor (targetWorldX / toFloat pathGridSize)
                        targetCellY = floor (targetWorldY / toFloat pathGridSize)

                        updatedUnit = { unit | targetDestination = Just ( targetCellX, targetCellY ) }
                        _ = Debug.log "[CG] SetTarget (patrol)"
                            { buildingId = buildingId
                            , unitPos = ( floor (unitX / toFloat pathGridSize), floor (unitY / toFloat pathGridSize) )
                            , buildingCenter = ( floor (buildingCenterX / toFloat pathGridSize), floor (buildingCenterY / toFloat pathGridSize) )
                            , targetCell = ( targetCellX, targetCellY )
                            , needsPath = True
                            }
                    in
                    ( updatedUnit
                    , { state | currentOperational = Just MoveToBuilding }
                    , True
                    )

                Nothing ->
                    -- Building destroyed, remove from patrol and try next
                    let
                        newRoute = List.take state.patrolIndex state.patrolRoute ++ List.drop (state.patrolIndex + 1) state.patrolRoute
                    in
                    ( context.unit
                    , { state | patrolRoute = newRoute, currentOperational = Just IncrementPatrolIndex }
                    , False
                    )

        Nothing ->
            -- No more buildings in patrol, return to castle
            ( context.unit
            , { state | currentTactical = Just ReturnToCastle, currentOperational = Nothing }
            , False
            )

handleOperationalMoveToBuilding : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalMoveToBuilding context state =
    -- Action: FollowPath
    -- Success: Within 32 pixels of building
    let
        ( updatedUnit, result, needsPath ) = Actions.executeOperationalAction context BT.CheckArrival
    in
    case result of
        Arrived ->
            -- Check tactical state to determine correct behavior on arrival
            case state.currentTactical of
                Just PatrolRoute ->
                    -- Patrolling: start circling building
                    let
                        _ = Debug.log "[CG] Arrived at building" "Transitioning to CircleBuilding"
                    in
                    ( updatedUnit
                    , { state | currentTactical = Just CircleBuilding, currentOperational = Nothing }
                    , False
                    )

                Just ReturnToCastle ->
                    -- Returning home: enter garrison
                    let
                        _ = Debug.log "[CG] Arrived at castle" "Transitioning to EnterGarrison"
                    in
                    ( updatedUnit
                    , { state | currentOperational = Just EnterGarrison }
                    , False
                    )

                _ ->
                    -- Shouldn't happen, but default to circling
                    let
                        _ = Debug.log "[CG] Arrived at building (unknown tactical)" "Defaulting to CircleBuilding"
                    in
                    ( updatedUnit
                    , { state | currentTactical = Just CircleBuilding, currentOperational = Nothing }
                    , False
                    )

        _ ->
            -- Only request path if we don't have one
            ( updatedUnit, state, List.isEmpty updatedUnit.path )

handleOperationalCirclePerimeter : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalCirclePerimeter context state =
    -- Simplified: Pick random waypoints around the building and patrol continuously
    case List.drop state.patrolIndex state.patrolRoute |> List.head of
        Nothing ->
            -- No building to circle
            ( context.unit, { state | currentOperational = Just CheckCircleComplete }, False )

        Just buildingId ->
            case List.filter (\b -> b.id == buildingId) context.buildings |> List.head of
                Nothing ->
                    -- Building destroyed
                    ( context.unit, { state | currentOperational = Just CheckCircleComplete }, False )

                Just building ->
                    -- Check if we have a target or need a new one
                    case context.unit.targetDestination of
                        Nothing ->
                            -- Pick a new random waypoint around the building
                            let
                                unit = context.unit
                                buildGridSize = 64
                                pathGridSize = 32
                                sizeCells = buildingSizeToGridCells building.size
                                buildingCenterX = toFloat building.gridX * toFloat buildGridSize + (toFloat sizeCells * toFloat buildGridSize / 2)
                                buildingCenterY = toFloat building.gridY * toFloat buildGridSize + (toFloat sizeCells * toFloat buildGridSize / 2)
                                buildingRadius = toFloat sizeCells * toFloat buildGridSize / 2

                                -- Generate random angle based on unit ID and perimeter index (deterministic but varied)
                                angle = toFloat (state.perimeterIndex * 73 + context.unit.id * 137) * 0.1
                                distance = buildingRadius + 64  -- 64 pixels outside the building

                                -- Calculate random waypoint
                                targetWorldX = buildingCenterX + distance * cos angle
                                targetWorldY = buildingCenterY + distance * sin angle
                                targetCellX = floor (targetWorldX / toFloat pathGridSize)
                                targetCellY = floor (targetWorldY / toFloat pathGridSize)

                                updatedUnit = { unit | targetDestination = Just ( targetCellX, targetCellY ) }
                                _ = Debug.log "[CG] CirclePerimeter new waypoint"
                                    { buildingId = buildingId
                                    , waypointIndex = state.perimeterIndex
                                    , targetCell = ( targetCellX, targetCellY )
                                    }
                            in
                            ( updatedUnit
                            , state
                            , True  -- Need path to new waypoint
                            )

                        Just _ ->
                            -- Check if arrived at current waypoint
                            let
                                ( updatedUnit, result, _ ) = Actions.executeOperationalAction context BT.CheckArrival
                            in
                            case result of
                                Arrived ->
                                    -- Arrived, pick next waypoint (increment index and clear target)
                                    let
                                        newIndex = state.perimeterIndex + 1
                                        _ = Debug.log "[CG] CirclePerimeter arrived" { waypointIndex = newIndex }
                                        -- Check if circled enough times (e.g., 2 waypoints = full circle)
                                        circleComplete = newIndex >= 2
                                    in
                                    if circleComplete then
                                        ( { updatedUnit | targetDestination = Nothing }
                                        , { state | currentOperational = Just CheckCircleComplete, perimeterIndex = 0 }
                                        , False
                                        )
                                    else
                                        ( { updatedUnit | targetDestination = Nothing }
                                        , { state | perimeterIndex = newIndex }
                                        , False  -- Will pick new waypoint on next update
                                        )

                                _ ->
                                    -- Still moving to waypoint, only request path if we don't have one
                                    ( updatedUnit, state, List.isEmpty updatedUnit.path )

handleOperationalIncrementPatrolIndex : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalIncrementPatrolIndex context state =
    -- Action: IncrementCounter
    let
        newIndex = state.patrolIndex + 1
    in
    if newIndex >= List.length state.patrolRoute then
        -- Patrol complete, return to castle
        ( context.unit
        , { state | patrolIndex = 0, currentTactical = Just ReturnToCastle, currentOperational = Nothing }
        , False
        )
    else
        -- Continue to next building
        ( context.unit
        , { state | patrolIndex = newIndex, currentTactical = Just PatrolRoute, currentOperational = Nothing }
        , False
        )

handleOperationalCheckCircleComplete : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalCheckCircleComplete context state =
    -- Action: CheckCounter
    -- Circle complete, move to next building in patrol
    ( context.unit
    , { state
        | perimeterPoints = []
        , perimeterIndex = 0
        , currentOperational = Just IncrementPatrolIndex
      }
    , False
    )

handleOperationalFindCastle : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalFindCastle context state =
    -- Action: FindBuildingByType
    -- Success: Castle found
    case context.unit.homeBuilding of
        Just homeBuildingId ->
            case List.filter (\b -> b.id == homeBuildingId) context.buildings |> List.head of
                Just castle ->
                    let
                        unit = context.unit
                        buildGridSize = 64
                        -- Get castle entrance (outside the building)
                        ( entranceGridX, entranceGridY ) = getBuildingEntrance castle
                        -- Target cell just outside the entrance
                        targetWorldX = toFloat entranceGridX * toFloat buildGridSize + toFloat buildGridSize / 2
                        targetWorldY = (toFloat entranceGridY + 1) * toFloat buildGridSize + toFloat buildGridSize / 2
                        targetCellX = floor (targetWorldX / 32)
                        targetCellY = floor (targetWorldY / 32)
                        updatedUnit = { unit | targetDestination = Just ( targetCellX, targetCellY ) }
                        _ = Debug.log "[CG] SetTarget (return home)"
                            { castleId = castle.id
                            , entrance = ( entranceGridX, entranceGridY )
                            , targetCell = ( targetCellX, targetCellY )
                            , needsPath = True
                            }
                    in
                    ( updatedUnit
                    , { state | currentOperational = Just MoveToBuilding }
                    , True
                    )

                Nothing ->
                    -- Castle destroyed
                    ( context.unit
                    , { state | currentStrategic = WithoutHome, currentTactical = Nothing, currentOperational = Nothing }
                    , False
                    )

        Nothing ->
            -- No home building
            ( context.unit
            , { state | currentStrategic = WithoutHome, currentTactical = Nothing, currentOperational = Nothing }
            , False
            )

handleOperationalMoveToMonster : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalMoveToMonster context state =
    -- Action: FollowPath
    -- Success: Within melee range of monster
    -- STUB: Monster system does not exist yet
    -- TODO: Implement when monster system exists
    -- Should use MoveToMonster action to path to engaged monster
    -- For now, pretend we instantly defeated the monster
    ( context.unit
    , { state | currentTactical = Just ResumePatrol, currentOperational = Nothing }
    , False
    )

handleOperationalAttackMonster : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalAttackMonster context state =
    -- Action: MeleeAttack
    -- Success: Monster HP reduced
    -- STUB: Monster system does not exist yet
    -- TODO: Implement when monster system exists
    -- Should use AttackMonster action to deal damage
    ( context.unit
    , { state | currentTactical = Just ResumePatrol, currentOperational = Nothing }
    , False
    )

handleOperationalCheckMonsterDefeated : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalCheckMonsterDefeated context state =
    -- Action: CheckUnitHP
    -- STUB: Monster system does not exist yet
    -- TODO: Implement when monster system exists
    -- Should check if engaged monster's HP <= 0
    ( context.unit
    , { state | currentTactical = Just ResumePatrol, currentOperational = Nothing }
    , False
    )

handleOperationalExitGarrison : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalExitGarrison context state =
    -- Action: NoAction
    -- Success: Now on map at castle entrance
    case context.unit.homeBuilding of
        Just homeBuildingId ->
            case List.filter (\b -> b.id == homeBuildingId) context.buildings |> List.head of
                Just homeBuilding ->
                    let
                        ( updatedUnit, result, needsPath ) =
                            Actions.executeOperationalAction context BT.ExitGarrison
                    in
                    case result of
                        Success ->
                            ( updatedUnit
                            , { state | currentTactical = Just PlanPatrolRoute, currentOperational = Nothing }
                            , False
                            )

                        _ ->
                            ( updatedUnit, state, needsPath )

                Nothing ->
                    -- Castle destroyed
                    ( context.unit
                    , { state | currentStrategic = WithoutHome, currentTactical = Nothing, currentOperational = Nothing }
                    , False
                    )

        Nothing ->
            -- No home building
            ( context.unit
            , { state | currentStrategic = WithoutHome, currentTactical = Nothing, currentOperational = Nothing }
            , False
            )

handleOperationalEnterGarrison : BehaviorContext -> CastleGuardPatrolState -> ( Unit, CastleGuardPatrolState, Bool )
handleOperationalEnterGarrison context state =
    -- Action: NoAction
    -- Success: Now garrisoned in castle
    let
        ( updatedUnit, result, needsPath ) = Actions.executeOperationalAction context BT.EnterGarrison
    in
    case result of
        Success ->
            ( updatedUnit
            , { state | currentTactical = Just RestInGarrison, currentOperational = Nothing }
            , False
            )

        HomeDestroyed ->
            ( updatedUnit
            , { state | currentStrategic = WithoutHome, currentTactical = Nothing, currentOperational = Nothing }
            , False
            )

        NotArrived ->
            ( updatedUnit, state, True )

        _ ->
            ( updatedUnit, state, needsPath )


-- AWARENESS FUNCTIONS

checkActiveAwarenessCastleGuardPatrol : BehaviorContext -> CastleGuardPatrolState -> Maybe CastleGuardActiveAwarenessTrigger
checkActiveAwarenessCastleGuardPatrol context state =
    -- Active awareness types: WatchForMonsters
    if checkWatchForMonsters context then
        Just
            { awarenessType = "WatchForMonsters"
            , forcedTactical = EngageMonster
            , priorityLevel = 5  -- Critical
            }
    else
        Nothing


checkWatchForMonsters : BehaviorContext -> Bool
checkWatchForMonsters context =
    -- Continuously scan for enemy units
    -- Trigger: Enemy unit within search radius (384 pixels)
    -- STUB: Monsters don't exist in game yet
    -- TODO: Implement when monster system exists
    -- Should scan context.units for enemy units within searchRadius
    -- Example implementation:
    --   case context.unit.location of
    --       OnMap x y ->
    --           context.units
    --               |> List.filter (\u -> u.owner == Enemy)
    --               |> List.any (\enemy ->
    --                   case enemy.location of
    --                       OnMap ex ey ->
    --                           let dist = sqrt ((x - ex)^2 + (y - ey)^2)
    --                           in dist < 384
    --                       _ -> False
    --               )
    --       _ -> False
    False


handleInterruptCastleGuardPatrol : CastleGuardPatrolState -> CastleGuardActiveAwarenessTrigger -> ( CastleGuardPatrolState, Bool )
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
