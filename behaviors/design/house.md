# House Building Behavior

**Behavior ID**: house_building
**Unit Type**: House
**Inherits**: NONE

## Description

The House is a small residential building that generates passive income. It accumulates gold in its coffer (2 gold every 15-30 seconds, randomized). Houses cannot be placed by the player and do not have a construction phase - they start at full HP when spawned by the game.

## Strategic Behaviors

### Exist
- **Priority**: Normal
- **Tactical Delegates**:
  1. GenerateIncome
- **Transitions**:
  - None

## Tactical Behaviors

### GenerateIncome
- **Description**: Generate passive gold into the building's coffer
- **Priority**: Background
- **Operational Sequence**:
  1. IncrementGoldTimer (count up to duration)
  2. AddGoldToCoffer (when timer reaches duration)
- **Success**: Continuous (never completes)
- **Failure**: None
- **Interruptible**: No
- **Transitions**: None (runs forever)

---

## Operational Behaviors

### IncrementGoldTimer
- **Description**: Count time until next gold generation
- **Action**: IncrementTimer
- **Parameters**:
  - timer: building.behaviorTimer
  - deltaSeconds: frame time
- **Duration**: 15-30 seconds (randomized per house)
- **Success**: timer >= building.behaviorDuration
- **Failure**: None
- **Side Effects**: building.behaviorTimer += deltaSeconds
- **Result**:
  - TimerComplete (timer >= duration)
  - Counting (timer < duration)

### AddGoldToCoffer
- **Description**: Generate gold into the building's coffer
- **Action**: AddGoldToCoffer
- **Parameters**:
  - amount: 2 gold
  - target: building.coffer
- **Duration**: Instant
- **Success**: Always
- **Failure**: None
- **Side Effects**:
  - building.coffer += 2
  - building.behaviorTimer = 0
- **Result**: Success

---

## Awareness System

House has no awareness system - it simply exists and generates income.

---

## State Data

```elm
type alias HouseState =
    { currentStrategic : StrategicHouse
    , currentTactical : Maybe TacticalHouse
    }

type StrategicHouse = Exist

type TacticalHouse = GenerateIncome
```

---

## State Transitions

```
[House Spawned]
    ↓
Exist (HP: 500/500)
    ↓
GenerateIncome (continuous)
    ↓
IncrementGoldTimer (0s → 15-30s)
    ↓
TimerComplete → AddGoldToCoffer (building.coffer += 2)
    ↓
Reset timer → Repeat

If HP <= 0:
    → Building destroyed
```

---

## Example Scenario

**Initial State**: House spawned at 500/500 HP
- behaviorTimer: 0s
- behaviorDuration: 18.3s (random for this house)
- coffer: 0 gold
- Not in build menu (spawned by game mechanics)

**Timeline**:

**t=0s**: House operational
- Gold timer: 0s / 18.3s
- Coffer: 0 gold

**t=18.3s**: First gold generation
- Gold timer: 18.3s → COMPLETE!
  - building.coffer += 2
  - Reset timer to 0s
- Coffer: 2 gold

**t=36.6s**: Second gold generation
- Gold timer: 18.3s → COMPLETE!
  - building.coffer += 2
  - Reset timer to 0s
- Coffer: 4 gold

**t=55s**: Tax Collector visits
- Tax Collector collects 4 gold from coffer
- Coffer: 0 gold
- Timer continues running (currently at 0.1s)

**t=73.3s**: Third gold generation
- Gold timer: 18.3s → COMPLETE!
  - building.coffer += 2
  - Reset timer to 0s
- Coffer: 2 gold

(Continues indefinitely until house destroyed)

---

## Implementation Notes

### Gold Generation
- Gold goes to building.coffer (NOT player.gold like castle)
- Tax Collectors will visit houses to collect gold from coffer
- Each house has its own random duration (15-30s)
- Duration set once during initialization, never changes
- Simple timer increment and reset pattern

### Building Properties
- Size: Small (2x2 grid cells)
- HP: 500/500 (starts at full HP)
- No construction phase
- Has CofferTag for Tax Collector targeting
- Has BuildingTag for general building systems

### Spawning
- Houses are NOT in the build menu
- Houses are spawned by game mechanics (future implementation)
- When spawned, they start at full HP immediately
- No UnderConstruction behavior needed

### Simplicity
- No behavior tree hierarchy complexity
- No awareness system
- No complex decision making
- Just a simple timer-based gold accumulation
- Uses existing Building type fields

---

## Testing Checklist

- [ ] House generates 2 gold every 15-30 seconds to its coffer
- [ ] Gold appears in building.coffer (not player.gold)
- [ ] Different houses have different random durations
- [ ] House has CofferTag for Tax Collector targeting
- [ ] House has BuildingTag
- [ ] House starts at 500/500 HP when spawned
- [ ] House timer increments correctly
- [ ] Tax Collectors can collect gold from house coffer

---

## Design Rationale

**Why 2 gold per cycle?**
- Consistent with castle generation rate
- Encourages building multiple houses for economic growth
- Balanced with Tax Collector collection mechanics

**Why 15-30 second random duration?**
- Same as castle for consistency
- Prevents predictable timing
- Adds variety to each game

**Why coffer instead of direct to player?**
- Creates gameplay loop: houses generate → Tax Collectors collect → player receives
- Makes Tax Collectors meaningful and necessary
- Adds spatial economy (Tax Collectors must travel to houses)

**Why 500 HP?**
- Small building, less HP than larger structures
- Vulnerable but not trivially destroyed
- Encourages player to protect residential areas

**Why no construction phase?**
- Houses are spawned by game mechanics, not built by player
- Simplifies house spawning logic
- Different from player-built buildings like Warriors Guild
