# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Foundry-based smart contract development repository using a modular submodule architecture. Each major contract is developed in its own directory as a git submodule with its own CLAUDE.md file to minimize context window usage.

## Architecture

### Submodule Development Approach
- Each major contract is isolated in its own submodule directory
- Submodules are developed independently with controlled access to sibling submodules via interfaces
- Dependencies are managed through a two-tier system: mutable (siblings) and immutable (external)
- Cross-submodule changes follow a structured change request process
- All development must follow Test-Driven Development (TDD) principles using Foundry

### Directory Structure
- Each submodule follows Foundry's standard structure:
  - `src/` - Solidity source files
  - `test/` - Test files (TDD required)
  - `script/` - Deployment scripts
  - `lib/mutable/` - Sibling dependencies (interfaces only)
  - `lib/immutable/` - External dependencies (full source)
  - `.claude/commands/` - Submodule-specific commands
  - `CLAUDE.md` - Submodule-specific Claude guidance
  - `MutableChangeRequests.json` - Queue for dependency change requests
  - `SiblingChangeRequests.json` - Incoming change requests from siblings

## Dependency Management System

### Dependency Types

1. **Immutable Dependencies**
   - External libraries (OpenZeppelin, etc.)
   - Full source code access
   - Stored in `lib/immutable/`
   - Added via: `.claude/commands/add-immutable-dependency.sh <repo>`

2. **Mutable Dependencies**
   - Sibling submodules within this repository
   - Only interfaces and abstract contracts exposed
   - Implementation details are automatically removed
   - Stored in `lib/mutable/`
   - Added via: `.claude/commands/add-mutable-dependency.sh <repo>`

### Change Request Process

When a submodule needs changes in a sibling dependency:

1. **Submodule adds request** to `MutableChangeRequests.json`:
   ```json
   {
     "requests": [{
       "dependency": "target-submodule",
       "changes": [{
         "fileName": "IInterface.sol",
         "description": "Add method X to handle Y"
       }]
     }]
   }
   ```

2. **Submodule stops work** and informs user

3. **User runs** `.claude/commands/pop-change-requests.sh <submodule>`
   - Transfers requests to target submodules' `SiblingChangeRequests.json`
   - Clears source submodule's request queue

4. **Target submodule runs** `.claude/commands/consider-change-requests.sh`
   - Reviews and implements changes using TDD
   - Reports any issues back to user

5. **Requesting submodule updates** dependency:
   - Run `.claude/commands/update-mutable-dependency.sh <dependency-name>`
   - Continues development with updated interfaces

## Custom Commands

### Parent-Level Commands

#### create-submodule
Creates a new Foundry submodule with dependency management structure.

**Usage:** `.claude/commands/create-submodule.sh <name>`

**Example:** `.claude/commands/create-submodule.sh TokenVault`

This command will:
1. Create a new directory with lowercase naming (e.g., `tokenvault`)
2. Initialize a git repository and Foundry project
3. Create dependency directories (`lib/mutable/` and `lib/immutable/`)
4. Set up submodule-specific commands for dependency management
5. Create an empty Solidity contract with PascalCase naming (e.g., `TokenVault.sol`)
6. Generate an enhanced CLAUDE.md file with dependency management rules
7. Initialize `MutableChangeRequests.json` for change tracking
8. Register the submodule with the parent repository

#### pop-change-requests
Processes change requests from a submodule and distributes them to target dependencies.

**Usage:** `.claude/commands/pop-change-requests.sh <submodule-name>`

**Example:** `.claude/commands/pop-change-requests.sh tokenvault`

This command:
1. Reads `MutableChangeRequests.json` from the specified submodule
2. Transfers requests to target submodules' `SiblingChangeRequests.json`
3. Processes requests in FIFO order
4. Clears the source submodule's request queue

### Submodule-Level Commands

Each submodule has these commands in `.claude/commands/`:

- **add-mutable-dependency.sh** - Add a sibling submodule as dependency (interfaces only)
- **add-immutable-dependency.sh** - Add an external library with full source
- **update-mutable-dependency.sh** - Pull updates for a mutable dependency
- **consider-change-requests.sh** - Review and implement sibling change requests

## Common Foundry Commands

- `forge build` - Compile all contracts
- `forge test` - Run all tests
- `forge test -vvv` - Run tests with verbose output
- `forge test --match-contract <ContractName>` - Run specific contract tests
- `forge test --match-test <testName>` - Run specific test
- `forge fmt` - Format Solidity code
- `forge snapshot` - Generate gas snapshots
- `forge coverage` - Generate test coverage report

## Working with Submodules

### Adding a new submodule
Use the custom command: `.claude/commands/create-submodule.sh <name>`

### Cloning with submodules
`git clone --recursive <repo-url>`

### Updating submodules
`git submodule update --init --recursive`

### Working within a submodule
When working on a feature within a submodule:
1. Navigate to the submodule directory
2. Work is done in isolation without access to sibling submodules
3. Each submodule has its own CLAUDE.md with specific guidance
4. If cross-submodule changes are needed, document and pause for human review

## Development Guidelines

### Test-Driven Development (TDD)

**ALL** development in submodules MUST follow TDD principles:

1. **Red Phase** - Write failing tests that define expected behavior
2. **Green Phase** - Write minimal code to make tests pass  
3. **Refactor Phase** - Improve code while keeping tests green

Use Foundry testing tools exclusively (no Hardhat or Truffle).

### General Guidelines

- All projects use Foundry for smart contract development
- Maintain controlled isolation between submodules via interfaces
- Each submodule should be independently compilable and testable
- Follow Solidity naming conventions: contracts in PascalCase, directories in lowercase
- Integration testing between submodules requires separate test repositories
- Mutable dependencies only expose interfaces - never implementation details
- Use the change request process for cross-submodule modifications