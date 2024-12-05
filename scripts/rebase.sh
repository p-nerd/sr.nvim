#!/bin/bash

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Store the current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Store the main branch name
main_branch="main"

# First, fetch all changes from remote
echo -e "${BLUE}Fetching latest changes from remote...${NC}"
git fetch --all

# Update the main branch
echo -e "${BLUE}Updating $main_branch branch...${NC}"
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
    echo -e "${YELLOW}[$current/$total_branches] Processing branch: $branch${NC}"

    # Checkout the branch
    if git checkout "$branch"; then
        echo -e "${YELLOW}Pulling latest changes for $branch...${NC}"
        git pull origin "$branch" || echo -e "${YELLOW}Note: Branch might not exist on remote yet${NC}"

        echo -e "${YELLOW}Rebasing $branch onto $main_branch...${NC}"
        if git rebase "$main_branch"; then
            echo -e "${GREEN}Successfully rebased $branch${NC}"

            echo -e "${YELLOW}Pushing changes to remote...${NC}"
            if git push origin "$branch" -f; then
                echo -e "${GREEN}Successfully pushed $branch to remote${NC}"
            else
                echo -e "${RED}Error: Failed to push $branch to remote${NC}"
                failed_branches+=("$branch - push failed")
            fi
        else
            echo -e "${RED}Error: Failed to rebase $branch. Aborting rebase...${NC}"
            git rebase --abort
            failed_branches+=("$branch - rebase failed")
        fi
    else
        echo -e "${RED}Error: Failed to checkout $branch${NC}"
        failed_branches+=("$branch - checkout failed")
    fi

    echo -e "${BLUE}----------------------------------------${NC}"
    ((current++))
done

# Return to the original branch
echo -e "${BLUE}Returning to original branch: $current_branch${NC}"
git checkout "$current_branch"

# Summary report
echo -e "\n${BLUE}Operation Summary:${NC}"
echo -e "${YELLOW}Total branches processed: $((current-1))${NC}"
if [ ${#failed_branches[@]} -eq 0 ]; then
    echo -e "${GREEN}All branches were successfully processed!${NC}"
else
    echo -e "\n${RED}Failed operations:${NC}"
    for failure in "${failed_branches[@]}"; do
        echo -e "${RED}- $failure${NC}"
    done
    echo -e "\n${YELLOW}Please handle these branches manually.${NC}"
fi
