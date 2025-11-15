# Strategy Game Prototype

A real-time strategy (RTS) game built with Elm, featuring a top-down 2D view.

## Game Design

### Genre & Perspective
- **Genre**: Real-Time Strategy (RTS)
- **Perspective**: Top-down 2D view
- **Map Size**: 4992×4992 pixels (exactly 78 build grid cells or 156 pathfinding grid cells)
- **Viewport**: Responsive, adjusts to window size with 4:3 aspect ratio preference

### Selection System
- **Selection State**: Player always has 0 or 1 thing selected at any time
- **Selection Determines UI**: The currently selected thing determines the content of the selection panel
- **Currently Selectable**: Global buttons (Debug, Build), buildings, and units
- **Deselection**: User cannot manually deselect
  - Zero selected only at game start or if selected thing is removed from game
- **Selection Highlight**: Semi-transparent yellow overlay with glow effect
  - Always visible when selected thing is on screen
  - Color: rgba(255, 215, 0, 0.3) with golden box shadow
- **No Selection State**: Selection panel shows "No selection" text in gray italic

### Resources
- **Gold**: The primary resource in the game
  - Starting amount: 50,000
  - Displayed in top-right corner above minimap
  - Visual representation: Yellow circular coin icon with gold-colored number
  - Generated passively by Houses and Guilds into building coffers
  - Collected by Tax Collectors and delivered to Castle
  - Spent on building construction

### Grids
- **Purpose**: Logical organization systems for building placement and unit pathfinding
- **Visibility**: Not shown to users by default (only visible via debug visualization)
- **Alignment**: Terrain size (4992×4992) aligns exactly with both grids
- **Build Grid**:
  - Cell size: 64×64 pixels
  - Approximately 1/3 the size of the minimap
  - Purpose: Determines valid building placement positions
  - Dimensions: 78×78 cells (exactly covers the 4992×4992 map)
  - Debug color: Semi-transparent yellow (rgba(255, 255, 0, 0.3))
- **Pathfinding Grid**:
  - Cell size: 32×32 pixels (half the build grid size)
  - Purpose: Unit movement and pathfinding calculations
  - Dimensions: 156×156 cells (exactly covers the 4992×4992 map)
  - Debug color: Semi-transparent cyan (rgba(0, 255, 255, 0.3))
- **Debug Visualization**: Toggle grid visibility using checkboxes in the debug panel

### Pathfinding Occupancy
- **Purpose**: Track which pathfinding grid tiles are blocked by buildings or units
- **Occupancy Rule**: A pathfinding tile is occupied if any building or unit intersects it or lies inside it
- **Update Policy**: Occupancy must be updated whenever:
  - A building is created or destroyed
  - A unit is created, moved, or destroyed (units not yet implemented)
- **Data Structure**:
  - Dict mapping pathfinding grid coordinates `(Int, Int)` to occupancy count `Int`
  - Uses reference counting to handle overlapping objects
  - Enables O(1) lookup for pathfinding algorithms
- **Building Occupancy Calculation**:
  - A 1×1 building (64×64px) occupies 2×2 pathfinding cells (4 cells total)
  - A 2×2 building (128×128px) occupies 4×4 pathfinding cells (16 cells total)
  - A 3×3 building (192×192px) occupies 6×6 pathfinding cells (36 cells total)
  - A 4×4 building (256×256px) occupies 8×8 pathfinding cells (64 cells total)
- **Debug Visualization**: Dark blue overlay (rgba(0, 0, 139, 0.5)) on occupied tiles

### Buildings
- **Selectable**: Buildings are selectable things that can be clicked to view/interact
- **Static**: Buildings do not move once placed
- **Grid Placement**: Buildings are always placed on the build grid (64×64)
- **Spacing Requirement**: Must have 1 building grid tile gap between adjacent buildings during placement
- **Sizes**: Four size categories
  - Small: 1×1 grid cells (64×64 pixels)
  - Medium: 2×2 grid cells (128×128 pixels)
  - Large: 3×3 grid cells (192×192 pixels)
  - Huge: 4×4 grid cells (256×256 pixels)
- **Properties**:
  - HP: Building health points (current/max), displayed via health bar below building
  - Garrison: Houses henchmen via garrison slot configuration
  - Coffer: Gold storage (if building has Coffer tag)
  - Cost: Gold required to construct
  - Owner: Player or Enemy
  - Behavior: State machine controlling actions
  - Tags: Collection of gameplay tags
  - Active/Search Radius: 192px/384px (approximately 3/6 build tiles)
