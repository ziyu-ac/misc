#!/bin/bash

# Configuration variables
ORG_NAME="infra-ac-001"
GITHUB_TOKEN=""
DOWNLOAD_METHOD="clone"  # Options: clone or download

# Function to download or clone repositories
download_repos() {
    local PREFIX="${1:-ai-}"
    local REPOS_TO_DOWNLOAD=("${@:2}")

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
        # Check download conditions
        if [[ "${#REPOS_TO_DOWNLOAD[@]}" -eq 0 ]] ||
           [[ " ${REPOS_TO_DOWNLOAD[@]} " =~ " ${repo#$PREFIX} " ]] ||
           [[ "${REPOS_TO_DOWNLOAD[0]}" == "all" ]]; then

            echo "Processing repository: $repo"

            if [[ "$DOWNLOAD_METHOD" == "clone" ]]; then
                # Clone repository
                git clone "https://${GITHUB_TOKEN}@github.com/$ORG_NAME/$repo.git"
            else
                # Download zip
                mkdir -p "$repo"
                curl -L \
                    -H "Authorization: token $GITHUB_TOKEN" \
                    "https://github.com/$ORG_NAME/$repo/archive/main.zip" \
                    -o "$repo.zip"

                # Unzip repository
                unzip -q "$repo.zip" -d "$repo"
                rm "$repo.zip"
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
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 [prefix] [repo1] [repo2] ..."
        echo "Examples:"
        echo "  $0 ai-                # Download all ai-* repos"
        echo "  $0 *                  # Download ALL repos"
        echo "  $0 ai- oms common     # Download specific ai-* repos"
        exit 1
    fi

    # Call download function with arguments
    download_repos "$@"

    echo "Download complete. Repositories saved in $(pwd)"
}

# Execute main function
main "$@"
