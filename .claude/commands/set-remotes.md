# set-remotes

## Purpose
Sets remote repository URLs for submodules based on a remoteMap file.

## Usage
`.claude/scripts/set-remotes.sh`

## Description
This command reads a `remoteMap` file in the repository root that contains submodule names and their corresponding remote repository URLs. It then ensures each submodule has the correct remote set.

## remoteMap Format
The `remoteMap` file should contain one submodule per line with the format:
```
submodule-name https://github.com/user/repo.git
another-submodule https://github.com/user/another-repo.git
```

## Behavior
- If no `remoteMap` file exists or it's empty, the command terminates silently
- For each entry in the remoteMap file:
  - Navigates to the submodule directory
  - Sets the remote origin to the specified URL
  - Returns to the parent directory
- Skips any submodules that don't exist in the repository

## Example
Create a `remoteMap` file:
```
token-submodule https://github.com/example/token.git
vault-submodule https://github.com/example/vault.git
```

Then run:
```bash
.claude/scripts/set-remotes.sh
```