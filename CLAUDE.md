# Castle Strategy Game - Technical Documentation

## Project Overview

A real-time strategy game prototype built with Elm 0.19.1 featuring autonomous AI-driven units, building management, resource economy, and simulation mechanics.

## Game Concept

Players manage a medieval kingdom starting with a Castle. Buildings generate gold, units (henchmen) autonomously perform tasks like construction, repairs, and tax collection. The game uses a behavior-driven AI system where units and buildings operate through state machines.

## Core Systems

### 1. Buildings

**Building Types** (src/BuildingTemplates.elm):
- **Castle** (4×4): Mission-critical HQ with garrison capacity of 6, spawns Houses periodically
- **House** (2×2): Generates 45-90 gold periodically, no garrison
- **Warrior's Guild** (3×3): Trains warriors, generates 450-900 gold
- **Test Building** (2×2): Development/testing structure

**Building Behaviors** (src/BuildingBehavior.elm):
- `Idle`: No active behavior
- `UnderConstruction`: Building being constructed
- `SpawnHouse`: Castle spawns new Houses every ~30s
- `GenerateGold`: Accumulates gold in building's coffer every ~15-45s
- `BuildingDead`: Building destroyed

### 2. Units (Henchmen)

**Unit Types** (src/GameStrings.elm):
- **Peasant**: Searches for damaged buildings to repair
- **Tax Collector**: Collects gold from building coffers, delivers to Castle
- **Castle Guard**: Defensive unit (currently patrols/sleeps)

**Unit Behaviors** (src/UnitBehavior.elm):
- `Sleeping`: Unit rests in garrison, heals 10% HP/s
- `LookingForTask`: Determines next task based on unit type
- `GoingToSleep`: Pathfinding to home building
- `LookForBuildRepairTarget`: Peasants find damaged buildings
- `MovingToBuildRepairTarget`: Traveling to repair location
- `Repairing`: Fixing damaged building
- `LookForTaxTarget`: Tax Collectors find buildings with gold
- `CollectingTaxes`: Extracting gold from building coffer
- `ReturnToCastle`: Returning with collected gold
- `DeliveringGold`: Depositing gold to player treasury
- `WithoutHome`: Unit has no home building (→ dies after 15s)
- `Dead`: Unit removed from game

### 3. Garrison System

**Features**:
- Buildings can house units in garrison slots
- Each slot has: unit type, max count, current count, spawn timer
- Units spawn periodically when below max capacity
- Garrisoned units still process behaviors (can wake up, exit, seek tasks)
- Castle starts with 1 of each unit type (Peasant, Tax Collector, Castle Guard)

**Implementation** (src/Types.elm:101-124):
```elm
type alias GarrisonSlotConfig =
    { unitType : String
    , maxCount : Int
    , currentCount : Int
    , spawnTimer : Float
    }
```

### 4. Pathfinding

**Grid System** (src/Grid.elm, src/Pathfinding.elm):
- Build grid: 64×64 pixels (for building placement)
- Pathfinding grid: 32×32 pixels (for unit movement)
- A* pathfinding with occupancy tracking
- Dynamic obstacle avoidance around buildings

### 5. Resource Economy

**Gold System**:
- Houses generate 45-90 gold periodically
- Warrior's Guilds generate 450-900 gold
- Gold stored in building coffers
- Tax Collectors transfer gold to player treasury
- Buildings cost gold to construct

### 6. Camera & Viewport

**Controls** (src/Camera.elm):
- Click-drag viewport to pan camera
- Minimap for navigation
- Viewport shows portion of larger game world

### 7. Simulation Loop

**Speeds** (src/Simulation.elm):
- Pause: Simulation stopped
- 1x: Real-time
- 2x: Double speed
- 10x: Fast-forward
- 100x: Ultra fast-forward

**Frame Processing**:
- Fixed timestep simulation
- Accumulated time tracking
- Unit behavior updates
- Building behavior updates
- Garrison spawning
- Pathfinding requests

## Architecture

### Module Structure

