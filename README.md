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
- **Currently Selectable**: Global buttons (Debug, Build) and buildings
- **Deselection**: User cannot manually deselect
  - Zero selected only at game start or if selected thing is removed from game
- **Selection Highlight**: Semi-transparent yellow overlay with glow effect
  - Always visible when selected thing is on screen
  - Color: rgba(255, 215, 0, 0.3) with golden box shadow
- **No Selection State**: Selection panel shows "No selection" text in gray italic

### Resources
- **Gold**: The primary resource in the game
  - Starting amount: 10,000
  - Displayed in top-right corner above minimap
  - Visual representation: Yellow circular coin icon with gold-colored number

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
  - HP: Building health points (current/max)
  - Garrison Slots: Number of units that can be garrisoned
  - Cost: Gold required to construct
  - Owner: Player or Enemy
  - Behavior: State machine controlling actions (currently only Idle state)
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
  - **Test Building**: 500 gold, 2×2 size, 500 HP, 5 garrison slots

### Build Mode
- **Activation**: Click a building button in the Build menu (only enabled if sufficient gold)
- **Visual Indicator**: Active building button shows white semi-transparent highlight overlay
- **Cancellation**: Click the active building button again, or switch away from Build menu
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
  - Player must have sufficient gold
- **Placement Action**:
  - Click on valid location: Building placed, gold deducted, occupancy updated
  - Click on invalid location: No action taken
- **Grid Occupancy**:
  - Build grid occupancy updated when building placed
  - Pathfinding grid occupancy updated automatically
  - Both grids use reference counting for overlapping detection

### Units
- **Selectable**: Units are selectable things that can be clicked to view/interact
- **Mobile**: Units move across the map using pathfinding
- **Appearance**: Circular placeholder graphics (16px diameter, half of pathfinding cell)
  - Random colors for visual distinction
  - Text label "U" in center
- **Selection Radius**: 32px diameter (2x visual size) for easier clicking
- **Properties**:
  - HP: Unit health points (current/max)
  - Movement Speed: Measured in grid cells per second (default: 2.5)
  - Owner: Player or Enemy
  - Location: OnMap (x, y coordinates) or Garrisoned (building ID)
  - Behavior: State machine controlling unit actions
  - Target Destination: Final pathfinding cell destination (when moving)
- **Pathfinding Grid Occupancy**: Units occupy all pathfinding cells they touch
  - Circular unit (16px diameter) occupies 1 pathfinding cell
  - Occupancy updated automatically when units move or are created/destroyed
- **Minimap Representation**:
  - Player units: Aquamarine dots (3px, #7FFFD4)
  - Enemy units: Red dots (3px, #FF0000)
- **Path Visualization**: Selected unit's path shown as golden dots
- **Available Units**:
  - **Test Unit**: 100 HP, 2.5 cells/s speed, random behavior pattern

### Behavior System
- **Purpose**: State machines that govern actions of units and buildings
- **Building Behaviors**:
  - **Idle**: Default state, building performs no actions
- **Unit Behaviors** (Test Unit):
  - **Thinking**: Brief pause (0.1-0.5 seconds) before deciding next action
    - Duration varies per unit using unit ID as seed
    - Transitions to FindingRandomTarget when timer expires
  - **FindingRandomTarget**: Request pathfinding to random location
    - Picks random cell within 10 tiles of current position
    - Transitions to MovingTowardTarget when path is assigned
  - **MovingTowardTarget**: Following calculated path to destination
    - Moves along path at unit's movement speed
    - Returns to Thinking when destination reached
- **State Display**: Current behavior shown in unit selection panel

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
      - Controls tab: Simulation speed radio buttons, gold setter, spawn test unit button
    - Build button: Shows available buildings (Test Building: 500g)
    - Building selected: Shows building name, HP, garrison info, owner
    - Unit selected: Shows unit type, HP, speed, owner, location (rounded), current behavior
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
elm make src/Main.elm --output=index.html
```

### Running
Open `index.html` in a web browser.
