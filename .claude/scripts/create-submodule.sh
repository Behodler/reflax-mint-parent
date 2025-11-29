#!/bin/bash

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide a name for the submodule"
    echo "Usage: create-submodule <name>"
    exit 1
fi

NAME="$1"
LOWERCASE_NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
# Convert to PascalCase (capitalize first letter and letters after underscores/hyphens)
PASCAL_NAME=$(echo "$NAME" | sed 's/[-_]/ /g' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) tolower(substr($i,2))}}1' | tr -d ' ')

# Create the directory
echo "Creating directory: $LOWERCASE_NAME"
mkdir -p "$LOWERCASE_NAME"

# Navigate to the directory
cd "$LOWERCASE_NAME" || exit 1

# Initialize a new git repository for the submodule
echo "Initializing git repository in $LOWERCASE_NAME"
git init

# Initialize Foundry project
echo "Initializing Foundry project"
forge init --no-commit --force

# Create lib directories for dependency management
echo "Creating dependency directories"
mkdir -p lib/mutable
mkdir -p lib/immutable

# Create .claude directories
echo "Creating .claude/commands and .claude/scripts directories"
mkdir -p .claude/commands
mkdir -p .claude/scripts

# Create add-mutable-dependency.sh
cat > .claude/scripts/add-mutable-dependency.sh << 'SCRIPT_EOF'
#!/bin/bash

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide a repository URL or path for the mutable dependency"
    echo "Usage: add-mutable-dependency <repository>"
    exit 1
fi

REPO="$1"
# Extract repo name from URL/path
REPO_NAME=$(basename "$REPO" .git)

# Clone the repository to lib/mutable
echo "Cloning mutable dependency: $REPO_NAME"
cd lib/mutable || exit 1
git clone "$REPO" "$REPO_NAME"

# Check if interfaces directory exists
if [ ! -d "$REPO_NAME/src/interfaces" ]; then
    echo "Error: No interfaces directory found in $REPO_NAME/src/"
    echo "Mutable dependencies must have an interfaces directory"
    rm -rf "$REPO_NAME"
    exit 1
fi

# Perform post-clone cleanup - keep only interfaces
echo "Cleaning up implementation details, keeping only interfaces..."
cd "$REPO_NAME" || exit 1

# Save interfaces directory temporarily
if [ -d "src/interfaces" ]; then
    cp -r src/interfaces /tmp/interfaces_temp_$$
fi

# Remove all src content except .git
find src -mindepth 1 -maxdepth 1 ! -name '.git*' -exec rm -rf {} +

# Restore interfaces
if [ -d "/tmp/interfaces_temp_$$" ]; then
    mv /tmp/interfaces_temp_$$ src/interfaces
fi

echo "Successfully added mutable dependency: $REPO_NAME (interfaces only)"
SCRIPT_EOF

chmod +x .claude/scripts/add-mutable-dependency.sh

# Create add-immutable-dependency.sh
cat > .claude/scripts/add-immutable-dependency.sh << 'SCRIPT_EOF'
#!/bin/bash

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide a repository URL or path for the immutable dependency"
    echo "Usage: add-immutable-dependency <repository>"
    exit 1
fi

REPO="$1"
# Extract repo name from URL/path
REPO_NAME=$(basename "$REPO" .git)

# Clone the repository to lib/immutable
echo "Cloning immutable dependency: $REPO_NAME"
cd lib/immutable || exit 1
git clone "$REPO" "$REPO_NAME"

echo "Successfully added immutable dependency: $REPO_NAME"
SCRIPT_EOF

chmod +x .claude/scripts/add-immutable-dependency.sh

# Create update-mutable-dependency.sh
cat > .claude/scripts/update-mutable-dependency.sh << 'SCRIPT_EOF'
#!/bin/bash

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide the name of the mutable dependency to update"
    echo "Usage: update-mutable-dependency <dependency-name>"
    exit 1
fi

DEP_NAME="$1"
DEP_PATH="lib/mutable/$DEP_NAME"

# Check if dependency exists
if [ ! -d "$DEP_PATH" ]; then
    echo "Error: Mutable dependency '$DEP_NAME' not found in lib/mutable/"
    exit 1
fi

cd "$DEP_PATH" || exit 1

# Revert any changes to restore deleted files
echo "Reverting local changes to restore all files..."
git checkout .
git clean -fd

# Pull latest changes
echo "Pulling latest changes..."
git pull

