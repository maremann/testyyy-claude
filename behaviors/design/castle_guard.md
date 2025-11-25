# Castle Guard Behavior

**Behavior ID**: castle_guard_patrol
**Unit Type**: Castle Guard
**Inherits**: CORE_BEHAVIORS

## Description

Castle Guards protect the kingdom by patrolling between buildings and engaging monsters on sight. They follow a patrol route visiting 1-3 buildings, circle each one, then return to the castle to rest. Combat always takes priority - if a monster is spotted, the guard immediately engages until victory or death.

## Strategic Behaviors

### DefendTerritory
- **Priority**: Normal
- **Tactical Delegates**:
  1. EngageMonster (if monster detected via active awareness)
  2. PatrolRoute (if healthy and patrol active)
  3. ReturnToCastle (if patrol complete or HP < 100%)
- **Awareness**: WatchForMonsters (active)
- **Transitions**:
  - If home destroyed → WithoutHome (handled by active awareness)
- **Notes**: Castle Guards fight to the death - MonitorCriticalHealth awareness is disabled

### RestInGarrison (from CORE)
- **Priority**: Background
- **Delegates to**: Sleeping
- **Awareness**: CheckHomeExists (active)

---

## Tactical Behaviors

### RestInGarrison (Initial State)
- **Description**: Sleep in castle garrison for minimum rest period
- **Priority**: Background
- **Operational Sequence**:
  1. Sleep (duration: 5 seconds minimum)
  2. PlanPatrolRoute
  3. ExitGarrison
- **Success**: timer >= 5s
- **Transitions**:
  - Success → PatrolRoute

---

### PlanPatrolRoute
- **Description**: Select 1-3 kingdom buildings to patrol
- **Priority**: Normal
- **Operational Sequence**:
  1. SelectPatrolBuildings (1-3 buildings, prioritize damaged/distant)
  2. SetPatrolIndex (start at 0)
- **Success**: Patrol route with 1-3 buildings created
- **Failure**: No buildings available
- **Transitions**:
  - Success → PatrolRoute
  - Failure → ReturnToCastle

---

### PatrolRoute
- **Description**: Visit each building in patrol route sequentially
- **Priority**: Normal
- **Operational Sequence**:
  1. GetCurrentPatrolTarget (building at patrolIndex)
  2. MoveToBuilding (target building)
  3. CircleBuilding (target building)
  4. IncrementPatrolIndex
  5. If more buildings in route → Repeat from step 1
  6. If route complete → ReturnToCastle
- **Awareness**: WatchForMonsters (active), ScanForDamage (passive)
- **Success**: All buildings in patrol route visited
- **Failure**: Patrol target building destroyed
- **Interrupts**:
  - If monster detected → EngageMonster (via active awareness)
- **Transitions**:
  - Success → ReturnToCastle
  - Failure → PlanPatrolRoute (replan)
  - Interrupted → EngageMonster

---

### CircleBuilding
- **Description**: Walk around target building perimeter using random waypoints
- **Priority**: Normal
- **Operational Sequence**:
  1. GenerateRandomPerimeterWaypoint (pick random point around building)
  2. MoveToPerimeterPoint (travel to waypoint)
  3. Repeat until 2 waypoints visited
  4. CheckCircleComplete
- **Duration**: Until 2 perimeter waypoints visited
- **Success**: Circle patrol completed (2 waypoints)
- **Failure**: Building destroyed mid-circle
- **Transitions**:
  - Success → PatrolRoute (advance to next building)
  - Failure → PatrolRoute (skip this building)

---

### EngageMonster
- **Description**: Attack detected monster until defeated or guard dies
- **Priority**: Critical (interrupt-capable)
- **Operational Sequence**:
  1. MoveToMonster (close to melee range)
  2. AttackMonster (continuous attacks)
  3. CheckMonsterDefeated
  4. If defeated → ResumePatrol
  5. If not defeated → Repeat from step 1
- **Awareness**: TrackMonsterDistance (passive)
- **Success**: Monster defeated
- **Failure**: Guard HP reaches 0
- **Interrupts**: None - Castle Guards never flee, fight to the death
- **Transitions**:
  - Success → ResumePatrol (return to patrol state before interrupt)
  - Failure → Dead

---

