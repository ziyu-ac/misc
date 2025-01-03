#!/bin/bash

# Configuration variables
ORG_NAME="infra-ac-001"
GITHUB_TOKEN=""
# Hard-coded repositories
#REPOS_TO_CLONE=("ai-oms" "ai-market-data-wrapper" "ai-common")
REPOS_TO_CLONE=("ai-util" "ai-common" "ai-framework" "ai-oms" "ai-market-data-wrapper" "ai-market-data")

# Function to display help
show_help() {
    echo "Usage: $0 [tag_name] [options]"
    echo "Options:"
    echo "  --dry-run       Log actions without pushing changes."
    echo "  --push-only     Push changes only if the tag exists."
    echo "  -h, --help      Display this help message."
}

# Function to update repositories
update_repos() {
    local TAG_NAME="$1"  # The specific tag to apply
    local dry_run="$2"
    local push_only="$3"
    local BRANCH_NAME="release-candidate"

    # Process hard-coded repositories
    for repo in "${REPOS_TO_CLONE[@]}"; do
        echo "============Processing repository: $repo============"

        # Check if the repository directory exists
        if [ ! -d "$repo" ]; then
            # Clone the master branch if the repo doesn't exist
            git clone -b master "https://${GITHUB_TOKEN}@github.com/$ORG_NAME/$repo.git"
        fi

        cd "$repo" || { echo "Failed to enter directory $repo"; continue; }

        # Fetch the latest branches from origin
        git fetch origin

        # Check if the branch exists on the remote
        if ! git rev-parse --verify "origin/$BRANCH_NAME" >/dev/null 2>&1; then
            echo "Warn, there is no $BRANCH_NAME in $repo, creating this branch"
            git checkout -b "$BRANCH_NAME"
        else
            git checkout "$BRANCH_NAME"
        fi

        # Special handling for ai-oms to update submodules
        if [ "$repo" == "ai-oms" ]; then
            echo "Updating submodules for $repo..."
            git submodule update --init --recursive
        fi

        # Check if the current commit is already tagged
        if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
            echo "Tag $TAG_NAME already exists for $repo, skipping tagging."
        else
            # Only tag if not in push-only mode
            if [ "$push_only" = false ]; then
                # Merge master into release-candidate
                if git merge master --no-edit; then
                    # Tag the release-candidate branch
                    git tag "$TAG_NAME"
                else
                    echo "Failed to merge master into $BRANCH_NAME for $repo"
                    git merge --abort  # Reset merge if it fails
                fi
            fi
        fi

        # Handle pushing logic
        if [ "$dry_run" = true ]; then
            echo "Dry run enabled: Not pushing changes for $repo"
            echo "Would push: git push origin $BRANCH_NAME --tags"
        elif [ "$push_only" = true ]; then
            if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
                echo "Pushing changes for $repo"
                #echo "git push origin $BRANCH_NAME --tags"
                git push origin "$BRANCH_NAME" --tags
            else
                echo "Tag $TAG_NAME does not exist, not pushing for $repo"
            fi
        else
            echo "Pushing changes for $repo"
            git push origin "$BRANCH_NAME" --tags
        fi

        echo "Successfully updated $repo"

        # Return to original directory
        cd ..
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

    # Check for tag argument
    if [[ $# -lt 1 ]]; then
        show_help
        exit 1
    fi

    # Initialize flags
    local dry_run=false
    local push_only=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run=true
                shift
                ;;
            --push-only)
                push_only=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                TAG_NAME="$1"
                shift
                ;;
        esac
    done

    # Call update function with arguments
    update_repos "$TAG_NAME" "$dry_run" "$push_only"

    echo "Update complete"
}

# Execute main function
main "$@"
