#!/bin/bash

current_branch=$(git rev-parse --abbrev-ref HEAD)

main_branch="main"

echo "petching latest changes from origin/$main_branch..."
git checkout $main_branch
git pull origin $main_branch

branches=$(git branch | grep -v "$main_branch" | sed 's/*//' | tr -d ' ')
total_branches=$(echo "$branches" | wc -l)
current=1

declare -a failed_branches

for branch in $branches; do
    echo "processing branch: $branch"
    if git checkout "$branch"; then
        git pull
        git rebase $main_branch
        git push --force-with-lease
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
