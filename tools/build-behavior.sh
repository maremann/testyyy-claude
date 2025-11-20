#!/bin/bash

# Build Behavior Pipeline
# Converts markdown behavior spec → JSON → Elm code
#
# Usage: ./build-behavior.sh <behavior-name>
# Example: ./build-behavior.sh castle_guard

set -e

if [ $# -lt 1 ]; then
    echo "Usage: ./build-behavior.sh <behavior-name>"
    echo "Example: ./build-behavior.sh castle_guard"
    exit 1
fi

BEHAVIOR_NAME=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

MARKDOWN_FILE="$PROJECT_ROOT/behaviors/design/${BEHAVIOR_NAME}.md"
JSON_FILE="$PROJECT_ROOT/behaviors/compiled/${BEHAVIOR_NAME}.json"

# Convert snake_case to PascalCase (works on both BSD and GNU sed)
MODULE_NAME=$(echo "$BEHAVIOR_NAME" | awk -F_ '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1' OFS="")
ELM_FILE="$PROJECT_ROOT/src/BehaviorEngine/Units/${MODULE_NAME}.elm"

echo "========================================"
echo "Behavior Build Pipeline"
echo "========================================"
echo "Behavior: $BEHAVIOR_NAME"
echo ""

# Step 1: Markdown → JSON (with validation)
echo "Step 1: Parsing markdown specification..."
node "$SCRIPT_DIR/md-to-json.js" "$MARKDOWN_FILE" "$JSON_FILE"
if [ $? -ne 0 ]; then
    echo "❌ Failed to parse markdown"
    exit 1
fi
echo ""

# Step 2: JSON → Elm
echo "Step 2: Generating Elm code..."
node "$SCRIPT_DIR/json-to-elm.js" "$JSON_FILE" "$ELM_FILE"
if [ $? -ne 0 ]; then
    echo "❌ Failed to generate Elm code"
    exit 1
fi
echo ""

# Step 3: Verify Elm compilation (optional)
echo "Step 3: Verifying Elm compilation..."
cd "$PROJECT_ROOT"
elm make src/Main.elm --output=/dev/null 2>&1 | head -20
if [ $? -eq 0 ]; then
    echo "✓ Elm compilation successful"
else
    echo "⚠️  Elm compilation failed (generated code may need manual adjustments)"
fi
echo ""

echo "========================================"
echo "✓ Build complete!"
echo "========================================"
echo "Generated files:"
echo "  JSON: $JSON_FILE"
echo "  Elm:  $ELM_FILE"
