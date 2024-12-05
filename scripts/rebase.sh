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

# Array to store failed branches
declare -a failed_branches

# Loop through each branch and rebase
for branch in $branches; do
    echo "[$current/$total_branches] Processing branch: $branch"

    # Checkout the branch
    if git checkout "$branch"; then
        echo "Pulling latest changes for $branch..."
        git pull origin "$branch" || echo "Note: Branch might not exist on remote yet"

        echo "Rebasing $branch onto $main_branch..."
        if git rebase "$main_branch"; then
            echo "Successfully rebased $branch"

            echo "Pushing changes to remote..."
            if git push origin "$branch" -f; then
                echo "Successfully pushed $branch to remote"
            else
                echo "Error: Failed to push $branch to remote"
                failed_branches+=("$branch - push failed")
            fi
        else
            echo "Error: Failed to rebase $branch. Aborting rebase..."
            git rebase --abort
            failed_branches+=("$branch - rebase failed")
        fi
    else
        echo "Error: Failed to checkout $branch"
        failed_branches+=("$branch - checkout failed")
    fi

    echo "----------------------------------------"
    ((current++))
done

# Return to the original branch
echo "Returning to original branch: $current_branch"
git checkout "$current_branch"

# Summary report
echo -e "\nOperation Summary:"
echo "Total branches processed: $((current-1))"
if [ ${#failed_branches[@]} -eq 0 ]; then
    echo "All branches were successfully processed!"
else
    echo -e "\nFailed operations:"
    for failure in "${failed_branches[@]}"; do
        echo "- $failure"
    done
    echo -e "\nPlease handle these branches manually."
fi
