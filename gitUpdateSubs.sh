#!/bin/bash

# Function to commit and push in the current repo
commit_and_push() {
  # Ensure we are on main branch; if not, switch or create it
  if ! git rev-parse --verify main >/dev/null 2>&1; then
    git checkout -b main
  else
    git checkout main
  fi

  # Update main branch
  git pull origin main

  # Commit and push changes
  git add .
  if git diff-index --quiet HEAD --; then
    echo "No changes to commit in $(pwd)"
  else
    git commit -m "Your commit message"
    git push origin main
  fi
}

read -rp "Commit && Push? (Y/n) " COMMIT_AND_PUSH
if [ "$COMMIT_AND_PUSH" == "n" ]; then
  exit 0
fi

# Main repo
echo "Processing main repository..."
commit_and_push

# Submodules
echo "Processing submodules..."
git submodule foreach '
    echo "Entering submodule: $(pwd)"
    # Ensure on main, then update and commit
    if ! git rev-parse --verify main >/dev/null 2>&1; then
        git checkout -b main
    else
        git checkout main
    fi
    git pull origin main
    git add .
    if git diff-index --quiet HEAD --; then
        echo "No changes to commit in $(pwd)"
    else
        git commit -m "autocommit"
        git push origin main
    fi
'

echo "All repositories have been processed."
