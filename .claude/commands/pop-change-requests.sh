#!/bin/bash

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide the name of the submodule with change requests"
    echo "Usage: pop-change-requests <submodule-name>"
    exit 1
fi

SUBMODULE="$1"
REQUESTS_FILE="$SUBMODULE/MutableChangeRequests.json"

# Check if submodule exists
if [ ! -d "$SUBMODULE" ]; then
    echo "Error: Submodule '$SUBMODULE' not found"
    exit 1
fi

# Check if requests file exists
if [ ! -f "$REQUESTS_FILE" ]; then
    echo "No change requests found for $SUBMODULE"
    exit 0
fi

# Check if jq is installed for JSON processing
if ! command -v jq &> /dev/null; then
    echo "Warning: jq not found. Using basic processing..."
    
    # Basic processing without jq
    echo "Processing change requests from $SUBMODULE..."
    
    # Read the file content
    REQUESTS_CONTENT=$(cat "$REQUESTS_FILE")
    
    # Check if there are any requests
    if echo "$REQUESTS_CONTENT" | grep -q '"requests":\s*\[\s*\]'; then
        echo "No pending change requests in $SUBMODULE"
        exit 0
    fi
    
    echo "Change requests found. Processing in FIFO order..."
    
    # Extract each dependency's requests manually
    # This is a simplified version - in production you'd want more robust parsing
    while IFS= read -r line; do
        if echo "$line" | grep -q '"dependency"'; then
            DEPENDENCY=$(echo "$line" | sed 's/.*"dependency":\s*"\([^"]*\)".*/\1/')
            
            if [ -d "$DEPENDENCY" ]; then
                TARGET_FILE="$DEPENDENCY/SiblingChangeRequests.json"
                
                # Create or append to the target file
                if [ ! -f "$TARGET_FILE" ]; then
                    echo '{"requests": []}' > "$TARGET_FILE"
                fi
                
                echo "Transferring change requests to $DEPENDENCY..."
                
                # For simplicity, copy the relevant section
                # In production, you'd want proper JSON merging
                echo "Note: Manual review required to properly merge JSON requests"
                echo "Source: $REQUESTS_FILE"
                echo "Target: $TARGET_FILE"
            else
                echo "Warning: Target dependency '$DEPENDENCY' not found as a submodule"
            fi
        fi
    done < "$REQUESTS_FILE"
    
else
    # Process with jq for proper JSON handling
    echo "Processing change requests from $SUBMODULE using jq..."
    
    # Get the number of requests
    REQUEST_COUNT=$(jq '.requests | length' "$REQUESTS_FILE")
    
    if [ "$REQUEST_COUNT" -eq 0 ]; then
        echo "No pending change requests in $SUBMODULE"
        exit 0
    fi
    
    echo "Found $REQUEST_COUNT change request group(s). Processing in FIFO order..."
    
    # Process each request group
    for i in $(seq 0 $((REQUEST_COUNT - 1))); do
        # Extract the dependency name
        DEPENDENCY=$(jq -r ".requests[$i].dependency" "$REQUESTS_FILE")
        
        # Check if the dependency submodule exists
        if [ ! -d "$DEPENDENCY" ]; then
            echo "Warning: Target dependency '$DEPENDENCY' not found as a submodule"
            continue
        fi
        
        TARGET_FILE="$DEPENDENCY/SiblingChangeRequests.json"
        
        # Extract the request object
        REQUEST=$(jq ".requests[$i]" "$REQUESTS_FILE")
        
        # Create target file if it doesn't exist
        if [ ! -f "$TARGET_FILE" ]; then
            echo '{"requests": []}' > "$TARGET_FILE"
        fi
        
        # Add the request to the target file
        echo "Transferring change request to $DEPENDENCY/SiblingChangeRequests.json"
        
        # Append the request to the target file's requests array
        jq --argjson request "$REQUEST" '.requests += [$request]' "$TARGET_FILE" > "${TARGET_FILE}.tmp"
        mv "${TARGET_FILE}.tmp" "$TARGET_FILE"
        
        echo "Successfully transferred change request for $DEPENDENCY"
    done
    
    # Clear the processed requests from the source file
    echo '{"requests": []}' > "$REQUESTS_FILE"
    echo "Cleared processed requests from $SUBMODULE/MutableChangeRequests.json"
fi

echo ""
echo "Change request processing complete!"
echo "Next steps:"
echo "1. Navigate to each affected dependency submodule"
echo "2. Run: .claude/commands/consider-change-requests.sh"
echo "3. Implement the requested changes using TDD principles"