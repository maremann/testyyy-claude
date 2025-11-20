#!/usr/bin/env node

/**
 * JSON → Elm Code Generator
 *
 * Takes behavior specification JSON and generates Elm code
 * for integration with BehaviorEngine
 */

const fs = require('fs');

if (process.argv.length < 4) {
    console.log('Usage: node json-to-elm.js <input.json> <output.elm>');
    process.exit(1);
}

const inputFile = process.argv[2];
const outputFile = process.argv[3];

console.log(`Generating Elm code from ${inputFile}...`);

// Read and parse JSON
const jsonContent = fs.readFileSync(inputFile, 'utf8');
const spec = JSON.parse(jsonContent);

// Generate Elm module
const elmCode = generateElmModule(spec);

// Write output
fs.writeFileSync(outputFile, elmCode, 'utf8');

console.log(`Successfully wrote ${outputFile}`);
console.log(`Generated code for ${spec.unitType}`);

// ============================================================================
// ELM CODE GENERATION
// ============================================================================

function generateElmModule(spec) {
    const moduleName = toElmModuleName(spec.behaviorId);
    const unitType = spec.unitType;

    let code = '';

    // Module declaration
    code += generateModuleHeader(moduleName, unitType);
    code += '\n\n';

    // Imports
    code += generateImports();
    code += '\n\n';

    // Type aliases for state data
    code += generateStateTypes(spec);
    code += '\n\n';

    // Strategic behavior type
    code += generateStrategicBehaviorType(spec);
    code += '\n\n';

    // Tactical behavior type
    code += generateTacticalBehaviorType(spec);
    code += '\n\n';

    // Operational behavior type
    code += generateOperationalBehaviorType(spec);
    code += '\n\n';

    // Initial state function
    code += generateInitialState(spec);
    code += '\n\n';

    // Update function (main entry point)
    code += generateUpdateFunction(spec);
    code += '\n\n';

    // Strategic behavior handlers
    code += generateStrategicHandlers(spec);
    code += '\n\n';

    // Tactical behavior handlers
    code += generateTacticalHandlers(spec);
    code += '\n\n';

    // Operational behavior handlers
    code += generateOperationalHandlers(spec);
    code += '\n\n';

    // Awareness functions
    code += generateAwarenessFunctions(spec);

    return code;
}

function generateModuleHeader(moduleName, unitType) {
    return `module BehaviorEngine.Units.${moduleName} exposing
    ( ${moduleName}State
    , init${moduleName}State
    , update${moduleName}
    )

{-| ${unitType} Behavior Implementation

Generated from behavior specification.

@docs ${moduleName}State, init${moduleName}State, update${moduleName}
-}`;
}

function generateImports() {
    return `import BehaviorEngine.Types exposing (..)
import BehaviorEngine.Actions as Actions
import Types exposing (..)`;
}

function generateStateTypes(spec) {
    const moduleName = toElmModuleName(spec.behaviorId);

    let code = `{-| State data for ${spec.unitType}
-}
type alias ${moduleName}State =
    { currentStrategic : Strategic${moduleName}
    , currentTactical : Maybe Tactical${moduleName}
    , currentOperational : Maybe Operational${moduleName}
    , patrolRoute : List Int
    , patrolIndex : Int
    , perimeterPoints : List ( Int, Int )
    , perimeterIndex : Int
    , engagedTarget : Maybe Int
    , interruptState : Maybe InterruptState
    }


type alias InterruptState =
    { previousTactical : Tactical${moduleName}
    , previousOperationalIndex : Int
    }`;

    return code;
}

function generateStrategicBehaviorType(spec) {
    const moduleName = toElmModuleName(spec.behaviorId);

    const variants = spec.strategicBehaviors.map(s =>
        `    | ${toElmTypeName(s.strategicId)}`
    ).join('\n');

    return `{-| Strategic behaviors for ${spec.unitType}
-}
type Strategic${moduleName}
${variants}
    | WithoutHome`;
}

function generateTacticalBehaviorType(spec) {
    const moduleName = toElmModuleName(spec.behaviorId);

    const variants = spec.tacticalBehaviors.map(t =>
        `    | ${toElmTypeName(t.tacticalId)}`
    ).join('\n');

    return `{-| Tactical behaviors for ${spec.unitType}
-}
type Tactical${moduleName}
${variants}
    | TacticalIdle`;
}

function generateOperationalBehaviorType(spec) {
    const moduleName = toElmModuleName(spec.behaviorId);

    const variants = spec.operationalBehaviors.map(o =>
        `    | ${toElmTypeName(o.operationalId)}`
    ).join('\n');

    return `{-| Operational behaviors for ${spec.unitType}
-}
type Operational${moduleName}
${variants}
    | OperationalIdle`;
}

