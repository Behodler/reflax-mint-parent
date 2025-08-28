# create-submodule

Creates a new Foundry-based smart contract submodule with dependency management structure.

## Purpose
Initializes a complete development environment for a new smart contract module with proper isolation, dependency tracking, and change request management.

## Usage
```bash
.claude/scripts/create-submodule.sh <name>
```

## Arguments
- `name` (required): The name of the submodule to create
  - Will be converted to lowercase for the directory name
  - Will be converted to PascalCase for the contract name

## Example
```bash
.claude/scripts/create-submodule.sh TokenVault
```

This creates:
- Directory: `tokenvault/`
- Contract: `TokenVault.sol`

## What It Does

1. **Creates directory structure**:
   - Creates submodule directory with lowercase naming
   - Initializes git repository
   - Initializes Foundry project structure

2. **Sets up dependency management**:
   - `lib/mutable/` - For sibling submodules (interfaces only)
   - `lib/immutable/` - For external libraries (full source)
   - Creates dependency management scripts

3. **Creates submodule-specific commands**:
   - `add-mutable-dependency.sh` - Add sibling dependencies
   - `add-immutable-dependency.sh` - Add external dependencies
   - `update-mutable-dependency.sh` - Update sibling dependencies
   - `consider-change-requests.sh` - Process change requests

4. **Initializes project files**:
   - Creates empty Solidity contract with PascalCase naming
   - Generates submodule-specific CLAUDE.md with TDD guidelines
   - Initializes `MutableChangeRequests.json` for outgoing change requests
   - Initializes `SiblingChangeRequests.json` for incoming change requests
   - Removes default Foundry Counter contract

5. **Registers with parent repository**:
   - Adds as git submodule
   - Commits initial structure

## Important Notes

- The submodule follows Test-Driven Development (TDD) principles
- Mutable dependencies only expose interfaces, never implementation
- Cross-submodule changes must go through the change request process
- Each submodule is independently compilable and testable

## Error Handling

The script will fail if:
- No name argument is provided
- Directory creation fails
- Git or Foundry initialization fails

## Post-Creation Steps

After creating the submodule:
1. Navigate to the new directory
2. Begin development using TDD principles
3. Add dependencies as needed using the provided scripts
4. If cross-module changes are needed, use the change request system