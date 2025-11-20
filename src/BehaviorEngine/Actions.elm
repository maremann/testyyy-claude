module BehaviorEngine.Actions exposing
    ( executeOperationalAction
    , updatePassiveAwareness
    , checkActiveAwareness
    )

import BehaviorEngine.Types exposing (..)
import GameHelpers exposing (exitGarrison, findNearestDamagedBuilding)
import GameStrings
import Grid exposing (getBuildingEntrance)
import Types exposing (..)


-- EXECUTE OPERATIONAL ACTIONS

executeOperationalAction : BehaviorContext -> OperationalAction -> ( Unit, ActionResult, Bool )
executeOperationalAction context action =
    case action of
        NoAction ->
            ( context.unit, NoResult, False )

        Sleep ->
            executeSleep context

        WaitFor duration ->
            ( context.unit, if context.unit.behaviorTimer >= duration then TimerExpired else NoResult, False )

        ExitGarrison ->
            executeExitGarrison context

        EnterGarrison ->
            executeEnterGarrison context

        FollowPath ->
            executeFollowPath context

        FindNearestDamagedBuilding ->
            executeFindNearestDamagedBuilding context

        FindBuildingWithGold ->
            executeFindBuildingWithGold context

        FindHomeBuilding ->
            executeFindHomeBuilding context

        FindCastle ->
            executeFindCastle context

        CheckArrival ->
            executeCheckArrival context

        RepairBuilding buildingId ->
            executeRepairBuilding context buildingId

        CollectGoldFrom buildingId ->
            executeCollectGold context buildingId

        DepositGold ->
            executeDepositGold context

        AttackUnit unitId ->
            executeAttackUnit context unitId

        PatrolArea ->
            executePatrolArea context


-- ACTION IMPLEMENTATIONS

executeSleep : BehaviorContext -> ( Unit, ActionResult, Bool )
executeSleep context =
    let
        unit = context.unit
        healAmount = toFloat unit.maxHp * 0.1 * context.deltaSeconds
        newHp = min unit.maxHp (unit.hp + round healAmount)
        updatedUnit = { unit | hp = newHp }
        isFullyHealed = newHp >= unit.maxHp
    in
    ( updatedUnit
    , if isFullyHealed then Success else NoResult
    , False
    )


executeExitGarrison : BehaviorContext -> ( Unit, ActionResult, Bool )
executeExitGarrison context =
    case context.unit.homeBuilding of
        Nothing ->
            ( context.unit, Failure "No home building", False )

        Just homeBuildingId ->
            case List.filter (\b -> b.id == homeBuildingId) context.buildings |> List.head of
                Nothing ->
                    ( context.unit, HomeDestroyed, False )

                Just homeBuilding ->
                    let
                        exitedUnit = exitGarrison homeBuilding context.unit
                    in
                    ( exitedUnit, Success, False )


executeEnterGarrison : BehaviorContext -> ( Unit, ActionResult, Bool )
executeEnterGarrison context =
    case context.unit.homeBuilding of
        Nothing ->
            ( context.unit, Failure "No home building", False )

        Just homeBuildingId ->
            case List.filter (\b -> b.id == homeBuildingId) context.buildings |> List.head of
                Nothing ->
                    ( context.unit, HomeDestroyed, False )

                Just homeBuilding ->
                    case context.unit.location of
                        OnMap x y ->
                            let
                                ( entranceGridX, entranceGridY ) = getBuildingEntrance homeBuilding
                                buildGridSize = 64
                                exitGridX = entranceGridX
                                exitGridY = entranceGridY + 1
                                exitX = toFloat exitGridX * toFloat buildGridSize + toFloat buildGridSize / 2
                                exitY = toFloat exitGridY * toFloat buildGridSize + toFloat buildGridSize / 2
                                dx = x - exitX
                                dy = y - exitY
                                distance = sqrt (dx * dx + dy * dy)
                                isAtEntrance = distance < 32
                            in
                            if isAtEntrance then
                                let
                                    unit = context.unit
                                in
                                ( { unit | location = Garrisoned homeBuildingId }
                                , Success
                                , False
                                )
                            else
                                let
                                    unit = context.unit
                                    targetCellX = floor (exitX / 32)
                                    targetCellY = floor (exitY / 32)
                                in
                                ( { unit | targetDestination = Just ( targetCellX, targetCellY ) }
                                , NotArrived
                                , True
                                )

                        Garrisoned _ ->
                            ( context.unit, Success, False )