```
src/
├── Main.elm                 # Entry point, model initialization, orchestration
├── Types.elm                # Core type definitions and aliases
├── Model.elm                # (referenced in git history)
├── Update.elm               # Message handling and state updates
├── Message.elm              # All message types
├── View.elm                 # Main rendering
├── View/
│   ├── Viewport.elm         # Game world viewport rendering
│   ├── SelectionPanel.elm   # Building/unit info panel
│   └── Debug.elm            # Debug overlay UI
├── Simulation.elm           # Simulation tick logic
├── UnitBehavior.elm         # Unit AI state machine
├── BuildingBehavior.elm     # Building AI state machine
├── Pathfinding.elm          # A* pathfinding algorithm
├── Grid.elm                 # Grid utilities, building placement
├── Camera.elm               # Viewport camera logic
├── GameHelpers.elm          # Shared helper functions
├── BuildingTemplates.elm    # Building definitions
└── GameStrings.elm          # All UI strings (i18n ready)
```

### Key Data Structures

**Model** (src/Types.elm:8-39):
- Camera position
- Drag state (viewport/minimap)
- Window size
- Game state (PreGame/Playing/GameOver)
- Gold amount
- Selected entity (building/unit/UI button)
- Buildings list + occupancy grid
- Units list
- Pathfinding occupancy
- Build mode
- Simulation state (frame count, speed, accumulated time)
- Debug configuration

**Building** (src/Types.elm:106-124):
- Owner (Player/Enemy)
- Grid position + size
- HP (current/max)
- Garrison configuration
- Behavior state + timer
- Coffer (gold storage)
- Active/search radius for AI
- Tags (Building, Guild, Objective, Coffer)

**Unit** (src/Types.elm:134-155):
- Owner, location (OnMap/Garrisoned)
- HP, movement speed, unit type
- Path (list of grid cells)
- Behavior state + timers
- Home building reference
- Carried gold
- Target destination for pathfinding
- Active/search radius
- Tags (Hero, Henchman)

## Recent Development

Based on git history (c319873 - 58d93da - 97708e2):

1. **Garrison System Fixes**: Garrisoned units now properly update behaviors, allowing them to exit garrison and perform tasks
2. **Initial Castle Units**: Castle now starts with 1 Peasant, 1 Tax Collector, 1 Castle Guard
3. **Test Unit Cleanup**: Removed old test unit behaviors (random movement, thinking state)
4. **Proper Henchman Behaviors**: Units now follow task-oriented state machines
5. **Code Reduction**: Multiple commits focused on reducing file size and splitting code

## Development Setup

**Build & Run**:
```bash
elm make src/Main.elm --output=elm.js
open index.html
```

**Dependencies** (elm.json):
- elm/browser 1.0.2
- elm/core 1.0.5
- elm/html 1.0.0
- elm/json 1.1.4
- elm/random 1.0.0

## Game Loop

1. Player places Castle at game start
2. Castle spawns initial garrison (1 of each unit type)
3. Castle periodically spawns Houses
4. Houses generate gold in their coffers
5. Units wake from garrison periodically
6. Peasants find and repair damaged buildings
7. Tax Collectors find buildings with gold, collect it, return to Castle
8. Castle Guards patrol (future: defend against enemies)
9. If Castle destroyed → Game Over

## Debug Features

**Visualization Toggles**:
- Build grid overlay
- Pathfinding grid overlay
- Pathfinding occupancy
- Building occupancy
- City active area (building active radius)
- City search area (building search radius)

**Stats Display**:
- Camera position
- Simulation frame count
- Average frame delta (ms)
- Current gold
- Simulation speed

**Selection Panel**:
- Building: HP, behavior, timer, coffer, garrison status
- Unit: HP, behavior, timer, location, carried gold
- Tabs: Main info, detailed info

## Known Limitations

- Single-player only (no enemy AI yet)
- Limited building types (4 total)
- No combat system (Castle Guards don't fight)
- No win condition (only lose condition: Castle dies)
- Houses spawn automatically from Castle (no manual construction)
- Building construction system exists but limited integration

## Code Quality Notes

- Clean separation of concerns (Model/Update/View)
- Type-safe Elm architecture
- All UI strings externalized to GameStrings
- Behavior systems use state machines
- Grid-based coordinate system throughout
- Comprehensive debug tooling

## Future Expansion Vectors

Based on existing code structure:
- Enemy AI (BuildingOwner.Enemy already exists)
- Combat system (HP system already in place)
- Manual building construction (templates exist)
- Hero units (UnitKind.Hero defined but unused)
- More building types (template system is extensible)
- Win conditions
- Save/load game state
- Internationalization (GameStrings ready)
