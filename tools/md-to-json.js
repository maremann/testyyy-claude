#!/usr/bin/env node

/**
 * Markdown to JSON Behavior Compiler
 *
 * Converts behavior specification markdown files to structured JSON
 * Usage: node md-to-json.js <input.md> <output.json>
 */

const fs = require('fs');
const path = require('path');
const Ajv = require('ajv');

// Parse command line arguments
const args = process.argv.slice(2);
if (args.length < 2) {
    console.error('Usage: node md-to-json.js <input.md> <output.json>');
    process.exit(1);
}

const inputFile = args[0];
const outputFile = args[1];

// Read input markdown file
let markdown;
try {
    markdown = fs.readFileSync(inputFile, 'utf8');
} catch (err) {
    console.error(`Error reading input file: ${err.message}`);
    process.exit(1);
}

console.log(`Parsing ${inputFile}...`);

// Initialize output structure
const output = {
    behaviorId: '',
    unitType: '',
    inherits: null,
    description: '',
    strategicBehaviors: [],
    tacticalBehaviors: [],
    operationalBehaviors: [],
    awarenessTypes: {
        active: [],
        passive: []
    },
    stateData: {}
};

// Extract header metadata
function extractMetadata(md) {
    // Extract title (# Title)
    const titleMatch = md.match(/^#\s+(.+)$/m);
    if (titleMatch) {
        output.unitType = titleMatch[1].replace(' Behavior', '').trim();
    }

    // Extract Behavior ID
    const behaviorIdMatch = md.match(/\*\*Behavior ID\*\*:\s*(.+)$/m);
    if (behaviorIdMatch) {
        output.behaviorId = behaviorIdMatch[1].trim();
    }

    // Extract Unit Type (redundant check)
    const unitTypeMatch = md.match(/\*\*Unit Type\*\*:\s*(.+)$/m);
    if (unitTypeMatch) {
        output.unitType = unitTypeMatch[1].trim();
    }

    // Extract Inherits
    const inheritsMatch = md.match(/\*\*Inherits\*\*:\s*(.+)$/m);
    if (inheritsMatch) {
        output.inherits = inheritsMatch[1].trim();
    }

    // Extract Description (paragraph after ## Description)
    const descMatch = md.match(/##\s+Description\s+(.+?)(?=\n##|\n---)/s);
    if (descMatch) {
        output.description = descMatch[1].trim();
    }
}

// Extract strategic behaviors
function extractStrategicBehaviors(md) {
    const strategicSection = md.match(/##\s+Strategic Behaviors(.+?)(?=##\s+Tactical Behaviors|---)/s);
    if (!strategicSection) return;

    const content = strategicSection[1];

    // Match each ### heading as a strategic behavior
    const behaviorPattern = /###\s+(.+?)\n([\s\S]+?)(?=###|##|---)/g;
    let match;

    while ((match = behaviorPattern.exec(content)) !== null) {
        const name = match[1].trim();
        const body = match[2];

        const strategic = {
            strategicId: name,
            description: '',
            priority: 'Normal',
            tacticalDelegates: [],
            awarenessTypes: [],
            transitions: []
        };

        // Extract description
        const descMatch = body.match(/-\s+\*\*Description\*\*:\s*(.+?)(?=\n-|\n\*\*|$)/s);
        if (descMatch) {
            strategic.description = descMatch[1].trim();
        }

        // Extract priority
        const priorityMatch = body.match(/-\s+\*\*Priority\*\*:\s*(.+)$/m);
        if (priorityMatch) {
            strategic.priority = priorityMatch[1].trim();
        }

        // Extract tactical delegates
        const delegatesMatch = body.match(/-\s+\*\*Tactical (?:Delegates|Behaviors)\*\*:?\s*\n((?:\s+\d+\.\s+.+\n?)+)/);
        if (delegatesMatch) {
            const delegates = delegatesMatch[1].match(/\d+\.\s+(.+?)(?=\s+\(|$)/gm);
            if (delegates) {
                strategic.tacticalDelegates = delegates.map(d => d.replace(/^\d+\.\s+/, '').trim());
            }
        }

        // Extract awareness types
        const awarenessMatch = body.match(/-\s+\*\*Awareness\*\*:\s*(.+)$/m);
        if (awarenessMatch) {
            const awarenessStr = awarenessMatch[1];
            strategic.awarenessTypes = awarenessStr.split(',').map(a =>
                a.replace(/\(active\)|\(passive\)/g, '').trim()
            );
        }

        // Extract transitions
        const transitionsMatch = body.match(/-\s+\*\*Transitions\*\*:\s*\n((?:\s+-\s+.+\n?)+)/);
        if (transitionsMatch) {
            const transitionLines = transitionsMatch[1].match(/-\s+If\s+(.+?)\s+→\s+(.+?)(?:\s+\(|$)/gm);
            if (transitionLines) {
                strategic.transitions = transitionLines.map(line => {
                    const parts = line.match(/-\s+If\s+(.+?)\s+→\s+(.+?)(?:\s+\(|$)/);
                    if (parts) {
                        return {
                            condition: parts[1].trim(),
                            target: parts[2].trim()
                        };
                    }
                    return null;
                }).filter(t => t !== null);
            }
        }

        output.strategicBehaviors.push(strategic);
    }
}

// Extract tactical behaviors
function extractTacticalBehaviors(md) {
    const tacticalSection = md.match(/##\s+Tactical Behaviors(.+?)(?=##\s+Operational Behaviors)/s);
    if (!tacticalSection) return;

    const content = tacticalSection[1];

    const behaviorPattern = /###\s+(.+?)\n([\s\S]+?)(?=###|##|---)/g;
    let match;

    while ((match = behaviorPattern.exec(content)) !== null) {
        const name = match[1].trim();
        const body = match[2];

        const tactical = {
            tacticalId: name,
            description: '',
            priority: 'Normal',
            operationalSequence: [],
            awarenessTypes: [],
            successCondition: '',
            failureCondition: '',
            interruptible: true,
            transitions: []
        };

        // Extract description
        const descMatch = body.match(/-\s+\*\*Description\*\*:\s*(.+?)(?=\n-|\n\*\*|$)/s);
        if (descMatch) {
            tactical.description = descMatch[1].trim();
        }

        // Extract priority
        const priorityMatch = body.match(/-\s+\*\*Priority\*\*:\s*(.+?)(?:\s+\(|$)/m);
        if (priorityMatch) {
            tactical.priority = priorityMatch[1].trim();
        }

        // Extract operational sequence
        const sequenceMatch = body.match(/-\s+\*\*Operational Sequence\*\*:\s*\n((?:\s+\d+\.\s+.+\n?)+)/);
        if (sequenceMatch) {
            const steps = sequenceMatch[1].match(/\d+\.\s+([^(\n]+)/gm);
            if (steps) {
                tactical.operationalSequence = steps.map(s =>
                    s.replace(/^\d+\.\s+/, '').replace(/\s*\(.*$/, '').trim()
                );
            }
        }

        // Extract awareness
        const awarenessMatch = body.match(/-\s+\*\*Awareness\*\*:\s*(.+)$/m);
        if (awarenessMatch) {
            const awarenessStr = awarenessMatch[1];
            tactical.awarenessTypes = awarenessStr.split(',').map(a =>
                a.replace(/\(active\)|\(passive\)/g, '').trim()
            );
        }

        // Extract success condition
        const successMatch = body.match(/-\s+\*\*Success\*\*:\s*(.+)$/m);
        if (successMatch) {
            tactical.successCondition = successMatch[1].trim();
        }

        // Extract failure condition
        const failureMatch = body.match(/-\s+\*\*Failure\*\*:\s*(.+)$/m);
        if (failureMatch) {
            tactical.failureCondition = failureMatch[1].trim();
        }

        // Check interruptible
        const interruptsMatch = body.match(/-\s+\*\*Interrupts\*\*:\s*(.+)$/m);
        if (interruptsMatch && interruptsMatch[1].includes('None')) {
            tactical.interruptible = false;
        }

        // Extract transitions
        const transitionsMatch = body.match(/-\s+\*\*Transitions\*\*:\s*\n((?:\s+-\s+.+\n?)+)/);
        if (transitionsMatch) {
            const transitionLines = transitionsMatch[1].match(/-\s+(.+?)\s+→\s+(.+?)(?:\s+\(|$)/gm);
            if (transitionLines) {
                tactical.transitions = transitionLines.map(line => {
                    const parts = line.match(/-\s+(.+?)\s+→\s+(.+?)(?:\s+\(|$)/);
                    if (parts) {
                        return {
                            condition: parts[1].trim(),
                            target: parts[2].trim()
                        };
                    }
                    return null;
                }).filter(t => t !== null);
            }
        }

        output.tacticalBehaviors.push(tactical);
    }
}

// Extract operational behaviors
function extractOperationalBehaviors(md) {
    const operationalSection = md.match(/##\s+Operational Behaviors(.+?)(?=##\s+Awareness System)/s);
    if (!operationalSection) return;

    const content = operationalSection[1];

    const behaviorPattern = /###\s+(.+?)\n([\s\S]+?)(?=###|##|---)/g;
    let match;

    while ((match = behaviorPattern.exec(content)) !== null) {
        const name = match[1].trim();
        const body = match[2];

        const operational = {
            operationalId: name,
            description: '',
            action: '',
            parameters: {},
            duration: null,
            successCondition: '',
            failureCondition: '',
            sideEffects: [],
            result: []
        };

        // Extract description
        const descMatch = body.match(/-\s+\*\*Description\*\*:\s*(.+?)(?=\n-|\n\*\*|$)/s);
        if (descMatch) {
            operational.description = descMatch[1].trim();
        }

        // Extract action
        const actionMatch = body.match(/-\s+\*\*Action\*\*:\s*(.+)$/m);
        if (actionMatch) {
            operational.action = actionMatch[1].trim();
        }

        // Extract duration
        const durationMatch = body.match(/-\s+\*\*Duration\*\*:\s*(.+)$/m);
        if (durationMatch) {
            const durStr = durationMatch[1].trim();
            // Try to parse as number, otherwise keep as string
            const durNum = parseFloat(durStr);
            operational.duration = isNaN(durNum) ? durStr : durNum;
        }

        // Extract parameters
        const paramsMatch = body.match(/-\s+\*\*Parameters\*\*:\s*\n((?:\s+-\s+.+\n?)+)/);
        if (paramsMatch) {
            const paramLines = paramsMatch[1].match(/-\s+(.+?):\s+(.+)$/gm);
            if (paramLines) {
                paramLines.forEach(line => {
                    const parts = line.match(/-\s+(.+?):\s+(.+)$/);
                    if (parts) {
                        operational.parameters[parts[1].trim()] = parts[2].trim();
                    }
                });
            }
        }

        // Extract success condition
        const successMatch = body.match(/-\s+\*\*Success\*\*:\s*(.+)$/m);
        if (successMatch) {
            operational.successCondition = successMatch[1].trim();
        }

        // Extract failure condition
        const failureMatch = body.match(/-\s+\*\*Failure\*\*:\s*(.+)$/m);
        if (failureMatch) {
            operational.failureCondition = failureMatch[1].trim();
        }

        // Extract side effects
        const sideEffectsMatch = body.match(/-\s+\*\*Side Effects\*\*:\s*(.+)$/m);
        if (sideEffectsMatch) {
            operational.sideEffects = [sideEffectsMatch[1].trim()];
        }

        // Extract result values
        const resultMatch = body.match(/-\s+\*\*Result\*\*:\s*\n((?:\s+-\s+.+\n?)+)/);
        if (resultMatch) {
            const resultLines = resultMatch[1].match(/-\s+([^(\n]+)/gm);
            if (resultLines) {
                operational.result = resultLines.map(r =>
                    r.replace(/^-\s+/, '').replace(/\s*\(.*$/, '').trim()
                );
            }
        }

        output.operationalBehaviors.push(operational);
    }
}

// Extract awareness types
function extractAwarenessTypes(md) {
    const awarenessSection = md.match(/##\s+Awareness System(.+?)(?=##\s+State Transitions|##\s+Priority)/s);
    if (!awarenessSection) return;

    const content = awarenessSection[1];

    // Extract active awareness
    const activeSection = content.match(/###\s+Active Awareness[\s\S]+?(####[\s\S]+?)(?=###\s+Passive|##|$)/);
    if (activeSection) {
        const activeContent = activeSection[1];
        const awarenessPattern = /####\s+(.+?)\n([\s\S]+?)(?=####|###|##|$)/g;
        let match;

        while ((match = awarenessPattern.exec(activeContent)) !== null) {
            const name = match[1].trim();
            const body = match[2];

            const awareness = {
                awarenessId: name,
                description: '',
                scanRadius: null,
                triggerCondition: '',
                forcedBehavior: '',
                priority: 'Critical',
                stores: []
            };

            // Extract description
            const descMatch = body.match(/-\s+\*\*Description\*\*:\s*(.+?)(?=\n-|\n\*\*|$)/s);
            if (descMatch) {
                awareness.description = descMatch[1].trim();
            }

            // Extract scan radius
            const radiusMatch = body.match(/-\s+\*\*Scan Radius\*\*:\s*(.+)$/m);
            if (radiusMatch) {
                const radiusStr = radiusMatch[1].trim();
                const radiusNum = parseInt(radiusStr);
                awareness.scanRadius = isNaN(radiusNum) ? radiusStr : radiusNum;
            }

            // Extract trigger condition
            const triggerMatch = body.match(/-\s+\*\*Trigger(?:\s+Condition)?\*\*:\s*(.+)$/m);
            if (triggerMatch) {
                awareness.triggerCondition = triggerMatch[1].trim();
            }

            // Extract forced behavior
            const forcedMatch = body.match(/-\s+\*\*Forced Behavior\*\*:\s*(.+)$/m);
            if (forcedMatch) {
                awareness.forcedBehavior = forcedMatch[1].trim();
            }

            // Extract priority
            const priorityMatch = body.match(/-\s+\*\*Priority\*\*:\s*(.+)$/m);
            if (priorityMatch) {
                awareness.priority = priorityMatch[1].trim();
            }

            output.awarenessTypes.active.push(awareness);
        }
    }

    // Extract passive awareness
    const passiveSection = content.match(/###\s+Passive Awareness[\s\S]+?(####[\s\S]+?)(?=###|##|$)/);
    if (passiveSection) {
        const passiveContent = passiveSection[1];
        const awarenessPattern = /####\s+(.+?)\n([\s\S]+?)(?=####|###|##|$)/g;
        let match;

        while ((match = awarenessPattern.exec(passiveContent)) !== null) {
            const name = match[1].trim();
            const body = match[2];

            const awareness = {
                awarenessId: name,
                description: '',
                stores: [],
                influences: []
            };

            // Extract description
            const descMatch = body.match(/-\s+\*\*Description\*\*:\s*(.+?)(?=\n-|\n\*\*|$)/s);
            if (descMatch) {
                awareness.description = descMatch[1].trim();
            }

            // Extract stores
            const storesMatch = body.match(/-\s+\*\*Stores\*\*:\s*(.+)$/m);
            if (storesMatch) {
                awareness.stores = [storesMatch[1].trim()];
            }

            // Extract influences
            const influencesMatch = body.match(/-\s+\*\*Influences\*\*:\s*(.+)$/m);
            if (influencesMatch) {
                awareness.influences = [influencesMatch[1].trim()];
            }

            output.awarenessTypes.passive.push(awareness);
        }
    }
}

// Parse the markdown
try {
    extractMetadata(markdown);
    extractStrategicBehaviors(markdown);
    extractTacticalBehaviors(markdown);
    extractOperationalBehaviors(markdown);
    extractAwarenessTypes(markdown);

    console.log(`Found:`);
    console.log(`  - ${output.strategicBehaviors.length} strategic behaviors`);
    console.log(`  - ${output.tacticalBehaviors.length} tactical behaviors`);
    console.log(`  - ${output.operationalBehaviors.length} operational behaviors`);
    console.log(`  - ${output.awarenessTypes.active.length} active awareness types`);
    console.log(`  - ${output.awarenessTypes.passive.length} passive awareness types`);

    // Validate against schema
    console.log(`\nValidating against schema...`);
    const schemaPath = path.join(__dirname, 'behavior-schema.json');
    const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));

    const ajv = new Ajv({ allErrors: true, allowUnionTypes: true });
    const validate = ajv.compile(schema);
    const valid = validate(output);

    if (!valid) {
        console.error('\nSchema validation failed:');
        validate.errors.forEach(error => {
            console.error(`  - ${error.instancePath}: ${error.message}`);
        });
        process.exit(1);
    }

    console.log('✓ Schema validation passed');

    // Write output JSON
    const jsonOutput = JSON.stringify(output, null, 2);
    fs.writeFileSync(outputFile, jsonOutput, 'utf8');
    console.log(`\nSuccessfully wrote ${outputFile}`);

} catch (err) {
    console.error(`Error parsing markdown: ${err.message}`);
    console.error(err.stack);
    process.exit(1);
}