function generateInitialState(spec) {
    const moduleName = toElmModuleName(spec.behaviorId);
    const firstStrategic = spec.strategicBehaviors[0];
    const firstStrategicName = toElmTypeName(firstStrategic.strategicId);

    return `{-| Initialize state for ${spec.unitType}
-}
init${moduleName}State : ${moduleName}State
init${moduleName}State =
    { currentStrategic = ${firstStrategicName}
    , currentTactical = Nothing
    , currentOperational = Nothing
    , patrolRoute = []
    , patrolIndex = 0
    , perimeterPoints = []
    , perimeterIndex = 0
    , engagedTarget = Nothing
    , interruptState = Nothing
    }`;
}

function generateUpdateFunction(spec) {
    const moduleName = toElmModuleName(spec.behaviorId);

    return `{-| Main update function for ${spec.unitType}
-}
update${moduleName} : BehaviorContext -> ${moduleName}State -> ( Unit, ${moduleName}State, Bool )
update${moduleName} context state =
    let
        -- Check active awareness (interrupts)
        activeAwareness = checkActiveAwareness${moduleName} context state

        -- Handle interrupt if triggered
        ( interruptedState, wasInterrupted ) =
            case activeAwareness of
                Just trigger ->
                    handleInterrupt${moduleName} state trigger

                Nothing ->
                    ( state, False )

        -- Execute current behavior
        ( updatedUnit, updatedState, needsPath ) =
            if wasInterrupted then
                executeStrategic${moduleName} context interruptedState
            else
                executeStrategic${moduleName} context state
    in
    ( updatedUnit, updatedState, needsPath )`;
}

function generateStrategicHandlers(spec) {
    const moduleName = toElmModuleName(spec.behaviorId);

    let code = `-- STRATEGIC BEHAVIOR HANDLERS\n\n`;

    code += `executeStrategic${moduleName} : BehaviorContext -> ${moduleName}State -> ( Unit, ${moduleName}State, Bool )
executeStrategic${moduleName} context state =
    case state.currentStrategic of\n`;

    spec.strategicBehaviors.forEach(strategic => {
        const typeName = toElmTypeName(strategic.strategicId);
        code += `        ${typeName} ->\n`;
        code += `            handleStrategic${typeName} context state\n\n`;
    });

    code += `        WithoutHome ->\n`;
    code += `            -- Unit is homeless, no actions\n`;
    code += `            ( context.unit, state, False )\n\n`;

    // Generate handler functions for each strategic behavior
    spec.strategicBehaviors.forEach(strategic => {
        const typeName = toElmTypeName(strategic.strategicId);
        code += `\nhandleStrategic${typeName} : BehaviorContext -> ${moduleName}State -> ( Unit, ${moduleName}State, Bool )
handleStrategic${typeName} context state =
    -- Delegates to tactical behaviors: ${strategic.tacticalDelegates.join(', ')}
    case state.currentTactical of
        Nothing ->
            -- Start with first tactical delegate
            let
                newState = { state | currentTactical = Just ${toElmTypeName(strategic.tacticalDelegates[0])} }
            in
            executeTactical${moduleName} context newState

        Just tactical ->
            executeTactical${moduleName} context state\n`;
    });

    return code;
}

function generateTacticalHandlers(spec) {
    const moduleName = toElmModuleName(spec.behaviorId);

    let code = `-- TACTICAL BEHAVIOR HANDLERS\n\n`;

    code += `executeTactical${moduleName} : BehaviorContext -> ${moduleName}State -> ( Unit, ${moduleName}State, Bool )
executeTactical${moduleName} context state =
    case state.currentTactical of
        Nothing ->
            ( context.unit, state, False )
\n`;

    spec.tacticalBehaviors.forEach(tactical => {
        const typeName = toElmTypeName(tactical.tacticalId);
        code += `        Just ${typeName} ->\n`;
        code += `            handleTactical${typeName} context state\n\n`;
    });

    code += `        Just TacticalIdle ->\n`;
    code += `            ( context.unit, state, False )\n\n`;

    // Generate handler functions for each tactical behavior
    spec.tacticalBehaviors.forEach((tactical, idx) => {
        const typeName = toElmTypeName(tactical.tacticalId);
        const sequence = tactical.operationalSequence;

        code += `\nhandleTactical${typeName} : BehaviorContext -> ${moduleName}State -> ( Unit, ${moduleName}State, Bool )
handleTactical${typeName} context state =
    -- Operational sequence: ${sequence.slice(0, 3).join(', ')}...
    -- Success: ${tactical.successCondition}
    -- Failure: ${tactical.failureCondition}
    case state.currentOperational of
        Nothing ->
            -- Start with first operational step
            let
                firstOp = ${sequence.length > 0 ? toElmTypeName(sequence[0]) : 'OperationalIdle'}
                newState = { state | currentOperational = Just firstOp }
            in
            executeOperational${moduleName} context newState

        Just operational ->
            executeOperational${moduleName} context state\n`;
    });

    code += `\n        Just TacticalIdle ->
            ( context.unit, state, False )\n`;

    return code;
}

