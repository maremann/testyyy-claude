# Claude Assistant Notes

This document contains important context and instructions for Claude when working on this Elm project.

## Critical Instructions

### Game Design Documentation
**ALWAYS update the "Game Design" section of README.md after ANY change to game design is made.**

Game design changes include:
- New resources, units, buildings, or game mechanics
- Changes to existing gameplay elements
- UI/UX modifications that affect player interaction
- Balance changes (resource amounts, costs, etc.)
- New controls or input methods
- Visual style changes that impact gameplay

### Visual Representation Guideline
**Since we don't have graphics yet, all important game objects and things should be represented by basic colored boxes with the name as text and optionally an icon/emoji in it.**

When implementing new game objects (units, buildings, resources, etc.):
- Use HTML divs with colored backgrounds
- Include text label with the object's name
- Optionally add an emoji/icon for visual distinction
- Keep it simple and functional - no complex graphics needed yet
- Use inline CSS styling for colors and layout

## Elm Project Knowledge

### Project Structure
- **Language**: Elm 0.19.1
- **Main file**: `src/Main.elm`
- **Output**: `index.html` (compiled)
- **Architecture**: The Elm Architecture (Model-Update-View)

### Dependencies (elm.json)
- `elm/browser`: For Browser.element, Browser.Dom, Browser.Events
- `elm/core`: Core Elm functionality
- `elm/html`: HTML rendering
- `elm/json`: JSON decoding for event handling
- `elm/random`: Random number generation

### Elm Patterns Used

#### Application Type
Using `Browser.element` (not `sandbox`) to support:
- Subscriptions for mouse events and window resize
- Commands for async operations (viewport queries, random generation)

#### Model-Update-View
- **Model**: Contains all application state
- **Update**: Handles all messages and state changes, returns `(Model, Cmd Msg)`
- **View**: Pure function that renders HTML from model

#### Subscriptions
- Window resize events: `Browser.Events.onResize`
- Mouse events during dragging: `Browser.Events.onMouseMove`, `onMouseUp`
- Conditional subscriptions based on drag state

#### Event Handling
- Use `stopPropagationOn` to prevent event bubbling (e.g., minimap clicks)
- Decode events with `Json.Decode` for custom event data
- Global `clientX/clientY` for consistent coordinate systems

### Common Elm Patterns

#### Commands
Use `Cmd.batch` to execute multiple commands:
```elm
Cmd.batch
    [ Random.generate ShapesGenerated (generateShapes 150 mapConfig)
    , Task.perform GotViewport Dom.getViewport
    ]
```

#### Random Generation
Use `Random.Generator` and `Random.generate`:
```elm
Random.generate MessageConstructor generatorFunction
```

#### Task Execution
For one-time async operations:
```elm
Task.perform MessageConstructor Dom.getViewport
```

### Coordinate Systems

#### Main Viewport
- World coordinates: Absolute positions on the 4992×4992 map
- Camera offset: Subtracted from world positions to get screen positions
- Formula: `screenX = worldX - camera.x`

#### Minimap
- Uses scale factor to fit 4992×4992 world into 200×150 minimap
- 10px padding inside minimap border
- Scale calculation: `min((width - padding*2) / mapWidth) ((height - padding*2) / mapHeight)`

#### Grid Coordinates
- Build grid: 64×64 pixels per cell (78×78 cells total)
- Pathfinding grid: 32×32 pixels per cell (156×156 cells total)
- Building positions stored in build grid coordinates
- Conversion: `worldX = gridX * buildGridSize`

#### Mouse Events
- `clientX/clientY`: Global browser coordinates (used for consistency)
- `offsetX/offsetY`: Element-relative (avoided due to browser inconsistencies)
- Always convert global coords to local coords manually for predictable behavior

