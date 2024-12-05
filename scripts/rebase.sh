#!/bin/bash

current_branch=$(git rev-parse --abbrev-ref HEAD)
main_branch="main"

echo "Fetching latest changes from origin/$main_branch..."
git checkout $main_branch
git pull origin $main_branch

branches=$(git branch | grep -v "$main_branch" | sed 's/*//' | tr -d ' ')
total_branches=$(echo "$branches" | wc -l)
current=1

declare -a failed_branches

for branch in $branches; do
    echo "Processing branch: $branch"
    if git checkout "$branch"; then
        if ! git pull origin "$branch" 2>/dev/null; then
            echo "Error: Failed to pull latest changes for $branch"
            failed_branches+=("$branch - pull failed")
            continue
        fi
        if ! git rebase "$main_branch" 2>/dev/null; then
            echo "Error: Rebase failed for $branch"
            git rebase --abort 2>/dev/null # Clean up the failed rebase
            failed_branches+=("$branch - rebase failed")
            continue
        fi
        if ! git push --force-with-lease 2>/dev/null; then
            echo "Error: Failed to push changes for $branch"
            failed_branches+=("$branch - push failed")
            continue
        fi
    else
        echo "Error: Failed to checkout $branch"
        failed_branches+=("$branch - checkout failed")
    fi
    echo "----------------------------------------"
    ((current++))
done

echo "Returning to original branch: $current_branch"
git checkout "$current_branch"

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
