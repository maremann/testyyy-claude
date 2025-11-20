# Core Behavior System Architecture

**Version**: 2.0 - Hierarchical, Priority-Based, Goal-Driven
**Purpose**: Define the foundational behavior architecture for all units

## System Overview

The behavior system has **four layers** working together:

```
┌─────────────────────────────────────────┐
│  GOALS (persistent objectives)          │  ← Influence utility scores
│  "Upgrade sword", "Build 10 houses"     │
└─────────────────────────────────────────┘
           ↓ modifies utility
┌─────────────────────────────────────────┐
│  STRATEGIC (coordinator-level)           │  ← "What's the overall plan?"
│  "Defend Territory", "Build Economy"     │
└─────────────────────────────────────────┘
           ↓ delegates to
┌─────────────────────────────────────────┐
│  TACTICAL (mid-level goals)              │  ← "What am I doing now?"
│  "Collect Taxes", "Hunt Monster"         │
└─────────────────────────────────────────┘
           ↓ delegates to
┌─────────────────────────────────────────┐
│  OPERATIONAL (immediate actions)         │  ← "What's my next step?"
│  "Move to X", "Attack Y", "Collect Gold" │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  AWARENESS (parallel passive channel)    │  ← "What do I notice?"
│  "Enemy nearby?", "Loot on ground?"      │
└─────────────────────────────────────────┘
```

### Key Principles

1. **Behavior Trees**: Strategic behaviors delegate to tactical, tactical delegate to operational
2. **Priority Interrupts**: High priority behaviors **immediately replace** low priority (no resume)
3. **Hybrid Awareness**: Two types of awareness running in parallel
   - **Passive**: Observes environment, influences next decision (no interrupt)
   - **Active**: Detects critical triggers, can force immediate interrupt
4. **Goal-Driven Utility**: Goals modify behavior utility scores indirectly

---

## Layer 1: Goals (Persistent Objectives)

### What Are Goals?

Goals are **persistent state** that represent long-term objectives. They don't directly control behavior but influence which behaviors are selected.

### Goal Structure

```markdown
### Goal: UpgradeSword

- **Description**: Save gold to purchase better sword
- **Target**: 1000 gold accumulated
- **Progress**: Track carried + banked gold
- **Utility Modifiers**:
  - CollectGold: +30% utility
  - VisitBlacksmith: +50% utility
  - Patrol (away from gold sources): -10% utility
- **Completion**: When sword upgraded
- **Abandonment**: If sword already max tier
```

### Common Goals

1. **Resource Goals**: "Collect 1000 gold", "Gather 50 wood"
2. **Building Goals**: "Construct 10 houses", "Repair all buildings"
3. **Combat Goals**: "Kill 20 enemies", "Defend castle for 10 minutes"
4. **Upgrade Goals**: "Upgrade sword", "Increase max HP"
5. **Exploration Goals**: "Discover entire map", "Find hidden treasure"

### Goal Lifecycle

```
Created → Active → (Progressing) → Completed
              ↓
         Abandoned (if impossible)
```

Goals persist across behavior changes. A unit "collecting taxes" can have goal "upgrade sword" - the goal influences why it collects taxes enthusiastically.

---

## Layer 2: Strategic Behaviors (Coordinator Level)

### What Are Strategic Behaviors?

Strategic behaviors represent **overall directives** from the game coordinator. They:
- Last minutes or until conditions change
- Determine high-level priorities
- Delegate to tactical behaviors
- Respond to game-wide events

### Strategic Behavior Structure

```markdown
### Strategic: DefendTerritory

- **Description**: Prioritize defending against enemy threats
- **Priority**: Critical
- **Duration**: Until threat eliminated
- **Tactical Behaviors** (in priority order):
  1. EngageEnemy (if enemy in range)
  2. PatrolPerimeter (if no immediate threat)
  3. RepairFortifications (if walls damaged)
- **Awareness**: WatchForEnemies (high vigilance)
- **Transitions**:
  - If no enemies for 60s → SwitchTo: BuildEconomy
  - If castle destroyed → SwitchTo: Retreat
```

### Common Strategic Behaviors (Units)

#### Idle (Default)
- **Priority**: Background
- **Delegates to**: RestInGarrison, LookForOpportunities
- **Description**: No coordinator directive, do low-priority tasks

#### BuildEconomy
- **Priority**: Normal
- **Delegates to**: CollectTaxes, RepairBuildings, ConstructNewBuildings
- **Description**: Peacetime economic development