# Check if interfaces directory exists
if [ ! -d "src/interfaces" ]; then
    echo "Error: No interfaces directory found in updated $DEP_NAME/src/"
    echo "Mutable dependencies must have an interfaces directory"
    exit 1
fi

# Clean up again - keep only interfaces
echo "Cleaning up implementation details, keeping only interfaces..."

# Save interfaces directory temporarily
if [ -d "src/interfaces" ]; then
    cp -r src/interfaces /tmp/interfaces_temp_$$
fi

# Remove all src content except .git
find src -mindepth 1 -maxdepth 1 ! -name '.git*' -exec rm -rf {} +

# Restore interfaces
if [ -d "/tmp/interfaces_temp_$$" ]; then
    mv /tmp/interfaces_temp_$$ src/interfaces
fi

echo "Successfully updated mutable dependency: $DEP_NAME (interfaces only)"
SCRIPT_EOF

chmod +x .claude/scripts/update-mutable-dependency.sh

# Create consider-change-requests.sh
cat > .claude/scripts/consider-change-requests.sh << 'SCRIPT_EOF'
#!/bin/bash

REQUESTS_FILE="SiblingChangeRequests.json"

# Check if the file exists
if [ ! -f "$REQUESTS_FILE" ]; then
    echo "No sibling change requests found."
    exit 0
fi

echo "Processing sibling change requests..."
echo "Contents of $REQUESTS_FILE:"
cat "$REQUESTS_FILE"
echo ""
echo "Please review these change requests and implement them using TDD principles."
echo "If any request cannot be implemented, document the issue for the requesting submodule."
SCRIPT_EOF

chmod +x .claude/scripts/consider-change-requests.sh

# Create markdown command files for slash command access
cat > .claude/commands/add-mutable-dependency.md << 'MD_EOF'
# add-mutable-dependency

Adds a sibling submodule as a mutable dependency, exposing only interfaces.

## Usage
```bash
.claude/scripts/add-mutable-dependency.sh <repository>
```

## Arguments
- `repository` (required): The repository URL or path of the sibling submodule

## What It Does
1. Clones the repository to `lib/mutable/`
2. Verifies an `src/interfaces/` directory exists
3. Removes all implementation details, keeping only interfaces
4. Reports success or failure

## Important Notes
- Mutable dependencies only expose interfaces and abstract contracts
- Implementation details are automatically stripped
- If the dependency lacks an interfaces directory, the operation fails
MD_EOF

cat > .claude/commands/add-immutable-dependency.md << 'MD_EOF'
# add-immutable-dependency

Adds an external library as an immutable dependency with full source access.

## Usage
```bash
.claude/scripts/add-immutable-dependency.sh <repository>
```

## Arguments
- `repository` (required): The repository URL of the external library (e.g., OpenZeppelin)

## What It Does
1. Clones the full repository to `lib/immutable/`
2. Preserves all source code for complete access

## Important Notes
- Use this for external libraries that won't change based on sibling requirements
- Full source code is available for these dependencies
MD_EOF

cat > .claude/commands/update-mutable-dependency.md << 'MD_EOF'
# update-mutable-dependency

Updates an existing mutable dependency to pull the latest interface changes.

## Usage
```bash
.claude/scripts/update-mutable-dependency.sh <dependency-name>
```

## Arguments
- `dependency-name` (required): The name of the mutable dependency in `lib/mutable/`

## What It Does
1. Reverts local changes to restore the full repository
2. Pulls the latest changes from the remote
3. Verifies the interfaces directory still exists
4. Strips implementation details again, keeping only interfaces

## When to Use
- After a sibling submodule has implemented your change requests
- To sync with the latest interface definitions
MD_EOF

cat > .claude/commands/consider-change-requests.md << 'MD_EOF'
# consider-change-requests

Reviews and processes incoming change requests from sibling submodules.

## Usage
```bash
.claude/scripts/consider-change-requests.sh
```

## What It Does
1. Checks for `SiblingChangeRequests.json` in the current directory
2. Displays the contents of any pending change requests
3. Prompts for review and implementation using TDD principles

## Workflow
1. Review the requested changes
2. Implement changes following TDD (write tests first)
3. Update interfaces as needed
4. Commit and push changes
5. Notify requesting submodules to update their dependencies
MD_EOF

