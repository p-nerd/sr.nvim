#!/bin/bash

# Store the current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Store the main branch name
main_branch="main"

# First, fetch all changes from remote
echo "Fetching latest changes from remote..."
git fetch --all

# Update the main branch
echo "Updating $main_branch branch..."
git checkout $main_branch
git pull origin $main_branch

# Get all local branches except main
branches=$(git branch | grep -v "$main_branch" | sed 's/*//' | tr -d ' ')

# Counter for progress
total_branches=$(echo "$branches" | wc -l)
current=1

# Loop through each branch and rebase
for branch in $branches; do
    echo "[$current/$total_branches] Processing branch: $branch"

    # Checkout the branch
    if git checkout "$branch"; then
        echo "Rebasing $branch onto $main_branch..."
        if git rebase "$main_branch"; then
            echo "Successfully rebased $branch"
        else
            echo "Error: Failed to rebase $branch. Aborting rebase..."
            git rebase --abort
            echo "You may need to manually rebase $branch"
        fi
    else
        echo "Error: Failed to checkout $branch"
    fi

    echo "----------------------------------------"
    ((current++))
done

# Return to the original branch
echo "Returning to original branch: $current_branch"
git checkout "$current_branch"

echo "Rebase operation completed!"