### ResumePatrol
- **Description**: Return to patrol after combat or interruption
- **Priority**: Normal
- **Operational Sequence**:
  1. CheckPatrolState (do we still have a patrol route?)
  2. If patrol route exists → PatrolRoute (resume at current index)
  3. If no patrol route → PlanPatrolRoute (start fresh)
- **Success**: Always succeeds
- **Transitions**:
  - If patrol route exists → PatrolRoute
  - If no route → PlanPatrolRoute

---

### ReturnToCastle
- **Description**: Travel back to castle to rest
- **Priority**: Normal
- **Operational Sequence**:
  1. FindCastle
  2. MoveToBuilding (castle)
  3. EnterGarrison
- **Success**: Entered castle garrison
- **Failure**: Castle destroyed
- **Transitions**:
  - Success → RestInGarrison
  - Failure → WithoutHome

---

## Operational Behaviors

### Sleep (from CORE)
- **Duration**: 5 seconds minimum (always)
- **Action**: Sleep (heals 10% maxHP per second)
- **Success**: timer >= 5s

---

### SelectPatrolBuildings
- **Description**: Choose 1-3 kingdom buildings to patrol
- **Action**: FindPlayerBuildings
- **Parameters**:
  - Min buildings: 1
  - Max buildings: 3
  - Exclude: Castle (home building)
- **Selection Logic**:
  1. Get all player-owned buildings except castle
  2. Prioritize damaged buildings (HP < maxHP)
  3. Prefer distant buildings (farther from castle)
  4. Randomize selection to avoid patterns
  5. Store as patrol route array
- **Success**: 1-3 buildings selected
- **Failure**: No buildings available (only castle exists)
- **Result**:
  - BuildingsSelected [id1, id2, id3]
  - NoBuildingsAvailable

---

### GetCurrentPatrolTarget
- **Description**: Retrieve building at current patrol index
- **Action**: LookupPatrolRoute
- **Parameters**: patrolIndex (current position in route)
- **Success**: Building exists at index
- **Failure**: Index out of bounds
- **Result**:
  - BuildingFound buildingId
  - PatrolComplete (no more buildings)

---

### MoveToBuilding
- **Description**: Travel to target building entrance
- **Action**: FollowPath
- **Parameters**: targetBuildingId
- **Success**: Within 32 pixels of building
- **Failure**: Path blocked, timeout (30s)
- **Side Effects**: Sets targetDestination, requests pathfinding

---

### CirclePerimeter
- **Description**: Walk around building perimeter using random waypoints
- **Action**: FollowPerimeterPath
- **Parameters**:
  - buildingId: Target building
  - perimeterIndex: Current waypoint count (0-1)
- **Waypoint Calculation**:
  ```
  Building center: (centerX, centerY)
  Building size: size (in grid cells)
  Radius: (size * gridSize / 2) + 64 pixels (distance from building)

  Random angle calculation (deterministic):
  angle = (perimeterIndex * 73 + unit.id * 137) * 0.1

  Waypoint position:
  waypointX = centerX + radius * cos(angle)
  waypointY = centerY + radius * sin(angle)
  ```
- **Duration**: Until 2 waypoints visited
- **Success**: Visited 2 perimeter waypoints
- **Failure**: Building destroyed
- **Result**:
  - Arrived (at current waypoint, advance to next)
  - CircleComplete (2 waypoints visited)
  - BuildingDestroyed

---

### IncrementPatrolIndex
- **Description**: Advance to next building in patrol route
- **Action**: IncrementCounter
- **Side Effects**: patrolIndex += 1
- **Result**:
  - Success (more buildings remain)
  - PatrolComplete (all buildings visited)

---

### CheckCircleComplete
- **Description**: Verify if perimeter patrol completed
- **Action**: CheckCounter
- **Parameters**: perimeterIndex (0-1)
- **Result**:
  - CircleComplete (index >= 2)
  - ContinueCircle (index < 2)

---

### FindCastle
- **Description**: Locate player's castle building
- **Action**: FindBuildingByType
- **Parameters**: buildingType = "Castle", owner = Player
- **Success**: Castle found
- **Failure**: Castle destroyed
- **Result**:
  - BuildingFound castleId
  - NoBuildingFound (castle destroyed)
- **Side Effects**: Sets targetDestination to castle

---

### MoveToMonster
- **Description**: Approach monster to melee range
- **Action**: FollowPath
- **Parameters**:
  - targetMonsterId
  - desiredDistance: 16 pixels (melee range)