- **Entrance Tiles**: Each building has one designated entrance tile
  - Purpose: Designated location for units to garrison into building
  - Visual: Transparent brown overlay with dark outline (rgba(139, 69, 19, 0.5))
  - Position by building size:
    - Small (1×1): The tile itself
    - Medium (2×2): Bottom left tile
    - Large (3×3): Bottom center tile
    - Huge (4×4): Bottom middle-left tile (second from left on bottom row)
- **Minimap Representation**:
  - Player buildings: Aquamarine/Light Blue (#7FFFD4)
  - Enemy buildings: Red (#FF0000)
- **Data Structure**:
  - Buildings stored in a list with unique IDs
  - Build grid occupancy tracked via Dict mapping (gridX, gridY) → count
  - Pathfinding grid occupancy updated automatically when buildings placed/removed
  - Enables efficient proximity queries and placement validation
- **Available Buildings**:
  - **Castle**: 4×4 Huge, 5000 HP, 10,000 gold
    - Player's main objective building (game over if destroyed)
    - Houses 3 Peasants, 1 Tax Collector, 2 Castle Guards
    - Spawns Houses automatically every 30-45 seconds
    - Must be placed first to start the game
    - Tags: Building, Objective
  - **House**: 2×2 Medium, 500 HP (not player-buildable)
    - Spawned automatically by Castle
    - Generates 45-90 gold every 15-45 seconds
    - Gold stored in building coffer for Tax Collector pickup
    - Tags: Building, Coffer
  - **Warrior's Guild**: 3×3 Large, 1000 HP, 1500 gold
    - Player-buildable guild for Warrior heroes (not yet implemented)
    - Generates 450-900 gold every 15-45 seconds
    - Gold stored in building coffer for Tax Collector pickup
    - Tags: Building, Guild, Coffer

### Build Mode
- **Castle Placement** (Pre-Game):
  - At game start, only Castle available in build menu
  - Text displays "Site your Castle" in top-right
  - Castle can be placed anywhere on map
  - Game begins when Castle is placed (exits Pre-Game state)
- **Regular Building Placement** (Playing state):
  - Activation: Click a building button in the Build menu (only enabled if sufficient gold)
  - Visual Indicator: Active building button shows white semi-transparent highlight overlay
  - Cancellation: Click the active building button again, or switch away from Build menu
- **Building Preview**:
  - Transparent preview follows mouse cursor
  - Preview centered on build grid cell under cursor
  - **Valid placement**: Bright green (rgba(0, 255, 0, 0.5))
  - **Invalid placement**: Bright red (rgba(255, 0, 0, 0.5))
  - White border outline on preview
  - Shows building name in center
- **Placement Validation**:
  - Must be within map bounds
  - No occupied build grid cells (includes 1-cell spacing requirement)
  - At least half the building's tiles must be within the city's search area
  - Exception: Castle (first building) can be placed anywhere
  - Player must have sufficient gold
- **Placement Action**:
  - Click on valid location: Building placed, gold deducted, occupancy updated
  - Castle: Built immediately at 100% HP with full functionality
  - Other buildings: Spawned as construction sites (see Construction System)
  - Click on invalid location: No action taken
- **Grid Occupancy**:
  - Build grid occupancy updated when building placed
  - Pathfinding grid occupancy updated automatically
  - Both grids use reference counting for overlapping detection

### Construction System
- **Purpose**: Player-placed buildings (except Castle) must be built by Peasants
- **Construction Sites**:
  - Spawn at 10% of maximum HP (minimum 1 HP)
  - Display "(under construction)" suffix in name
  - Have UnderConstruction behavior (no functionality yet)
  - Only have Building tag initially
- **Building Process**:
  - Peasants automatically find and repair construction sites
  - Multiple Peasants can work on same site simultaneously
  - Each Peasant adds 5 HP every 0.15 seconds while within 48px
  - Construction site health bar shows progress to completion
- **Completion**:
  - When HP reaches 100% (max HP), construction completes automatically
  - Building transitions to proper behavior (e.g., GenerateGold)
  - Gains full set of tags (e.g., Guild, Coffer)
  - Begins functioning normally
  - "(under construction)" suffix removed

### Garrison System
- **Purpose**: System for housing henchmen units inside buildings
- **Garrison Slot Configuration**:
  - Buildings define garrison slots per unit type
  - Each slot specifies: unit type, max count, current count, spawn timer
  - Example (Castle): 3 Peasants, 1 Tax Collector, 2 Castle Guards
- **Spawning**:
  - Buildings automatically spawn henchmen every 30 seconds
  - Checks each slot type and spawns if under max count
  - Units spawn inside garrison (Garrisoned location)
  - Spawned units begin in Sleeping behavior
- **Entry and Exit**:
  - Units exit garrison at building entrance tile
  - Units enter garrison by moving within 32px of entrance
  - Location changes between OnMap (x, y) and Garrisoned (buildingId)
- **Death and Respawn**:
  - When henchman dies, garrison slot count decrements
  - After 30-second cooldown, new henchman spawns automatically
  - Maintains stable population of workers
- **Homeless Behavior**:
  - If home building is destroyed, henchman enters WithoutHome state
  - Dies after 15-30 seconds without home
- **UI Display**:
  - Selection panel shows garrison counts per unit type
  - Format: "Peasant: 2/3" (current/max)
  - Spawn timers visible in Info tab

### Units
- **Selectable**: Units are selectable things that can be clicked to view/interact
- **Mobile**: Units move across the map using pathfinding
- **Appearance**: Circular placeholder graphics (16px diameter, half of pathfinding cell)
  - Random colors for visual distinction
  - Text label showing unit type abbreviation
- **Selection Radius**: 32px diameter (2x visual size) for easier clicking
- **Unit Types**:
  - **Heroes**: Important named units with randomized names, hero classes, stats, inventory, and leveling (not yet implemented)
  - **Henchmen**: Anonymous worker units that maintain the kingdom
- **Properties**:
  - HP: Unit health points (current/max), displayed via health bar below unit
  - Movement Speed: Measured in grid cells per second
  - Owner: Player or Enemy
  - Location: OnMap (x, y coordinates) or Garrisoned (building ID)
  - Behavior: State machine controlling unit actions
  - Target Destination: Final pathfinding cell destination (when moving)
  - Unit Kind: Hero or Henchman
  - Home Building: ID of garrison building (for henchmen)
  - Tags: Collection of gameplay tags (Hero or Henchman tag)
  - Active/Search Radius: 192px/384px (approximately 3/6 build tiles)
- **Pathfinding Grid Occupancy**: Units occupy all pathfinding cells they touch
  - Circular unit (16px diameter) occupies 1 pathfinding cell
  - Occupancy updated automatically when units move or are created/destroyed
- **Minimap Representation**:
  - Player units: Aquamarine dots (3px, #7FFFD4)
  - Enemy units: Red dots (3px, #FF0000)
- **Path Visualization**: Selected unit's path shown as golden dots
- **Available Henchmen**:
  - **Peasant**: 50 HP, 2.0 cells/s speed
    - Builds construction sites and repairs damaged buildings
    - Uses Build ability: adds 5 HP every 0.15 seconds
    - Works within 48px radius of target building
    - Automatically finds nearest damaged building or construction site
    - Returns to garrison when no work available
  - **Tax Collector**: 50 HP, 1.5 cells/s speed
    - Collects gold from building coffers
    - Carries up to 250 gold before returning to Castle
    - Delivers gold to player at Castle
    - Collection takes 2-3 seconds per building
    - Delivery takes 2-3 seconds at Castle
  - **Castle Guard**: 50 HP, 2.0 cells/s speed
    - Defensive unit (not yet implemented)
    - Currently has no task behavior

### Behavior System
- **Purpose**: State machines that govern actions of units and buildings
- **Building Behaviors**:
  - **Idle**: Default state, building performs no actions
  - **UnderConstruction**: Construction site state, building non-functional
  - **SpawnHouse**: Castle behavior, spawns Houses every 30-45 seconds
  - **GenerateGold**: Generates gold into coffer every 15-45 seconds (amount varies by building)
  - **Dead**: Building destroyed (not yet implemented)
- **Common Unit Behaviors** (all henchmen):
  - **Sleeping**: Unit regenerates HP (10% max HP per second) while garrisoned
    - Checks for tasks every 1 second
    - Transitions to LookingForTask periodically
  - **LookingForTask**: Routes unit to appropriate task based on type
    - Peasant → LookForBuildRepairTarget
    - Tax Collector → LookForTaxTarget
    - Castle Guard → GoingToSleep (no tasks yet)
  - **GoingToSleep**: Unit moves back to home building entrance
    - Enters garrison when within 32 pixels
    - At each waypoint, interrupted to check for tasks
    - Transitions to Sleeping when garrisoned
  - **WithoutHome**: Unit's home building was destroyed
    - Dies after 15-30 seconds
  - **Dead**: Unit is dead, shows gray visuals
    - Lasts 45-60 seconds before removal (not yet implemented)
- **Peasant Behaviors**:
  - **LookForBuildRepairTarget**: Exit garrison and search for damaged buildings
    - Finds nearest building with HP < max HP
    - Requests pathfinding to target
    - Transitions to Repairing when path assigned
    - If no targets found, goes to sleep
  - **Repairing**: Build/repair target building
    - Works when within 48px of building
    - Uses Build ability every 0.15 seconds (adds 5 HP)
    - When building reaches max HP, looks for new target
- **Tax Collector Behaviors**:
  - **LookForTaxTarget**: Exit garrison and search for buildings with gold
    - Finds nearest building with coffer > 0
    - Requests pathfinding to target
    - Transitions to CollectingTaxes when adjacent
    - If no targets found, goes to sleep
  - **CollectingTaxes**: Collect gold from building coffer
    - Waits 2-3 seconds
    - Transfers all gold from coffer to carried storage
    - If storage ≥ 250 gold, returns to Castle
    - Otherwise, looks for more targets
  - **ReturnToCastle**: Move to Castle and enter garrison
    - Navigates to Castle entrance
    - Enters when within 32 pixels
    - Transitions to DeliverGold
  - **DeliverGold**: Transfer gold to player
    - Waits 2-3 seconds
    - Adds carried gold to player gold (green flash)
    - Empties storage
    - Returns to LookingForTask
- **State Display**: Current behavior shown in unit and building selection panels
- **Tooltips**: Hovering over behavior shows descriptive tooltip explaining the current state

### Tags System
- **Purpose**: Gameplay logic classification system for all entities
- **Available Tags**:
  - **Building**: Applied to all buildings
  - **Objective**: Applied to Castle (game over if destroyed)
  - **Coffer**: Applied to buildings that generate and store gold (House, Warrior's Guild)
  - **Guild**: Applied to guild buildings (Warrior's Guild)
  - **Hero**: Applied to hero units (not yet implemented)
  - **Henchman**: Applied to henchman units (Peasant, Tax Collector, Castle Guard)
- **Display**: Tags shown in selection panel below entity name as comma-separated list
- **Tooltips**: Hovering over tags shows description
- **Usage**: Enables flexible game logic based on entity classifications

### Tooltips
- **Hover System**: UI elements display tooltips after 0.5 seconds of hovering
- **Appearance**: Semi-transparent black background with higher opacity
- **Dismissal**: Tooltip vanishes when mouse leaves element
- **Current Implementation**:
  - Test Building button shows HP, Size, and Garrison information in tooltip
  - Tags show descriptions (e.g., "This is a building", "This is a hero", "This is a henchman")
  - Behaviors show state explanations (e.g., "The unit is pausing before deciding on next action")
  - Garrison display shows current units, capacity, and production time (not yet implemented)
- **Future Expansion**: Tooltips can expand right (extra info) or up (unit production)

### Health Bars
- **Visual**: Small bar below each building and unit
- **Color**: Dark blue (#2E4272)
- **Size**: 4px height for buildings, 3px for units
- **Display**: Percentage of current HP vs max HP shown as filled portion of bar

### Visual Animations
- **Purpose**: Show progress of time-based actions
- **Animation Timer**: Uses frame delta (separate from game simulation timer)
- **Time Guarantee**: Animation completes exactly when the timed action finishes
- **Shrinking Circle Animation**:
  - **Appearance**: Semi-transparent white circle with border
  - **Behavior**: Starts at maximum size and shrinks to a point over the duration
  - **Size**: Initial radius is 2x the visual size of the animated object
  - **Color**: rgba(255, 255, 255, 0.3) with rgba(255, 255, 255, 0.6) border
  - **Current Usage**: Displays on units during Thinking behavior (1-2 seconds)
  - **Position**: Centered on the animated object

### Pathfinding
- **Algorithm**: A* pathfinding with octile distance heuristic
- **Movement**: 8-directional (orthogonal and diagonal)
  - Orthogonal moves cost 1.0
  - Diagonal moves cost √2 (1.414)
- **Dynamic Recalculation**: Units recalculate paths every time they reach an intermediate cell
  - Enables units to avoid each other dynamically
  - Uses current occupancy grid state
  - Smooth collision avoidance without unit-to-unit communication
- **Occupancy Awareness**: Pathfinding avoids cells occupied by buildings or units
- **Path Storage**: Each unit stores its current path as list of grid cells

### Simulation
- **Game Loop**: Fixed timestep simulation independent of render rate
  - Simulation rate: 20 times per second (50ms timestep)
  - Render rate: Uses requestAnimationFrame (typically 60 FPS)
- **Speed Controls**: Radio buttons in debug menu control simulation speed
  - 0x: Paused
  - 1x: Normal speed
  - 2x: Double speed
  - 10x: 10x speed
  - 100x: 100x speed
- **Auto-Pause**: Simulation automatically pauses if delta time exceeds 1000ms
  - Prevents time jumps when tab is hidden or system lags
  - Visual indicator: "PAUSED" text appears next to gold counter
- **Debug Statistics**:
  - Simulation frame counter
  - Running average of last 3 simulation deltas
  - Available in Debug panel Stats tab

### Camera Controls
- **Main Viewport Dragging**: Click and hold anywhere on the terrain to drag the camera
- **Minimap Navigation**:
  - Click on background to center camera at that position
  - Click and drag on viewbox to pan smoothly while maintaining cursor position
  - Click and drag on background to center and then drag
  - Mouse capture: Dragging continues even when cursor leaves minimap bounds

### Visual Elements

#### Art Style
- **Placeholder Graphics**: All important game objects are represented by basic colored boxes
  - Text labels showing object names
  - Optional emoji/icon for visual distinction
  - Simple, functional design until proper graphics are implemented

#### Environment
- **Terrain**: Dark green background (#1a6b1a)
- **Decorative Elements**: 150 randomly placed shapes (circles and rectangles) in earth tones
  - Purpose: Purely cosmetic, helps visualize camera movement
  - Colors: Browns, tans, and greens
  - Size range: 20-80 pixels
- **Void**: Black area outside the playable map
  - Camera can scroll 500px beyond map edges

### UI Components
- **Global Buttons Panel**: Fixed buttons panel for always-accessible controls
  - Dimensions: 120px × 120px (square, fixed)
  - Responsive positioning:
    - When window is wide: Sticks to left edge of selection panel with 10px gap
    - When window is narrow: Flush to left edge of window (20px margin)
  - Contains two selectable buttons:
    - Debug button: Shows debug information and controls in selection panel
    - Build button: Shows available buildings in selection panel
  - Selected button displays yellow semi-transparent highlight overlay
  - Non-selected buttons have darker background (#333)
- **Selection Panel**: Docked flush to the left side of minimap
  - Displays information about currently selected thing
  - Dimensions: 120px height (fixed), 100-700px width (responsive)
  - Width scales with window size between minimum (100px) and maximum (700px)
  - Always positioned at bottom-right, aligned to minimap's left edge
  - Horizontal layout: Elements flow left to right with visible horizontal scrollbar
  - Scrollbar: 16px height, gray (#888) thumb on dark (#222) track with hover effect
  - Content based on current selection:
    - Nothing selected: Shows "No selection" message
    - Debug button: Tabbed interface with three tabs
      - Stats tab: Camera position, gold, simulation frame count, average delta time
      - Visualization tab: Grid visualization checkboxes (Build Grid, PF Grid, occupancy overlays)
      - Controls tab: Simulation speed radio buttons, gold setter, spawn test unit button, place test building button
    - Build button: Shows Castle button (pre-game) or Warrior's Guild button (playing)
      - Buttons disabled if insufficient gold
      - Active building button shows white highlight
    - Building selected: Tabbed interface with two tabs
      - Main tab: Name (with construction suffix if applicable), tags, HP, owner, garrison counts per unit type
      - Info tab: Current behavior, behavior timer, coffer amount (if Coffer tag), spawn cooldowns per garrison slot
    - Unit selected: Shows unit type, tags, HP, speed, owner, location, current behavior, carried gold (Tax Collector)
- **Minimap**: 200x150px in bottom-right corner
  - Shows entire map overview
  - Red viewport indicator shows current camera position
  - Player buildings shown in aquamarine (#7FFFD4)
  - Enemy buildings shown in red (#FF0000)
  - 10px padding inside for visible borders
  - Interactive: clickable and draggable
- **Gold Counter**: Positioned above minimap
  - Displays current gold amount
  - Gold coin icon with monospace numeric display

## Technical Details

### Built With
- Elm 0.19.1
- Pure CSS for styling (HTML divs, no SVG)
- No external game engines

### Compilation
```bash
elm make src/Main.elm --output=elm.js
```

This compiles the Elm code to `elm.js`, which is loaded by the static `index.html` file.

### Running
Open `index.html` in a web browser.
