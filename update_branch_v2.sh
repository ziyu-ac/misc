#!/bin/bash

# Configuration variables
ORG_NAME="infra-ac-001"
GITHUB_TOKEN=""

# Function to update repositories
update_repos() {
    local PREFIX="${1:-ai-}"
    local BRANCH_NAME="${2:-main}"  # Default to main if not specified
    local REPOS_TO_UPDATE=("${@:3}")

    echo "Switching to branch: $BRANCH_NAME"

    # Fetch repositories based on conditions
    if [[ "$PREFIX" == "*" ]]; then
        # Fetch ALL repositories if prefix is *
        REPOS=$(curl -s \
            -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/orgs/$ORG_NAME/repos?per_page=1000" | \
            jq -r '.[].name')
    else
        # Fetch repositories with specific prefix
        REPOS=$(curl -s \
            -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/orgs/$ORG_NAME/repos?per_page=1000" | \
            jq -r '.[] | select(.name | startswith("'"$PREFIX"'")) | .name')
    fi

    # Process repositories
    for repo in $REPOS; do
        # Check update conditions
        if [[ "${#REPOS_TO_UPDATE[@]}" -eq 0 ]] || 
           [[ " ${REPOS_TO_UPDATE[@]} " =~ " ${repo#$PREFIX} " ]] || 
           [[ "${REPOS_TO_UPDATE[0]}" == "all" ]]; then
            
            echo "Updating repository: $repo"
            
            if [ -d "$repo" ]; then
                # Repository exists, update it
                cd "$repo"
                
                # Fetch all remotes
                git fetch --all
                
                # Check if branch exists on remote
                if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then
                    # Create local branch tracking remote branch if it doesn't exist
                    if ! git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
                        git checkout -b "$BRANCH_NAME" "origin/$BRANCH_NAME"
                    else
                        # Switch to branch and pull latest changes
                        git checkout "$BRANCH_NAME"
                        git pull origin "$BRANCH_NAME"
                    fi
                else
                    echo "Warning: Branch $BRANCH_NAME does not exist in repository $repo"
                fi
                
                # Return to original directory
                cd ..
            else
                # Clone repository if it doesn't exist
                git clone -b "$BRANCH_NAME" "https://${GITHUB_TOKEN}@github.com/$ORG_NAME/$repo.git"
            fi
        fi
    done
}

# Validate dependencies
validate_dependencies() {
    local dependencies=("curl" "jq" "git")
    for dep in "${dependencies[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || {
            echo "Error: $dep is not installed"
            exit 1
        }
    done

    if [[ -z "$GITHUB_TOKEN" ]]; then
        echo "Error: GitHub personal access token is required"
        exit 1
    fi
}

# Main execution
main() {
    validate_dependencies

    # Default behavior
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 [prefix] [branch_name] [repo1] [repo2] ..."
        echo "Examples:"
        echo "  $0 ai- develop           # Switch all ai-* repos to develop branch"
        echo "  $0 * main               # Switch ALL repos to main branch"
        echo "  $0 ai- feature oms common # Switch specific ai-* repos to feature branch"
        exit 1
    fi

    # Call update function with arguments
    update_repos "$@"

    echo "Update complete"
}

# Execute main function
main "$@"