executeFollowPath : BehaviorContext -> ( Unit, ActionResult, Bool )
executeFollowPath context =
    -- Path following is handled by simulation loop
    -- This just checks if we've arrived
    let
        unit = context.unit
    in
    case unit.targetDestination of
        Nothing ->
            ( unit, PathComplete, False )

        Just _ ->
            if List.isEmpty unit.path then
                ( { unit | targetDestination = Nothing }, PathComplete, False )
            else
                ( unit, NoResult, False )


executeFindNearestDamagedBuilding : BehaviorContext -> ( Unit, ActionResult, Bool )
executeFindNearestDamagedBuilding context =
    case context.unit.location of
        OnMap x y ->
            case findNearestDamagedBuilding x y context.buildings of
                Just building ->
                    let
                        unit = context.unit
                        buildGridSize = 64
                        targetX = toFloat building.gridX * toFloat buildGridSize + (toFloat (buildingSizeToGridCells building.size) * toFloat buildGridSize / 2)
                        targetY = toFloat building.gridY * toFloat buildGridSize + (toFloat (buildingSizeToGridCells building.size) * toFloat buildGridSize / 2)
                        targetCellX = floor (targetX / 32)
                        targetCellY = floor (targetY / 32)
                    in
                    ( { unit | targetDestination = Just ( targetCellX, targetCellY ) }
                    , BuildingFound building.id
                    , True
                    )

                Nothing ->
                    ( context.unit, NoBuildingFound, False )

        Garrisoned _ ->
            ( context.unit, Failure "Cannot search while garrisoned", False )


executeFindBuildingWithGold : BehaviorContext -> ( Unit, ActionResult, Bool )
executeFindBuildingWithGold context =
    case context.unit.location of
        OnMap x y ->
            let
                buildingsWithGold = List.filter (\b -> b.coffer > 0) context.buildings
                findNearest = buildingsWithGold
                    |> List.map (\b ->
                        let
                            buildGridSize = 64
                            bx = toFloat b.gridX * toFloat buildGridSize + (toFloat (buildingSizeToGridCells b.size) * toFloat buildGridSize / 2)
                            by = toFloat b.gridY * toFloat buildGridSize + (toFloat (buildingSizeToGridCells b.size) * toFloat buildGridSize / 2)
                            dist = sqrt ((x - bx) ^ 2 + (y - by) ^ 2)
                        in
                        ( b, dist )
                    )
                    |> List.sortBy Tuple.second
                    |> List.head
                    |> Maybe.map Tuple.first
            in
            case findNearest of
                Just building ->
                    let
                        unit = context.unit
                        buildGridSize = 64
                        targetX = toFloat building.gridX * toFloat buildGridSize + (toFloat (buildingSizeToGridCells building.size) * toFloat buildGridSize / 2)
                        targetY = toFloat building.gridY * toFloat buildGridSize + (toFloat (buildingSizeToGridCells building.size) * toFloat buildGridSize / 2)
                        targetCellX = floor (targetX / 32)
                        targetCellY = floor (targetY / 32)
                    in
                    ( { unit | targetDestination = Just ( targetCellX, targetCellY ) }
                    , BuildingFound building.id
                    , True
                    )

                Nothing ->
                    ( context.unit, NoBuildingFound, False )

        Garrisoned _ ->
            ( context.unit, Failure "Cannot search while garrisoned", False )


executeFindHomeBuilding : BehaviorContext -> ( Unit, ActionResult, Bool )
executeFindHomeBuilding context =
    case context.unit.homeBuilding of
        Nothing ->
            ( context.unit, HomeDestroyed, False )

        Just homeBuildingId ->
            case List.filter (\b -> b.id == homeBuildingId) context.buildings |> List.head of
                Nothing ->
                    ( context.unit, HomeDestroyed, False )

                Just _ ->
                    ( context.unit, HomeExists, False )


executeFindCastle : BehaviorContext -> ( Unit, ActionResult, Bool )
executeFindCastle context =
    case context.unit.location of
        OnMap x y ->
            let
                castle = context.buildings
                    |> List.filter (\b -> b.buildingType == GameStrings.buildingTypeCastle && b.owner == Player)
                    |> List.head
            in
            case castle of
                Just building ->
                    let
                        unit = context.unit
                        buildGridSize = 64
                        targetX = toFloat building.gridX * toFloat buildGridSize + (toFloat (buildingSizeToGridCells building.size) * toFloat buildGridSize / 2)
                        targetY = toFloat building.gridY * toFloat buildGridSize + (toFloat (buildingSizeToGridCells building.size) * toFloat buildGridSize / 2)
                        targetCellX = floor (targetX / 32)
                        targetCellY = floor (targetY / 32)
                    in
                    ( { unit | targetDestination = Just ( targetCellX, targetCellY ) }
                    , BuildingFound building.id
                    , True
                    )

                Nothing ->
                    ( context.unit, NoBuildingFound, False )

        Garrisoned _ ->
            ( context.unit, Failure "Cannot search while garrisoned", False )