#### DefendTerritory
- **Priority**: Critical
- **Delegates to**: EngageEnemy, PatrolPerimeter, RepairFortifications
- **Description**: Territory under attack, prioritize defense

#### Retreat
- **Priority**: Critical
- **Delegates to**: FleeToSafety, AvoidEnemies
- **Description**: Overwhelming threat, get to safety

#### ScoutArea
- **Priority**: Normal
- **Delegates to**: ExploreUnknown, MapTerrain
- **Description**: Exploration mission

---

## Layer 3: Tactical Behaviors (Mid-Level Goals)

### What Are Tactical Behaviors?

Tactical behaviors represent **concrete tasks** like "collect taxes" or "hunt monster". They:
- Last seconds to minutes
- Have clear success/failure conditions
- Delegate to operational behaviors
- Can be interrupted by higher priority strategic changes

### Tactical Behavior Structure

```markdown
### Tactical: CollectTaxes

- **Description**: Gather gold from buildings and return to castle
- **Priority**: Normal
- **Duration**: Until complete or interrupted
- **Operational Sequence**:
  1. LookForBuildingWithGold
  2. MoveToBuilding
  3. CollectGold
  4. MoveTowardCastle
  5. DepositGoldAtCastle
  6. Repeat (until no more buildings with gold)
- **Awareness**: WatchForThreats, ScanForLoot
- **Success**: All buildings taxed
- **Failure**: Home castle destroyed
- **Interrupts**:
  - If HP < 30% → FleeToSafety (Priority: High)
  - If enemy in range → EngageOrFlee (Priority: Critical)
```

### Common Tactical Behaviors

#### CollectTaxes
Gather gold from buildings, deposit at castle

#### RepairBuilding
Find damaged building, travel to it, repair it

#### HuntMonster
Track down and kill specific monster

#### ConstructBuilding
Travel to construction site, build structure

#### PatrolArea
Move along patrol route, observe surroundings

#### FleeToSafety
Get to nearest safe location (garrison/castle)

#### EngageEnemy
Fight nearby enemy unit

#### RestInGarrison
Sleep in home building, heal HP

---

## Layer 4: Operational Behaviors (Immediate Actions)

### What Are Operational Behaviors?

Operational behaviors are **atomic actions** - the lowest level of behavior. They:
- Last <1 second to a few seconds
- Are concrete, specific actions
- Don't delegate further
- Report success/failure to tactical layer

### Operational Behavior Structure

```markdown
### Operational: MoveToWaypoint

- **Description**: Move unit to specific coordinates
- **Duration**: Until arrival or 30s timeout
- **Action**: FollowPath
- **Parameters**:
  - targetX, targetY: Destination
  - pathfindingGrid: Occupancy grid
- **Success**: Distance to target < 32 pixels
- **Failure**: Path blocked, timeout reached
- **Side Effects**: Updates unit location each frame
```

### Common Operational Behaviors

#### Movement
- **MoveToWaypoint**: Go to specific coordinates
- **MoveToBuilding**: Go to building entrance
- **MoveToUnit**: Follow moving unit
- **Patrol**: Move along waypoint list

#### Interaction
- **CollectGold**: Extract gold from building coffer
- **DepositGold**: Transfer gold to castle treasury
- **RepairBuilding**: Add HP to nearby building
- **AttackUnit**: Deal damage to enemy unit

#### State Changes
- **EnterGarrison**: Move into building, change location to Garrisoned
- **ExitGarrison**: Leave building, spawn on map at entrance
- **Sleep**: Rest and heal (must be garrisoned)

#### Search
- **LookForBuildingWithGold**: Find nearest building with gold > 0
- **LookForDamagedBuilding**: Find nearest building with HP < maxHP
- **LookForEnemy**: Find nearest enemy unit

---

## Layer 5: Awareness (Parallel Observation Channel)

### What Is Awareness?

Awareness is a **parallel system** that continuously observes the environment. It comes in two forms:

**Passive Awareness**: Gathers information, influences next behavior selection
- Runs every frame alongside primary behavior
- Stores results in awareness state
- Modifies utility scores for next decision
- Does NOT interrupt current behavior

**Active Awareness**: Detects critical conditions, can interrupt immediately
- Monitors critical triggers (low health, high-value opportunities)
- Can trigger priority interrupts
- Acts like high-priority behaviors
- Used sparingly for true emergencies

### Awareness Types

#### Passive Awareness Structure

