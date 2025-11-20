# Behavior Specification Format

This document defines the markdown format for specifying unit and building behaviors.

## Purpose

The behavior system uses three layers of abstraction:
1. **Markdown** (this format) - Human-readable, iterative design
2. **JSON** - Machine-readable intermediate representation (auto-generated)
3. **Elm Code** - Executable implementation (auto-generated)

## File Organization

```
behaviors/design/
├── CORE_BEHAVIORS.md       # Shared states for all units
├── peasant.md              # Peasant-specific behaviors
├── tax_collector.md        # Tax Collector-specific behaviors
├── castle_guard.md         # Castle Guard-specific behaviors
└── ...                     # Future unit types
```

## Markdown Structure

### Document Header
```markdown
# [Unit Type] Behavior

**Behavior ID**: unique_identifier
**Unit Type**: Peasant | Tax Collector | Castle Guard | ...
**Inherits**: CORE_BEHAVIORS (if applicable)
```

### State Definitions

Each state is defined as an H3 heading with properties as bullet lists:

```markdown
### StateName

- **Description**: Human-readable explanation of what this state does
- **Duration**: Time in seconds, or "Until condition" for event-driven states
- **Action**: ActionName (from Actions.elm)
- **On Enter**: Optional setup when entering this state
- **On Exit**: Optional cleanup when leaving this state
- **Transitions**:
  - If [Condition] → [TargetState]
  - If [Condition] → [TargetState]
  - Otherwise → [DefaultState] (optional)
```

### Example State

```markdown
### LookForBuildRepairTarget

- **Description**: Peasant searches for damaged buildings within search radius
- **Duration**: 0.5 seconds
- **Action**: FindNearestDamagedBuilding
- **Transitions**:
  - If BuildingFound → MovingToBuildRepairTarget
  - If NoBuildingFound → GoingToSleep
```

## Condition Types

Conditions determine state transitions. Available condition types:

### Action Result Conditions
Based on the result of the state's action:
- `BuildingFound` - FindNearestDamagedBuilding succeeded
- `NoBuildingFound` - No suitable building found
- `PathComplete` - Unit reached destination
- `GoldCollected` - Successfully collected gold
- `TimerExpired` - Duration elapsed

### Location Conditions
- `IsGarrisoned` - Unit is in a building
- `IsOnMap` - Unit is on the map
- `AtTarget` - Unit reached target destination
- `NearBuilding [id]` - Unit is near specific building

### State Conditions
- `HPFull` - HP equals maxHP
- `HPLow` - HP below threshold
- `HasGold` - carriedGold > 0
- `NoGold` - carriedGold = 0

### Time Conditions
- `TimerExpired` - behaviorTimer >= behaviorDuration
- `After [seconds]` - Explicit time condition

### Fallback
- `Otherwise` - Default transition if no other conditions met
- `Always` - Unconditional transition (immediate)

## Action Types

Actions are implemented in `BehaviorEngine/Actions.elm`. Common actions:

### Search Actions
- `FindNearestDamagedBuilding` - Search for buildings needing repair
- `FindBuildingWithGold` - Search for buildings with gold in coffer
- `FindHomeBuilding` - Locate unit's home building
- `FindCastle` - Locate player's castle

### Movement Actions
- `CheckArrival` - Test if unit reached target
- `SetPathTo [target]` - Calculate path to target
- `ExitGarrison` - Leave home building onto map

### Work Actions
- `RepairBuilding` - Add HP to nearby building
- `CollectGold` - Extract gold from building coffer
- `DepositGold` - Transfer gold to player treasury
- `PatrolArea` - Move within patrol radius

### Wait Actions
- `WaitFor [duration]` - Idle for specified time
- `Sleep` - Rest and heal
- `NoAction` - Do nothing (idle state)

## Timer Management

Each state can have a duration. Timers work as follows:

1. **`behaviorTimer`**: Tracks time in current state
2. **`behaviorDuration`**: How long to stay in state
3. **Timer resets** when transitioning to new state
4. **TimerExpired condition**: `behaviorTimer >= behaviorDuration`

