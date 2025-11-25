# Castle Building Behavior

**Behavior ID**: castle_building
**Unit Type**: Castle
**Inherits**: NONE

## Description

The Castle is the kingdom's heart. It generates passive income (2 gold every 15-30 seconds) and spawns defenders into its garrison. There is only one castle per game. If destroyed (HP <= 0), the game ends.

## Strategic Behaviors

### Exist
- **Priority**: Normal
- **Tactical Delegates**:
  1. GenerateIncome
- **Transitions**:
  - None

## Tactical Behaviors

### GenerateIncome
- **Description**: Generate passive gold for the player
- **Priority**: Background
- **Operational Sequence**:
  1. IncrementGoldTimer (count up to duration)
  2. AddGoldToPlayer (when timer reaches duration)
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
- **Duration**: 15-30 seconds (randomized per castle)
- **Success**: timer >= building.behaviorDuration
- **Failure**: None
- **Side Effects**: building.behaviorTimer += deltaSeconds
- **Result**:
  - TimerComplete (timer >= duration)
  - Counting (timer < duration)

### AddGoldToPlayer
- **Description**: Generate gold directly to player's gold pool
- **Action**: AddGoldToPlayer
- **Parameters**:
  - amount: 2 gold
  - target: player.gold
- **Duration**: Instant
- **Success**: Always
- **Failure**: None
- **Side Effects**:
  - player.gold += 2
  - building.behaviorTimer = 0
- **Result**: Success

---

## Awareness System

Castle has no awareness system - it simply exists and generates income.

---

## State Data

```elm
type alias CastleState =
    { currentStrategic : StrategicCastle
    , currentTactical : Maybe TacticalCastle
    }

type StrategicCastle = Exist

type TacticalCastle = GenerateIncome
```

---

## State Transitions

```
[Castle Built]
    ↓
Exist
    ↓
GenerateIncome (continuous)
    ↓
IncrementGoldTimer (0s → 15-30s)
    ↓
TimerComplete → AddGoldToPlayer (player.gold += 2)
    ↓
Reset timer → Repeat

If HP <= 0:
    → Game Over (handled by ObjectiveTag in Simulation.elm)
```

---

## Example Scenario

**Initial State**: Castle at 1000/1000 HP
- behaviorTimer: 0s
- behaviorDuration: 22.5s (random for this castle)
- garrisonConfig:
  - Castle Guard: 0/2, spawnTimer: 0s
  - Tax Collector: 0/1, spawnTimer: 0s

**Timeline**:

**t=0s**: Castle operational
- Gold timer: 0s / 22.5s
- Garrison: 0/2 Guards, 0/1 Collector → Has space, start timer

**t=10s**: First garrison spawn
- Gold timer: 10s / 22.5s
- Garrison timer: 10s → SPAWN!
  - Create Castle Guard #1 (Sleeping, Garrisoned)
  - Create Castle Guard #2 (Sleeping, Garrisoned)
  - Create Tax Collector #1 (Sleeping, Garrisoned)
  - Now: 2/2 Guards, 1/1 Collector → All full
  - Garrison timer stops

**t=22.5s**: First gold generation
- Gold timer: 22.5s → COMPLETE!
  - player.gold += 2
  - Reset to 0s
- Garrison: Still full, idle

**t=45s**: Second gold generation
- Gold timer: 22.5s → COMPLETE!
  - player.gold += 2
  - Reset to 0s

**t=60s**: Castle Guard dies in combat
- Garrison: 1/2 Guards, 1/1 Collector → Has space!
- Start garrison timer: 0s

**t=70s**: Replacement spawn
- Garrison timer: 10s → SPAWN!
  - Create Castle Guard #3 (Sleeping, Garrisoned)
  - Now: 2/2 Guards, 1/1 Collector → Full again
  - Garrison timer stops

(Continues indefinitely until castle destroyed)

---

## Implementation Notes

### Gold Generation
- No building coffer involved - gold goes directly to Model.gold
- Each castle has its own random duration (15-30s)
- Duration set once during initialization, never changes
- Simple timer increment and reset pattern

### Garrison Spawning
- **Simultaneous**: All available slots spawn at once, not one-by-one
- **Shared Timer**: Single timer for all slots (garrisonConfig[0].spawnTimer)
- **Conditional**: Only counts if at least one slot has room
- **Initial Spawn**: Happens 10 seconds after castle becomes operational
- **Respawn**: If a unit dies, its slot opens and spawning resumes

### Game Over
- Castle has ObjectiveTag in its tags list
- Simulation.elm checks: `List.any (\b -> List.member ObjectiveTag b.tags && b.hp <= 0) buildings`
- If true, sets gameState to GameOver
- No special behavior needed in castle - tag is sufficient

### Simplicity
- No behavior tree hierarchy (Strategic/Tactical/Operational)
- No awareness system
- No complex decision making
- Just two simple timer-based behaviors
- Uses existing Building type fields

---

## Testing Checklist

- [ ] Castle generates 2 gold every 15-30 seconds
- [ ] Gold appears in player.gold (not building coffer)
- [ ] Different castles have different random durations
- [ ] Garrison spawns all units simultaneously after 10s
- [ ] Castle Guard slots fill to 2/2
- [ ] Tax Collector slot fills to 1/1
- [ ] If a unit dies, its slot opens
- [ ] Replacement unit spawns after 10s
- [ ] Garrison timer only runs when slots available
- [ ] Castle has ObjectiveTag
- [ ] Game ends when castle HP reaches 0
- [ ] Only one castle exists per game

---

## Design Rationale

**Why 2 gold per cycle?**
- Small but meaningful passive income
- Prevents total economic stall
- Not enough to spam units - encourages expansion
- Castles are expensive, should provide value

**Why 15-30 second random duration?**
- Prevents predictable timing exploits
- Adds variety to each game
- Range is wide enough for variation but not too long to feel sluggish

**Why simultaneous garrison spawning?**
- Simpler implementation (one timer, not per-slot)
- Units appear together, feel more impactful
- Faster garrison filling after losses

**Why 10 second spawn time?**
- Not instant (player must wait for reinforcements)
- Not too slow (reasonable recovery time)
- Matches unit behavioral timings

**Why no complex behavior tree?**
- Castle behavior is simple and doesn't need hierarchy
- Timer-based approach is sufficient
- Easier to understand and maintain
- Can always upgrade to behavior tree later if needed
