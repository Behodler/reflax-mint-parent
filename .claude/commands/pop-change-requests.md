# pop-change-requests

Processes and distributes change requests from a submodule to its target dependencies.

## Purpose
Transfers pending change requests from a submodule's queue to the appropriate target submodules for implementation, following the FIFO principle.

## Usage
```bash
.claude/scripts/pop-change-requests.sh <submodule-name>
```

## Arguments
- `submodule-name` (required): The name of the submodule containing change requests to process

## Example
```bash
.claude/scripts/pop-change-requests.sh tokenvault
```

## What It Does

1. **Reads change requests** from `<submodule>/MutableChangeRequests.json`

2. **Validates targets** - Checks that target dependency submodules exist

3. **Transfers requests** in FIFO order:
   - Extracts each change request
   - Appends to target's `SiblingChangeRequests.json`
   - Creates the file if it doesn't exist

4. **Clears source queue** - Empties the processed requests from the source submodule

## Change Request Format

The `MutableChangeRequests.json` file should contain:
```json
{
  "requests": [
    {
      "dependency": "target-submodule-name",
      "changes": [
        {
          "fileName": "IInterface.sol",
          "description": "Add method X to handle Y"
        }
      ]
    }
  ]
}
```

## Process Flow

1. **Submodule Development**:
   - Developer identifies need for dependency changes
   - Adds request to `MutableChangeRequests.json`
   - Stops work and informs user

2. **User Runs This Command**:
   - Transfers requests to target submodules
   - Clears source queue

3. **Target Submodule Implementation**:
   - Navigate to target submodule
   - Run `.claude/commands/consider-change-requests.sh`
   - Implement changes using TDD

4. **Source Submodule Continues**:
   - Update dependency: `.claude/commands/update-mutable-dependency.sh <dep-name>`
   - Continue development with updated interfaces

## Dependencies

- Optionally uses `jq` for JSON processing (falls back to basic parsing if unavailable)
- Requires target submodules to exist as directories

## Error Handling

The script will:
- Exit if no submodule name provided
- Exit if submodule directory doesn't exist
- Warn if target dependencies are not found
- Handle empty request queues gracefully

## Important Notes

- Requests are processed in FIFO (First In, First Out) order
- Each target submodule receives its own `SiblingChangeRequests.json`
- The source queue is cleared after successful transfer
- Manual JSON merging may be required if `jq` is not available

## Next Steps After Running

1. Navigate to each affected dependency submodule
2. Run `.claude/commands/consider-change-requests.sh` 
3. Implement the requested changes using TDD principles
4. Update the source submodule's dependency when changes are complete