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
- `CLAUDE.md` - This file (assistant notes)