# Create CLAUDE.md for the submodule with enhanced dependency management
echo "Creating CLAUDE.md for submodule"
cat > CLAUDE.md << EOF
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Submodule: $PASCAL_NAME

This is a Foundry smart contract submodule for the $PASCAL_NAME contract.

## Dependency Management

### Types of Dependencies

1. **Immutable Dependencies** (lib/immutable/)
   - External libraries and contracts that don't change based on sibling requirements
   - Full source code is available
   - Examples: OpenZeppelin, standard libraries

2. **Mutable Dependencies** (lib/mutable/)
   - Dependencies from sibling submodules
   - ONLY interfaces and abstract contracts are exposed
   - NO implementation details are available
   - Changes to these dependencies must go through the change request process

### Important Rules

- **NEVER** access implementation details of mutable dependencies
- Mutable dependencies only expose interfaces and abstract contracts
- If a feature requires changes to a mutable dependency, add it to the change request queue
- All development must follow Test-Driven Development (TDD) principles using Foundry

### Change Request Process

When a feature requires changes to a mutable dependency:

1. Add the request to \`MutableChangeRequests.json\` with format:
   \`\`\`json
   {
     "requests": [
       {
         "dependency": "dependency-name",
         "changes": [
           {
             "fileName": "ISomeInterface.sol",
             "description": "Plain language description of what needs to change"
           }
         ]
       }
     ]
   }
   \`\`\`

2. **STOP WORK** immediately after adding the change request
3. Inform the user that dependency changes are needed
4. Wait for the dependency to be updated before continuing

### Available Commands

Use these as slash commands (e.g., \`/add-mutable-dependency\`) or run the scripts directly:

- \`.claude/scripts/add-mutable-dependency.sh <repo>\` - Add a mutable dependency (sibling)
- \`.claude/scripts/add-immutable-dependency.sh <repo>\` - Add an immutable dependency
- \`.claude/scripts/update-mutable-dependency.sh <name>\` - Update a mutable dependency
- \`.claude/scripts/consider-change-requests.sh\` - Review and implement sibling change requests

## Project Structure

- \`src/\` - Solidity source files
- \`test/\` - Test files (TDD required)
- \`script/\` - Deployment scripts
- \`lib/mutable/\` - Mutable dependencies (interfaces only)
- \`lib/immutable/\` - Immutable dependencies (full source)

## Development Guidelines

### Test-Driven Development (TDD)

**ALL** features, bug fixes, and modifications MUST follow TDD principles:

1. **Write tests first** - Before implementing any feature
2. **Red phase** - Write failing tests that define the expected behavior
3. **Green phase** - Write minimal code to make tests pass
4. **Refactor phase** - Improve code while keeping tests green

### Testing Commands

- \`forge test\` - Run all tests
- \`forge test -vvv\` - Run tests with verbose output
- \`forge test --match-contract <ContractName>\` - Run specific contract tests
- \`forge test --match-test <testName>\` - Run specific test
- \`forge coverage\` - Check test coverage

### Other Commands

- \`forge build\` - Compile contracts
- \`forge fmt\` - Format Solidity code
- \`forge snapshot\` - Generate gas snapshots

## Important Reminders

- This submodule operates independently from sibling submodules
- Follow Solidity best practices and naming conventions
- Use Foundry testing tools exclusively (no Hardhat or Truffle)
- If you need to change a mutable dependency, use the change request process
EOF

# Initialize MutableChangeRequests.json
echo '{"requests": []}' > MutableChangeRequests.json

# Initialize SiblingChangeRequests.json
echo '{"requests": []}' > SiblingChangeRequests.json

# Create the empty Solidity contract
echo "Creating contract: src/$PASCAL_NAME.sol"
cat > "src/$PASCAL_NAME.sol" << EOF
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract $PASCAL_NAME {

}
EOF

# Remove the default Counter contract and test if they exist
rm -f src/Counter.sol test/Counter.t.sol

# Make initial commit
git add .
git commit -m "Initial commit for $PASCAL_NAME submodule with dependency management"

# Go back to parent directory
cd ..

# Add as git submodule to parent repository
echo "Adding $LOWERCASE_NAME as a submodule"
git submodule add "./$LOWERCASE_NAME" "$LOWERCASE_NAME"
git config -f .gitmodules "submodule.$LOWERCASE_NAME.url" "./$LOWERCASE_NAME"

echo "Successfully created submodule: $LOWERCASE_NAME with contract $PASCAL_NAME and dependency management system"