executeCheckArrival : BehaviorContext -> ( Unit, ActionResult, Bool )
executeCheckArrival context =
    case context.unit.location of
        OnMap x y ->
            case context.unit.targetDestination of
                Nothing ->
                    ( context.unit, Arrived, False )

                Just ( targetX, targetY ) ->
                    let
                        targetWorldX = toFloat targetX * 32 + 16
                        targetWorldY = toFloat targetY * 32 + 16
                        dx = x - targetWorldX
                        dy = y - targetWorldY
                        distance = sqrt (dx * dx + dy * dy)
                        unit = context.unit
                    in
                    if distance < 32 then
                        ( { unit | targetDestination = Nothing, path = [] }
                        , Arrived
                        , False
                        )
                    else
                        ( unit, NotArrived, False )

        Garrisoned _ ->
            ( context.unit, Arrived, False )


executeRepairBuilding : BehaviorContext -> Int -> ( Unit, ActionResult, Bool )
executeRepairBuilding context buildingId =
    -- Repairing is handled by simulation loop
    -- This just reports progress
    ( context.unit, RepairInProgress, False )


executeCollectGold : BehaviorContext -> Int -> ( Unit, ActionResult, Bool )
executeCollectGold context buildingId =
    -- Gold collection handled by simulation
    ( context.unit, NoResult, False )


executeDepositGold : BehaviorContext -> ( Unit, ActionResult, Bool )
executeDepositGold context =
    -- Gold deposit handled by simulation
    ( context.unit, NoResult, False )


executeAttackUnit : BehaviorContext -> Int -> ( Unit, ActionResult, Bool )
executeAttackUnit context targetId =
    -- Combat not implemented yet
    ( context.unit, NoResult, False )


executePatrolArea : BehaviorContext -> ( Unit, ActionResult, Bool )
executePatrolArea context =
    -- Patrolling not implemented yet
    ( context.unit, NoResult, False )


-- PASSIVE AWARENESS

updatePassiveAwareness : BehaviorContext -> PassiveAwarenessData
updatePassiveAwareness context =
    let
        unit = context.unit
        ( unitX, unitY ) =
            case unit.location of
                OnMap x y -> ( x, y )
                Garrisoned _ -> ( 0, 0 )

        -- Find damaged buildings
        damagedBuildings =
            context.buildings
                |> List.filter (\b -> b.hp < b.maxHp)
                |> List.map .id

        -- Find buildings with gold
        buildingsWithGold =
            context.buildings
                |> List.filter (\b -> b.coffer > 0)
                |> List.map .id

        -- Threat detection (placeholder - no enemies yet)
        threatLevel = NoThreat

    in
    { nearestEnemy = Nothing
    , enemyDistance = Nothing
    , threatLevel = threatLevel
    , nearestLoot = Nothing
    , nearbyAllies = []
    , damagedBuildings = damagedBuildings
    , buildingsWithGold = buildingsWithGold
    }


-- ACTIVE AWARENESS

checkActiveAwareness : BehaviorContext -> Maybe ActiveTrigger
checkActiveAwareness context =
    let
        unit = context.unit

        -- Critical health check
        criticalHealthTrigger =
            if toFloat unit.hp < (toFloat unit.maxHp * 0.2) then
                Just
                    { triggerType = MonitorCriticalHealth
                    , forcedBehavior = FleeToSafety
                    , priority = Critical
                    }
            else
                Nothing

        -- Home destroyed check
        homeDestroyedTrigger =
            case unit.homeBuilding of
                Nothing ->
                    Nothing

                Just homeBuildingId ->
                    let
                        homeExists = context.buildings
                            |> List.any (\b -> b.id == homeBuildingId)
                    in
                    if not homeExists then
                        Just
                            { triggerType = CheckHomeBuildingExists
                            , forcedBehavior = TacticalNoAction  -- Will become WithoutHome
                            , priority = Critical
                            }
                    else
                        Nothing
    in
    -- Return first triggered awareness (priority: health > home)
    case criticalHealthTrigger of
        Just trigger -> Just trigger
        Nothing -> homeDestroyedTrigger