### Debugging
- Use `Debug.log` for console logging (Elm's built-in debug tool)
- Keep `Debug` import even when not actively debugging

### Styling Approach
- Inline CSS via `Html.Attributes.style`
- No external CSS files
- CSS-in-Elm pattern for all styling
- Uses HTML divs with absolute positioning for game elements

### Performance Considerations
- 150 decorative shapes rendered as individual divs
- All shapes repositioned on camera movement
- No culling implemented yet (all shapes always rendered)
- Consider adding viewport culling if performance becomes an issue

## Development Workflow

### Making Changes
1. Edit `src/Main.elm`
2. Compile: `elm make src/Main.elm --output=index.html`
3. Test in browser by opening `index.html`
4. **Update README.md if game design changed**

### Adding Dependencies
Manually add to `elm.json` in the `"direct"` dependencies object, then compile.

### Type Safety
- Elm is strongly typed - compiler catches most errors
- If compilation fails, read error messages carefully (they're very helpful)
- Use type annotations for top-level functions

## File Organization
- `/src/Main.elm` - All game code (currently monolithic)
- `/elm.json` - Package configuration
- `/index.html` - Compiled output
- `/elm-stuff/` - Build artifacts (ignored)
- `README.md` - Game design documentation
- `MECHANICS.md` - Game mechanics specification
- `CLAUDE.md` - This file (assistant notes)

## Building and Henchman System

This section explains the core game mechanics around buildings and henchmen, which form the foundation of the kingdom simulation.

### Overview

The game simulates a medieval kingdom where:
- **Buildings** are static structures that house henchmen and generate resources
- **Henchmen** are autonomous units that maintain the kingdom's infrastructure
- **Garrison System** connects buildings and henchmen through housing relationships
- **Behavior State Machines** control all autonomous actions

### Buildings

#### Building Types

1. **Castle** (Huge, 4×4 grid)
   - The player's main objective building
   - Houses basic henchmen: Peasants, Tax Collectors, Castle Guards
   - Spawns Houses automatically to support hero population
   - Behavior: `SpawnHouse` - Creates Houses every 30-45 seconds
   - Tags: `BuildingTag`, `ObjectiveTag`
   - Max HP: 5000, Cost: 10,000 gold (only built once at game start)

2. **House** (Medium, 2×2 grid)
   - Not player-buildable, spawned by Castle
   - Generates gold passively into its coffer
   - Behavior: `GenerateGold` - Adds 45-90 gold to coffer every 15-45 seconds
   - Tags: `BuildingTag`, `CofferTag`
   - Max HP: 500

3. **Warrior's Guild** (Large, 3×3 grid)
   - Player-buildable guild for Warrior heroes
   - Generates gold into its coffer (more than Houses)
   - Behavior: `GenerateGold` - Adds 450-900 gold to coffer every 15-45 seconds
   - Tags: `BuildingTag`, `GuildTag`, `CofferTag`
   - Max HP: 1000, Cost: 1500 gold

#### Construction System

All player-placed buildings (except Castle) follow this construction lifecycle:

1. **Placement**: Player places building in Build Mode
   - Costs gold immediately
   - Creates construction site at 10% of max HP (minimum 1)
   - Initial behavior: `UnderConstruction`
   - Initial tags: Only `BuildingTag`

2. **Construction**: Peasants automatically build the site
   - Peasants detect damaged buildings (HP < max HP)
   - Multiple Peasants can work simultaneously
   - Each Peasant adds 5 HP every 0.15 seconds while nearby (48px radius)
   - Construction site displays "(under construction)" suffix

3. **Completion**: When HP reaches 100%
   - Behavior transitions to proper type (e.g., `GenerateGold`)
   - Full tags added (e.g., `GuildTag`, `CofferTag`)
   - Building becomes fully functional

#### Building Properties

Every building has:
- **HP System**: Current/Max HP with health bar display
- **Garrison System**: Houses henchmen via garrison slots
- **Behavior State Machine**: Controls autonomous actions
- **Coffer** (if `CofferTag`): Stores generated gold for Tax Collector pickup
- **Entrance Tile**: Designated location where units garrison (varies by size)
- **Active/Search Radius**: 192px/384px for proximity detection

### Garrison System

The garrison system manages how henchmen live inside buildings.

#### Garrison Slot Configuration

Buildings with garrison use `GarrisonSlotConfig` records:
```elm
{ unitType : String        -- "Peasant", "Tax Collector", "Castle Guard"
, maxCount : Int           -- Maximum units of this type
, currentCount : Int       -- Currently spawned/alive units
, spawnTimer : Float       -- Countdown to next spawn
}
```

**Example** (Castle):
```elm
[ { unitType = "Castle Guard", maxCount = 2, currentCount = 0, spawnTimer = 0 }
, { unitType = "Tax Collector", maxCount = 1, currentCount = 0, spawnTimer = 0 }
, { unitType = "Peasant", maxCount = 3, currentCount = 0, spawnTimer = 0 }
]
```

#### Spawning Mechanics

1. **Automatic Spawning**: Buildings spawn henchmen every 30 seconds
   - Checks each slot type sequentially
   - If `currentCount < maxCount`, spawns one unit
   - Unit starts `Garrisoned` inside the building
   - `currentCount` increments immediately

2. **Death and Respawn**: When a henchman dies
   - Garrison slot `currentCount` decrements
   - After 30-second cooldown, new henchman spawns
   - Maintains population automatically

3. **Homeless Behavior**: If home building is destroyed
   - Henchman enters `WithoutHome` behavior
   - Dies after 15-30 seconds

### Henchmen

Henchmen are autonomous worker units that maintain the kingdom.

#### Common Properties

All henchmen have:
- **Home Building**: The building they're garrisoned in (or were spawned from)
- **Location**: Either `OnMap x y` or `Garrisoned buildingId`
- **Behavior State Machine**: Controls current action
- **HP with Regeneration**: Heals 10% max HP per second while Sleeping
- **Unit Type**: String identifier ("Peasant", "Tax Collector", "Castle Guard")

#### Core Behavior Cycle

All henchmen follow this state machine pattern:

1. **Sleeping** (while Garrisoned)
   - Regenerates 10% max HP per second
   - Checks for tasks every 1 second
   - Transitions to `LookingForTask` when timer expires

2. **LookingForTask**
   - Routes to appropriate task behavior based on unit type
   - Peasant → `LookForBuildRepairTarget`
   - Tax Collector → `LookForTaxTarget`
   - Others → `GoingToSleep` (no work available)

3. **Task Behavior** (type-specific)
   - Exits garrison if necessary
   - Performs specialized work
   - Returns to sleep when done

4. **GoingToSleep**
   - Moves toward home building entrance
   - Enters garrison when within 32 pixels
   - Checks for destroyed home (→ `WithoutHome` if destroyed)

5. **WithoutHome**
   - Henchman with destroyed home building
   - Dies after 15-30 seconds

#### Peasant Behavior

**Purpose**: Build construction sites and repair damaged buildings

**Properties**:
- Max HP: 50
- Move Speed: 2 cells/second
- Build Ability: Adds 5 HP every 0.15 seconds to nearby building

**State Machine**:

1. **LookForBuildRepairTarget**
   - If garrisoned: Exits garrison at building entrance
   - If on map: Searches for nearest building with HP < max HP
   - If found: Requests pathfinding, switches to `Repairing`
   - If none: Returns to sleep (`GoingToSleep`)

2. **Repairing**
   - Checks if within 48 pixels of target building
   - If near: Uses Build ability every 0.15 seconds
   - Building HP increases by 5 (applied in simulation loop)
   - When building reaches max HP: Switches to `LookForBuildRepairTarget`

**Implementation Notes**:
- Multiple Peasants can repair the same building
- HP gain is applied in the simulation loop, not directly in behavior
- Peasants don't distinguish between construction sites and damaged buildings
- Cooldown timer tracked in `behaviorTimer`

#### Tax Collector Behavior

**Purpose**: Collect gold from building coffers and deliver to Castle

**Properties**:
- Max HP: 50
- Move Speed: 1.5 cells/second
- Carried Gold Storage: Max 250 gold (returns to Castle when full)

**State Machine**:

1. **LookForTaxTarget**
   - Searches for nearest building with gold in coffer
   - Requests pathfinding to that building
   - When adjacent: Switches to `CollectingTaxes`

2. **CollectingTaxes**
   - Waits 2-3 seconds (collection animation)
   - Transfers all gold from building coffer to unit storage
   - If storage ≥ 250: Switches to `ReturnToCastle`
   - Otherwise: Returns to `LookForTaxTarget`

3. **ReturnToCastle**
   - Moves toward Castle entrance
   - Enters garrison when within 32 pixels
   - Switches to `DeliverGold`

4. **DeliverGold**
   - Waits 2-3 seconds
   - Transfers gold from storage to player gold
   - Player gold counter flashes green with +amount
   - Returns to `LookingForTask`

**Implementation Notes**:
- Tax Collector prioritizes full coffers (no partial pickups)
- Automatically returns to Castle when storage is full
- Gold is only added to player when delivered, not when collected

#### Castle Guard Behavior

**Status**: Not yet implemented
- Will defend the Castle
- Currently has no task behavior (goes directly to sleep)

### Gold System

Gold flows through the kingdom in this cycle:

1. **Generation**: Buildings with `GenerateGold` behavior create gold
   - Houses: 45-90 gold every 15-45 seconds → coffer
   - Warrior's Guild: 450-900 gold every 15-45 seconds → coffer

2. **Storage**: Gold sits in building `coffer` field
   - Displayed in selection panel for buildings with `CofferTag`
   - Accumulates until Tax Collector picks it up

3. **Collection**: Tax Collector picks up gold
   - Searches for buildings with `coffer > 0`
   - Takes all gold from coffer into carried storage
   - Can carry up to 250 gold before returning

4. **Delivery**: Tax Collector delivers to Castle
   - Enters Castle garrison
   - Transfers storage to player gold after 2-3 seconds
   - Player sees green flash with +amount

5. **Spending**: Player spends gold
   - Building placement costs deducted immediately
   - Red flash with -amount shown

### Game State Flow

**Pre-Game State**:
- Player must place Castle first
- Only Castle available in build menu
- Text displays "Site your Castle"
- No simulation runs

**Playing State**:
- Castle placed, game begins
- Castle starts spawning henchmen
- Henchmen begin working
- Houses spawn automatically
- Player can build Warrior's Guild and other buildings

**Game Over State**:
- Triggered when Castle HP reaches 0
- All input disabled
- "Game Over" text displayed

### Key Implementation Details

#### Entrance Tiles

Each building has one entrance tile where units garrison:
- **Small (1×1)**: The tile itself
- **Medium (2×2)**: Bottom-left tile
- **Large (3×3)**: Bottom-center tile
- **Huge (4×4)**: Bottom middle-left tile (2nd from left)

Calculated by `getBuildingEntrance : Building -> (Int, Int)`

#### Garrison Entry/Exit

**Exit** (`exitGarrison` function):
- Places unit at entrance tile world coordinates
- Centers unit in tile (buildGridSize / 2 offset)
- Changes location from `Garrisoned id` to `OnMap x y`

**Entry**:
- Detected in `GoingToSleep` behavior
- Triggers when unit within 32 pixels of entrance
- Changes location from `OnMap x y` to `Garrisoned id`

#### Simulation Loop Integration

Many behaviors request changes that execute in the simulation loop:

1. **Pathfinding Requests**: Behaviors set `targetDestination`, return flag
   - Loop collects all units needing paths
   - Generates random destinations or pathfinding requests

2. **Building HP Changes**: Multiple sources modify building HP
   - Peasant repair contributions calculated per-building
   - Sum all nearby repairing Peasants' contributions
   - Apply HP gain in single pass

3. **Gold Transfers**: Happen at specific behavior trigger points
   - Building generation: In building behavior update
   - Tax collection: In unit behavior update
   - Delivery: In unit behavior update

#### Behavior Timers

Two timer fields per entity:
- **behaviorTimer**: Counts up from 0, tracks time in current state
- **behaviorDuration**: Target duration for timed behaviors

Common patterns:
- **Cooldown**: Check if `timer >= cooldownValue`, reset to 0 when used
- **Duration Wait**: Check if `timer >= duration`, transition when complete
- **Periodic Check**: Increment timer, check at intervals (e.g., every 1 second)

### Debugging Tips

#### Common Issues

1. **Henchmen not spawning**
   - Check garrison config is set correctly on building
   - Verify spawn timer is incrementing
   - Check if building behavior is running simulation loop

2. **Peasants not repairing**
   - Verify they're exiting garrison successfully
   - Check pathfinding is finding damaged buildings
   - Ensure proximity detection (48px radius) is correct
   - Verify HP gain is applied in simulation loop

3. **Tax Collector not collecting**
   - Check buildings have `CofferTag` and `coffer > 0`
   - Verify pathfinding to coffer buildings works
   - Check storage limit (250) and return-to-castle logic

4. **Construction sites not completing**
   - Verify completion detection (HP >= maxHP && UnderConstruction)
   - Check behavior/tag transition logic triggers
   - Ensure proper building type string matching

#### Debug Visualization

Use debug panel to view:
- **Stats tab**: Simulation frame count, delta times
- **Visualization tab**: Grids, occupancy, city areas
- **Controls tab**: Spawn units, place buildings, adjust gold

Selection panel shows:
- Building: HP, garrison counts, behavior state, coffer amount
- Unit: HP, location, behavior state, carried gold (Tax Collector)

### Future Expansion

When adding new building/henchman types:

1. **New Building**:
   - Add template with stats
   - Define behavior (Idle, GenerateGold, or custom)
   - Add to construction system completion logic if needed
   - Update build menu UI

2. **New Henchman**:
   - Add to garrison config of appropriate building
   - Define behavior state machine
   - Implement task behaviors in `updateUnitBehavior`
   - Add routing in `LookingForTask`
   - Update unit rendering if special display needed

3. **New Behavior**:
   - Add to `UnitBehavior` or `BuildingBehavior` type
   - Implement in `updateUnitBehavior` or `updateBuildingBehavior`
   - Add to selection panel display logic
   - Add tooltip description for UI