- **Success**: Within melee range of monster
- **Failure**: Monster disappeared, path blocked
- **Result**:
  - Arrived (in melee range)
  - TargetLost (monster no longer exists)

---

### AttackMonster
- **Description**: Deal damage to monster in melee range
- **Action**: MeleeAttack
- **Parameters**:
  - targetMonsterId
  - damagePerHit: 10 HP
  - attackSpeed: 1.0 seconds per attack
- **Duration**: 1.0 second per attack cycle
- **Success**: Monster HP reduced
- **Failure**: Monster out of range, monster dead
- **Result**:
  - MonsterDamaged (still alive)
  - MonsterDefeated (HP <= 0)
  - MonsterOutOfRange (need to move closer)
- **Side Effects**: Reduces monster HP by 10 every 1.0s

---

### CheckMonsterDefeated
- **Description**: Verify if monster is dead
- **Action**: CheckUnitHP
- **Parameters**: monsterId
- **Result**:
  - MonsterDefeated (HP <= 0 or doesn't exist)
  - MonsterAlive (HP > 0)

---

### ExitGarrison (from CORE)
- **Description**: Leave castle garrison onto map
- **Success**: Now on map at castle entrance

---

### EnterGarrison (from CORE)
- **Description**: Enter castle garrison
- **Success**: Now garrisoned in castle

---

## Awareness System

### Active Awareness (Can Interrupt)

#### WatchForMonsters
- **Type**: Active
- **Description**: Continuously scan for enemy units
- **Scan Radius**: unit.searchRadius (384 pixels)
- **Frequency**: Every frame
- **Trigger Condition**: Enemy unit within search radius
- **Forced Behavior**: EngageMonster
- **Priority**: Critical
- **Stores**:
  - nearestMonster: Maybe UnitId
  - monsterDistance: Float
- **Interrupts**: Any behavior with priority < Critical
- **Action**: When monster detected, immediately switch to EngageMonster tactical

#### CheckHomeExists (from CORE)
- **Type**: Active
- **Trigger**: Castle destroyed
- **Forced Behavior**: WithoutHome
- **Priority**: Critical

### Passive Awareness (Influences Next Decision)

#### ScanForDamage
- **Type**: Passive
- **Description**: Notice damaged buildings during patrol
- **Stores**: List of buildings with HP < maxHP
- **Influences**: Building selection for patrol route (prioritize damaged)

#### TrackMonsterDistance
- **Type**: Passive
- **Description**: Monitor distance to engaged monster
- **Stores**: Current monster distance
- **Influences**: MoveToMonster behavior (stay in melee range)

---

## State Transitions Diagram

```
[Spawned in Castle]
    ↓
Sleeping (RestInGarrison)
    ↓ (5s minimum)
PlanPatrolRoute (select 1-3 buildings)
    ↓
ExitGarrison
    ↓
PatrolRoute ←─────────────────┐
    ↓                          │
GetCurrentPatrolTarget         │
    ↓                          │
MoveToBuilding                 │
    ↓                          │
CircleBuilding (2 waypoints)   │
    ↓                          │
More buildings? ───YES─────────┘
    │
    NO
    ↓
ReturnToCastle
    ↓
EnterGarrison
    ↓
Sleeping (loop back to top)

INTERRUPT PATH (any time during patrol):
Monster Detected! (Active Awareness)
    ↓
EngageMonster (Critical Priority)
    ↓
MoveToMonster
    ↓
AttackMonster (loop until victory)
    ↓
CheckMonsterDefeated
    ↓ (victory)
ResumePatrol (return to patrol state)
    ↓
Continue PatrolRoute at current index
```

---

## Priority Assignments

| Behavior | Priority | Can Be Interrupted By |
|----------|----------|-----------------------|
| EngageMonster | Critical | Home destroyed only (WithoutHome) |
| PatrolRoute | Normal | Critical behaviors (EngageMonster) |
| CircleBuilding | Normal | Critical behaviors (EngageMonster) |
| ReturnToCastle | Normal | Critical behaviors (EngageMonster) |
| RestInGarrison | Background | All higher priorities |

**Note**: Castle Guards have no flee behavior - they fight to the death.

---

## Unit State Data

Castle Guards need these additional state fields:

```elm
type alias CastleGuardState =
    { patrolRoute : List Int  -- Building IDs to patrol
    , patrolIndex : Int        -- Current position in route (0-2)
    , perimeterIndex : Int     -- Current waypoint count (0-1)
    , engagedMonster : Maybe Int  -- Monster currently fighting
    , patrolStateBeforeInterrupt : Maybe PatrolInterruptState  -- For resuming
    }

type alias PatrolInterruptState =
    { wasInPatrolRoute : Bool
    , patrolRouteAtInterrupt : List Int
    , patrolIndexAtInterrupt : Int
    , wasCirclingBuilding : Bool
    , perimeterIndexAtInterrupt : Int
    }
```

---

## Example Scenario

**Initial State**: Guard spawns in castle
1. **Sleeping** (5 seconds) → Heals while resting
2. **PlanPatrolRoute** → Selects: [House #5, Warriors Guild #12, House #9]
3. **ExitGarrison** → Appears at castle entrance
4. **PatrolRoute begins**:
   - **GetCurrentPatrolTarget** → House #5
   - **MoveToBuilding** → Paths to House #5
   - **CircleBuilding** → Walks perimeter (2 random waypoints)
   - **IncrementPatrolIndex** → patrolIndex = 1
   - **GetCurrentPatrolTarget** → Warriors Guild #12
   - **MoveToBuilding** → Halfway there...
   - **MONSTER DETECTED!** (Active Awareness triggers)
5. **EngageMonster** (interrupt):
   - Stores patrol state: {patrolRoute, patrolIndex: 1}
   - **MoveToMonster** → Chase monster
   - **AttackMonster** → Deal damage (loop)
   - **CheckMonsterDefeated** → Victory!
6. **ResumePatrol**:
   - Restore: patrolIndex = 1, target = Warriors Guild #12
   - **MoveToBuilding** → Resume path to Warriors Guild
   - **CircleBuilding** → Complete circle (2 waypoints)
   - **IncrementPatrolIndex** → patrolIndex = 2
   - **GetCurrentPatrolTarget** → House #9
   - **MoveToBuilding** → Path to House #9
   - **CircleBuilding** → Complete circle (2 waypoints)
   - **PatrolComplete** → All buildings visited
7. **ReturnToCastle** → Path back to castle
8. **EnterGarrison** → Back in garrison
9. **Sleeping** → Heals any damage, rest 5s minimum
10. Loop back to step 2 (plan new patrol)

---

## Testing Checklist

- [ ] Guard spawns in castle garrison
- [ ] Guard sleeps until healed or 5s timeout
- [ ] Guard plans patrol route with 1-3 buildings
- [ ] Guard exits garrison successfully
- [ ] Guard paths to first building
- [ ] Guard circles building (2 random perimeter waypoints)
- [ ] Guard advances to next building in route
- [ ] Guard completes full patrol route
- [ ] Guard returns to castle after patrol
- [ ] Guard enters garrison and sleeps
- [ ] Guard detects monster during patrol (active awareness)
- [ ] Guard interrupts patrol to engage monster
- [ ] Guard attacks monster until defeated or guard dies
- [ ] Guard resumes patrol after combat victory
- [ ] Guard fights to death (no fleeing at low HP)
- [ ] Guard becomes WithoutHome if castle destroyed
- [ ] Patrol route adjusts if patrolled building is destroyed

---

## Design Notes

**Why 1-3 buildings?**
- Too few: patrol is boring, repetitive
- Too many: takes forever to complete cycle
- 1-3: Good variety while keeping patrol duration reasonable

**Why circle buildings?**
- Visual feedback: player sees guard is "guarding"
- Tactical: covers multiple approaches to building
- Random waypoints: prevents completely predictable patterns
- 2 waypoints: Quick patrol without being too brief

**Why return to castle after patrol?**
- Guards need rest (healing)
- Clear patrol cycle (start/end at castle)
- Prevents guards from wandering forever

**Why immediate interrupt on monster detection?**
- Guards' primary purpose is defense
- Monster threats are urgent (Critical priority)
- Player expects guards to engage enemies on sight

**Why resume patrol after combat?**
- Completing the patrol feels better than abandoning it
- Guards don't get stuck in one location
- Provides post-combat purpose

**Monster detection range = searchRadius (384px)?**
- Large enough to spot threats before they reach buildings
- Small enough that guard doesn't chase distant monsters
- Matches other unit awareness ranges for consistency
