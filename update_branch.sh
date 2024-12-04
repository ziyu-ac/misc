#!/bin/bash

# Check if the correct number of arguments were passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <repo_dir> <branch_name>"
    exit 1
fi

# First argument is the directory containing the repositories
REPO_DIR=$1
# Second argument is the branch to checkout
BRANCH_NAME=$2

# Navigate to the directory containing the repositories
cd "$REPO_DIR" || { echo "Failed to enter directory $REPO_DIR"; exit 1; }

# Loop through all directories matching the pattern "ai-*"
for repo in ai-*; do
    if [ -d "$repo" ]; then  # Check if it is a directory
        echo "Checking repository: $repo"
        cd "$repo"

        # Check if the directory is a Git repository
        if git rev-parse --git-dir > /dev/null 2>&1; then
            echo "Fetching all updates for $repo..."
            git fetch -a

            if git checkout "$BRANCH_NAME" 2> /dev/null; then
                echo "Switched to $BRANCH_NAME in $repo"
                git pull
            else
                echo "Branch $BRANCH_NAME not found in $repo, skipping..."
            fi
        else
            echo "Not a git repository: $repo, skipping..."
        fi

        # Return to the base directory
        cd "$REPO_DIR"
    fi
done


# ./update_branch.sh /home/ziyu/code/ gateio
