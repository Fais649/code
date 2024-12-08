#!/bin/bash

# Function to add, commit, and push in the current repository
commit_and_push() {
	git add .

	# Check if there are changes to commit
	if git diff-index --quiet HEAD --; then
		echo "No changes to commit in $(pwd)"
	else
		git commit -m "Your commit message"
		git push
	fi
}

read -rp "Commit && Push? (Y/n)" COMMIT_AND_PUSH

if [ "$COMMIT_AND_PUSH" == "n" ]; then
	exit 0
fi

# Start in the main repository
echo "Processing main repository..."
commit_and_push

# Process each submodule
echo "Processing submodules..."
git submodule foreach '
    echo "Entering submodule: $(pwd)"
	git add .

	# Check if there are changes to commit
	if git diff-index --quiet HEAD --; then
		echo "No changes to commit in $(pwd)"
	else
		git commit -m \"autocommit\"
		git push
	fi
'

echo "All repositories have been processed."