function generateOperationalHandlers(spec) {
    const moduleName = toElmModuleName(spec.behaviorId);

    let code = `-- OPERATIONAL BEHAVIOR HANDLERS\n\n`;

    code += `executeOperational${moduleName} : BehaviorContext -> ${moduleName}State -> ( Unit, ${moduleName}State, Bool )
executeOperational${moduleName} context state =
    case state.currentOperational of
        Nothing ->
            ( context.unit, state, False )
\n`;

    spec.operationalBehaviors.forEach(operational => {
        const typeName = toElmTypeName(operational.operationalId);
        code += `        Just ${typeName} ->\n`;
        code += `            handleOperational${typeName} context state\n\n`;
    });

    code += `        Just OperationalIdle ->\n`;
    code += `            ( context.unit, state, False )\n\n`;

    // Generate handler functions for each operational behavior
    spec.operationalBehaviors.forEach(operational => {
        const typeName = toElmTypeName(operational.operationalId);
        const action = operational.action || 'NoAction';

        code += `\nhandleOperational${typeName} : BehaviorContext -> ${moduleName}State -> ( Unit, ${moduleName}State, Bool )
handleOperational${typeName} context state =
    -- Action: ${action}
    -- Success: ${operational.successCondition}
    -- TODO: Implement operational logic
    ( context.unit, state, False )\n`;
    });

    return code;
}

function generateAwarenessFunctions(spec) {
    const moduleName = toElmModuleName(spec.behaviorId);

    let code = `-- AWARENESS FUNCTIONS\n\n`;

    code += `checkActiveAwareness${moduleName} : BehaviorContext -> ${moduleName}State -> Maybe ActiveAwarenessTrigger
checkActiveAwareness${moduleName} context state =
    -- Active awareness types: ${spec.awarenessTypes.active.map(a => a.awarenessId).join(', ')}
    `;

    if (spec.awarenessTypes.active.length > 0) {
        spec.awarenessTypes.active.forEach((awareness, idx) => {
            if (idx > 0) code += `    else`;
            code += `if check${toElmTypeName(awareness.awarenessId)} context then
        Just
            { awarenessType = "${awareness.awarenessId}"
            , forcedTactical = ${toElmTypeName(awareness.forcedBehavior)}
            , priority = ${awareness.priority}
            }
    `;
        });
        code += `else
        Nothing\n\n`;
    } else {
        code += `Nothing\n\n`;
    }

    // Generate check functions for each active awareness
    spec.awarenessTypes.active.forEach(awareness => {
        const typeName = toElmTypeName(awareness.awarenessId);
        code += `\ncheck${typeName} : BehaviorContext -> Bool
check${typeName} context =
    -- ${awareness.description}
    -- Trigger: ${awareness.triggerCondition}
    -- TODO: Implement awareness check
    False\n`;
    });

    code += `\n\nhandleInterrupt${moduleName} : ${moduleName}State -> ActiveAwarenessTrigger -> ( ${moduleName}State, Bool )
handleInterrupt${moduleName} state trigger =
    -- Save current state for potential resume
    let
        interruptState =
            case state.currentTactical of
                Just tactical ->
                    Just { previousTactical = tactical, previousOperationalIndex = 0 }

                Nothing ->
                    Nothing

        newState =
            { state
                | currentTactical = Just trigger.forcedTactical
                , currentOperational = Nothing
                , interruptState = interruptState
            }
    in
    ( newState, True )\n\n`;

    code += `\ntype alias ActiveAwarenessTrigger =
    { awarenessType : String
    , forcedTactical : Tactical${moduleName}
    , priority : Priority
    }\n`;

    return code;
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

function toElmModuleName(str) {
    // Convert "castle_guard_patrol" to "CastleGuardPatrol"
    return str.split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join('');
}

function toElmTypeName(str) {
    // Convert "PlanPatrolRoute" or "plan_patrol_route" to "PlanPatrolRoute"
    // Remove parentheses and "from CORE" annotations
    str = str.replace(/\s*\(.*?\)\s*/g, '').trim();
    str = str.replace(/\s+from\s+CORE/i, '').trim();

    // Handle snake_case
    if (str.includes('_')) {
        return str.split('_')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
            .join('');
    }

    // Handle spaces
    if (str.includes(' ')) {
        return str.split(' ')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
            .join('');
    }

    // Already PascalCase - just ensure first letter is uppercase
    return str.charAt(0).toUpperCase() + str.slice(1);
}