```markdown
### Awareness (Passive): ScanForLoot

- **Type**: Passive
- **Description**: Notice gold/items on ground along path
- **Scan Radius**: unit.activeRadius
- **Frequency**: Every frame
- **Stores**:
  - nearestLoot: Maybe Item
  - lootDistance: Float
  - lootValue: Int
- **Influences**:
  - If lootValue > 100 → Utility(CollectLoot) +30%
  - If lootValue > 500 → Utility(CollectLoot) +80%
```

**Passive Examples**:
- Notice common loot nearby → influences next decision
- Observe ally movements → affects formation behavior later
- Track building health → influences repair priority
- Monitor gold availability → affects tax collection eagerness

#### Active Awareness Structure

```markdown
### Awareness (Active): MonitorCriticalHealth

- **Type**: Active (can interrupt)
- **Description**: Immediately interrupt if HP drops critically low
- **Trigger Condition**: HP < 20% of maxHP
- **Interrupt Priority**: Critical
- **Forced Behavior**: FleeToSafety
- **Overrides**: Any behavior with priority < Critical
```

**Active Examples**:
- **Critical Health**: HP < 20% → Immediately flee to safety
- **Legendary Loot**: Ultra-rare item nearby → Interrupt to collect
- **Home Destroyed**: Home building destroyed → Immediate WithoutHome state
- **Ambush Detected**: Multiple enemies surrounding → Emergency scatter/flee
- **Mission Critical Event**: Castle under direct attack → All units defend

### Common Awareness Types

#### WatchForThreats (Passive)
- **Type**: Passive
- **Scan**: Enemy units within search radius
- **Stores**: Threat level (Low/Medium/High)
- **Influences**: Combat behavior utilities

#### MonitorCriticalHealth (Active)
- **Type**: Active
- **Trigger**: HP < 20%
- **Interrupt**: FleeToSafety (Priority: Critical)
- **Overrides**: All non-critical behaviors

#### ScanForLoot (Passive)
- **Type**: Passive
- **Scan**: Items/gold on ground
- **Stores**: Loot value and location
- **Influences**: Collection behavior utility

#### DetectLegendaryLoot (Active)
- **Type**: Active
- **Trigger**: Item value > 1000 gold AND distance < 100 pixels
- **Interrupt**: CollectLegendaryItem (Priority: High)
- **Overrides**: Normal work behaviors

#### CheckHomeBuilding (Active)
- **Type**: Active
- **Trigger**: Home building no longer exists
- **Interrupt**: WithoutHome (Priority: Critical)
- **Overrides**: All behaviors

#### ObserveAlly (Passive)
- **Type**: Passive
- **Scan**: Nearby friendly units
- **Stores**: Formation data
- **Influences**: Movement coordination (future)

---

## Priority System

### Priority Levels

```
Priority Hierarchy (highest to lowest):
┌────────────────────────────────────┐
│  CRITICAL  (flee, emergency)       │  Can interrupt anything
├────────────────────────────────────┤
│  HIGH      (combat, urgent repair) │  Can interrupt Normal and below
├────────────────────────────────────┤
│  NORMAL    (work, tasks)           │  Can interrupt Low and below
├────────────────────────────────────┤
│  LOW       (patrol, explore)       │  Can interrupt Background only
├────────────────────────────────────┤
│  BACKGROUND (idle, rest)           │  Cannot interrupt anything
└────────────────────────────────────┘
```

### Interrupt Rules (Hard Interrupts)

When a higher priority behavior activates:
1. **Current behavior is abandoned** (no stack, no resume)
2. **Higher priority behavior takes over immediately**
3. **All layers cascade**: New strategic → new tactical → new operational
4. **No state preservation**: Interrupted behavior state is lost

**Example**:
```
Unit is: Strategic(BuildEconomy) → Tactical(CollectTaxes) → Operational(MoveToBuilding)
Enemy appears!
New: Strategic(DefendTerritory) → Tactical(EngageEnemy) → Operational(AttackUnit)
Old behavior completely replaced.
```

### Priority Assignment

| Behavior Type | Typical Priority |
|---------------|------------------|
| FleeToSafety | Critical |
| EngageEnemy | Critical |
| DefendCastle | Critical |
| RepairCriticalBuilding | High |
| CollectTaxes | Normal |
| RepairBuilding | Normal |
| PatrolArea | Low |
| ExploreMap | Low |
| RestInGarrison | Background |
| Idle | Background |

---

## Execution Model

### Frame-by-Frame Execution

Each simulation frame (every 50ms):