### Duration Syntax
- `0.5 seconds` - Fixed duration
- `1.0-3.0 seconds` - Random range (will be expanded by tooling)
- `Until arrival` - Event-driven (no timer)
- `Infinite` - Must transition via condition

## State Machine Requirements

A well-formed behavior must satisfy:

### Completeness
- [ ] Every state has at least one transition
- [ ] All conditions are mutually exclusive OR has `Otherwise` fallback
- [ ] No unreachable states (all states reachable from initial state)

### Safety
- [ ] Dead state exists and is reachable (for unit cleanup)
- [ ] Error state exists for debugging
- [ ] No infinite loops without exit conditions

### Clarity
- [ ] Each state has clear single responsibility
- [ ] State names are descriptive
- [ ] Transitions are logical and predictable

## Inheritance (CORE_BEHAVIORS)

Unit types can inherit shared states from `CORE_BEHAVIORS.md`:

```markdown
**Inherits**: CORE_BEHAVIORS
```

Inherited states:
- `Dead` - Unit is removed from game
- `DebugError` - Unit encountered error
- `WithoutHome` - Unit has no home building (dies after timeout)
- `Sleeping` - Unit rests in garrison, heals
- `LookingForTask` - Unit decides what to do next
- `GoingToSleep` - Unit paths back to home building

Specialized behaviors extend these with unit-specific states.

## Example: Complete Behavior Specification

```markdown
# Peasant Repair Behavior

**Behavior ID**: peasant_repair
**Unit Type**: Peasant
**Inherits**: CORE_BEHAVIORS

## Description

Peasants automatically search for damaged buildings and repair them. When no damaged buildings exist, they return to sleep in their home building.

## Shared States

*See CORE_BEHAVIORS.md for:*
- Sleeping
- LookingForTask
- GoingToSleep
- WithoutHome
- Dead

## Specialized States

### LookForBuildRepairTarget

- **Description**: Peasant searches for damaged buildings within search radius
- **Duration**: 0.5 seconds
- **Action**: FindNearestDamagedBuilding
- **On Enter**: If garrisoned, exit garrison first
- **Transitions**:
  - If BuildingFound → MovingToBuildRepairTarget
  - If NoBuildingFound → GoingToSleep

### MovingToBuildRepairTarget

- **Description**: Travel to damaged building
- **Duration**: Until arrival
- **Action**: CheckArrival
- **On Enter**: Set path to building entrance
- **Transitions**:
  - If Arrived → Repairing
  - If BuildingFullyRepaired → LookForBuildRepairTarget

### Repairing

- **Description**: Repair building (adds 5 HP every 0.15s)
- **Duration**: 0.15 seconds per tick
- **Action**: RepairBuilding
- **Transitions**:
  - If BuildingFullyRepaired → LookForBuildRepairTarget
  - If NotNearBuilding → MovingToBuildRepairTarget
  - If TimerExpired → Repairing (continue repairing)
```

## Validation Checklist

Before running toolchain, verify:

- [ ] All state names match UnitBehavior type in Types.elm
- [ ] All action names exist in Actions.elm
- [ ] All conditions are valid condition types
- [ ] State machine has no dead ends
- [ ] Initial state is defined (inherited from CORE or explicit)
- [ ] Transitions are deterministic (no ambiguous conditions)

## Toolchain Usage

Once behavior is designed in markdown:

```bash
# Convert markdown to JSON
node tools/md-to-json.js behaviors/design/peasant.md behaviors/compiled/peasant.json

# Generate Elm code
node tools/json-to-elm.js behaviors/compiled/ src/BehaviorEngine/Registry.elm

# Compile and test
elm make src/Main.elm --output=elm.js
```

Or use the build script:

```bash
./build-behaviors.sh
```

## Iteration Workflow

1. Edit markdown behavior spec
2. Run toolchain to regenerate code
3. Test in game
4. Observe behavior in debug panel
5. Refine markdown spec
6. Repeat

This allows rapid iteration on behavior design without writing Elm code.
