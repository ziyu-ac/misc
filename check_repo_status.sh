#!/bin/bash
#for d in */; do echo -e "\n=== $d" && git -C "$d" status -s; done
for d in */; do
    echo -e "\n=== $d"
    # Get current branch
    branch=$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null)
    # Get current commit hash
    commit=$(git -C "$d" rev-parse HEAD 2>/dev/null)
    # Get all tags pointing to the current commit
    tags=$(git -C "$d" tag --points-at HEAD 2>/dev/null)
    if [ -z "$tags" ]; then
        tags="No tags"
    fi
    # Display branch, commit, and tag
    echo "Branch: ${branch:-Detached HEAD}"
    echo "Commit: ${commit:-No commit}"
    echo "Tag: $tags"
    # Check if the directory is a submodule and display its status
    git -C "$d" status -s

    # Check for submodules and display the latest commit, log, date, and tags
    if [ -d "$d/.git/modules" ]; then
        echo "Submodules:"
        git -C "$d" submodule status --recursive | while read -r line; do
            # Extract submodule details
            path=$(echo "$line" | awk '{print $2}')
            echo "  Path: $path"
            
            # Get the latest commit hash of the submodule
            latest_commit_hash=$(git -C "$d/$path" rev-parse HEAD)
            echo "  Latest Commit: $latest_commit_hash"
            
            # Get the log message for the latest commit
            log_message=$(git -C "$d/$path" log -1 --pretty=%B "$latest_commit_hash")
            echo "  Log: $log_message"
            
            # Get the date of the latest commit
            commit_date=$(git -C "$d/$path" show -s --format=%ci "$latest_commit_hash")
            echo "  Date: $commit_date"
            
            # Get tags pointing to the latest commit
            submodule_tags=$(git -C "$d/$path" tag --points-at "$latest_commit_hash" 2>/dev/null)
            if [ -z "$submodule_tags" ]; then
                submodule_tags="No tags"
            fi
            echo "  Tags: $submodule_tags"
        done
    fi
done