```
1. UPDATE PASSIVE AWARENESS
   - Run passive observations (WatchForThreats, ScanForLoot)
   - Store results in awareness state
   - Update utility modifiers based on observations
   - Does NOT interrupt

2. CHECK ACTIVE AWARENESS (Critical Interrupts)
   - Evaluate active awareness triggers
   - Examples: HP < 20%, home destroyed, legendary loot detected
   - If triggered: FORCE INTERRUPT with specified priority
   - Abandon current behavior stack, switch to awareness-defined behavior
   - ⚠️ This happens BEFORE normal priority checks

3. CHECK PRIORITY INTERRUPTS
   - Evaluate if any higher-priority behavior should activate
   - Use: current priority, goals, passive awareness data
   - Calculate utilities: baseUtility × goalModifier × awarenessModifier
   - If higher priority available: abandon current, switch to new

4. UPDATE STRATEGIC BEHAVIOR
   - Strategic behavior evaluates if tactical child should change
   - Selector logic: try tactical children in priority order
   - Based on: tactical completion, conditions, awareness, goals
   - Select first applicable tactical behavior

5. UPDATE TACTICAL BEHAVIOR
   - Tactical behavior advances operational sequence
   - Check if current operational complete (success/failure)
   - If complete: start next operational in sequence
   - If sequence complete: report success to strategic
   - If failed: report failure to strategic

6. UPDATE OPERATIONAL BEHAVIOR
   - Execute atomic action (move, attack, collect, etc.)
   - Update timers (behaviorTimer += deltaSeconds)
   - Check success/failure conditions
   - Report result to tactical layer

7. APPLY RESULTS
   - Update unit position, state, HP, gold, etc.
   - Generate pathfinding requests if needed
   - Update building states (coffers, HP, etc.)
```

### Execution Order Rationale

**Why Active Awareness Before Priority Interrupts?**
- Active awareness represents **immediate physical danger** (critical health, home destroyed)
- These are non-negotiable - must interrupt regardless of goals/utility
- Example: Even if goal makes "collect legendary loot" very attractive, critical health should always win

**Why Passive Awareness First?**
- Gathers fresh data before any decision-making
- Ensures utility calculations use up-to-date information
- Low cost (just observation, no decisions)

### Behavior Tree Evaluation

Strategic behaviors use **selector logic** (try children in order):

```
Strategic: BuildEconomy
├─ Tactical: RepairCriticalBuildings  (if any building HP < 20%)
├─ Tactical: CollectTaxes             (if any building has gold)
├─ Tactical: ConstructNewBuilding     (if gold > 500)
└─ Tactical: RestInGarrison           (fallback: nothing urgent)
```

First applicable tactical behavior activates.

---

## Utility-Based Behavior Selection

### Base Utility

Each behavior has a base utility score (0-100):

```elm
baseUtility : TacticalBehavior -> Float
baseUtility behavior =
    case behavior of
        CollectTaxes -> 50.0
        RepairBuilding -> 50.0
        PatrolArea -> 30.0
        RestInGarrison -> 20.0
        -- ...
```

### Goal Modifiers

Active goals modify utilities:

```elm
-- Goal: "Upgrade Sword" (needs gold)
goalModifiers =
    [ ( CollectTaxes, 1.3 )      -- +30% utility
    , ( PatrolArea, 0.9 )        -- -10% utility
    ]
```

### Awareness Modifiers

Awareness results modify utilities:

```elm
-- Awareness: Enemy nearby
awarenessModifiers =
    [ ( FleeToSafety, 2.0 )      -- +100% utility
    , ( CollectTaxes, 0.5 )      -- -50% utility
    ]
```

### Final Utility

```elm
finalUtility = baseUtility * goalModifier * awarenessModifier
```

Behavior with highest final utility is selected (within priority tier).

---

## Core Behavior States (Operational Level)

### Dead
- **Priority**: N/A (terminal)
- **Description**: Unit removed from game
- **Action**: None
- **Transitions**: None

### WithoutHome
- **Priority**: Critical
- **Description**: Unit has no home building (destroyed)
- **Duration**: 15-30 seconds (randomized)
- **Action**: WaitThenDie
- **Transitions**: After timeout → Dead

### Sleeping
- **Priority**: Background
- **Description**: Rest in garrison, heal HP
- **Duration**: 1.0 second cycles
- **Action**: Sleep (heals 10% maxHP/sec)
- **Location**: Must be Garrisoned
- **Transitions**:
  - If HP = maxHP AND timer > 1.0s → DecideNextBehavior
  - If still healing → Continue Sleeping

