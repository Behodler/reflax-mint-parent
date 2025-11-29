#!/bin/bash

# set-remotes.sh - Sets remote URLs for submodules based on remoteMap file

# Check if remoteMap file exists
if [ ! -f "remoteMap" ]; then
    exit 0
fi

# Check if remoteMap file is empty
if [ ! -s "remoteMap" ]; then
    exit 0
fi

# Store the original directory
ORIGINAL_DIR=$(pwd)

# Read the remoteMap file line by line
while IFS=' ' read -r submodule remote_url; do
    # Skip empty lines and comments
    if [ -z "$submodule" ] || [[ "$submodule" == \#* ]]; then
        continue
    fi
    
    # Check if submodule directory exists
    if [ -d "$submodule" ]; then
        echo "Setting remote for $submodule to $remote_url"
        
        # Navigate to submodule
        cd "$submodule" 2>/dev/null || {
            echo "Warning: Could not enter directory $submodule"
            cd "$ORIGINAL_DIR"
            continue
        }
        
        # Check if it's a git repository
        if [ -d ".git" ]; then
            # Set the remote origin
            git remote set-url origin "$remote_url" 2>/dev/null || git remote add origin "$remote_url" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo "  ✓ Remote set successfully for $submodule"
            else
                echo "  ✗ Failed to set remote for $submodule"
            fi
        else
            echo "  ✗ $submodule is not a git repository"
        fi
        
        # Return to original directory
        cd "$ORIGINAL_DIR"
    else
        echo "Warning: Submodule $submodule not found, skipping"
    fi
done < "remoteMap"

echo "Remote configuration complete"