### ExitGarrison
- **Priority**: Varies (matches next behavior)
- **Description**: Leave home building onto map
- **Duration**: Instant
- **Action**: SetLocationToMapAtEntrance
- **Transitions**: Complete → Next operational behavior

### MoveToLocation
- **Priority**: Varies (matches parent tactical)
- **Description**: Travel to coordinates
- **Duration**: Until arrival or timeout
- **Action**: FollowPath
- **Success**: Distance < 32 pixels
- **Failure**: Timeout (30s) or path blocked

### EnterGarrison
- **Priority**: Varies
- **Description**: Enter home building
- **Duration**: Until at entrance
- **Action**: MoveToEntrance then SetLocationToGarrisoned
- **Success**: Now garrisoned

---

## Example: Complete Behavior Stack

### Scenario: Peasant Collecting Taxes

```
GOAL:
  UpgradeSword (progress: 450/1000 gold)
  → Modifies CollectTaxes utility +30%

AWARENESS:
  WatchForThreats: No enemies detected
  ScanForLoot: No loot nearby
  MonitorHealth: HP = 50/50 (full)

STRATEGIC:
  BuildEconomy (Priority: Normal)
  → Delegates to tactical behaviors based on utility

TACTICAL:
  CollectTaxes (Priority: Normal)
  → Selected because utility boosted by UpgradeSword goal
  → Operational sequence:
     1. LookForBuildingWithGold
     2. MoveToBuilding ← CURRENTLY HERE
     3. CollectGold
     4. MoveTowardCastle
     5. DepositGoldAtCastle

OPERATIONAL:
  MoveToBuilding (target: House #42)
  → Following path: [(10,5), (11,6), (12,6)]
  → Progress: 2/3 waypoints
  → Duration: 3.5s elapsed

NEXT FRAME:
  - Awareness: Check for threats/loot
  - MoveToBuilding: Advance along path
  - If arrived: Complete → Tactical advances to CollectGold
```

### Scenario: Enemy Appears (Priority Interrupt)

```
AWARENESS UPDATE:
  WatchForThreats: Enemy unit detected! Distance: 150 pixels
  → Threat level: HIGH

PRIORITY INTERRUPT TRIGGERED:
  Current priority: Normal (CollectTaxes)
  New priority: Critical (FleeToSafety)
  → HARD INTERRUPT

ABANDON OLD STACK:
  ❌ Strategic: BuildEconomy
  ❌ Tactical: CollectTaxes (abandoned at MoveToBuilding)
  ❌ Operational: MoveToBuilding (abandoned mid-path)

NEW STACK:
  ✓ Strategic: DefendTerritory (Priority: Critical)
  ✓ Tactical: FleeToSafety (Priority: Critical)
  ✓ Operational: MoveToBuilding (target: Castle entrance)

RESULT:
  Unit immediately stops collecting taxes, runs to castle
  No resume - if threat passes, starts fresh behavior selection
```

---

## Validation Rules

A complete behavior system must satisfy:

- [ ] Every strategic behavior delegates to at least one tactical
- [ ] Every tactical behavior has operational sequence defined
- [ ] All behaviors have priority assigned
- [ ] Interrupt conditions specify which behaviors can interrupt which
- [ ] Awareness types defined per strategic/tactical behavior
- [ ] Goals specify utility modifiers for related behaviors
- [ ] All operational behaviors have success/failure conditions
- [ ] No infinite loops (all behaviors must eventually complete or be interrupted)

---

## Design Philosophy

### Why Hierarchical?
Allows clean separation: "What's the plan?" (strategic) vs "What am I doing?" (tactical) vs "What's my next step?" (operational)

### Why Hard Interrupts?
Simplicity. Soft interrupts require behavior stacks and resume logic. Hard interrupts: higher priority wins, old behavior forgotten.

### Why Passive Awareness?
Prevents thrashing. If awareness could interrupt, units would constantly switch behaviors. Passive awareness influences **next** decision smoothly.

### Why Goal-Based Utility?
Goals are fuzzy long-term objectives. They shouldn't dictate "collect gold NOW", but should make "collect gold" more appealing when the opportunity arises naturally.

---

## Next Steps

This core architecture will be extended with:
1. Unit-specific tactical behaviors (peasant.md, tax_collector.md, castle_guard.md)
2. Strategic coordinator behaviors (game-wide)
3. Goal definitions and utility modifiers
4. Awareness types and their triggers

The implementation will be in BehaviorEngine modules with JSON-driven behavior trees.
