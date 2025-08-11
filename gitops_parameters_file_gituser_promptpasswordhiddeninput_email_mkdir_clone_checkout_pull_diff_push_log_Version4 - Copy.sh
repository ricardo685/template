#!/bin/bash

# Usage:
# ./gitops_parameters_file_gituser_promptpasswordhiddeninput_email_mkdir_clone_checkout_pull_diff_push_log.sh parameters.env

PARAM_FILE="$1"

if [ -z "$PARAM_FILE" ]; then
  echo "Usage: $0 <parameters_file>"
  exit 1
fi

# Load parameters from the file
source "$PARAM_FILE"

# Required parameters in parameters.env:
# GIT_USER
# GIT_EMAIL
# REPO_URL
# CHECKOUT_BRANCH
# PULL_BRANCH
# LOGFILE

if [ -z "$GIT_USER" ] || [ -z "$GIT_EMAIL" ] || [ -z "$REPO_URL" ] || [ -z "$CHECKOUT_BRANCH" ] || [ -z "$PULL_BRANCH" ] || [ -z "$LOGFILE" ]; then
  echo "One or more required parameters are missing in $PARAM_FILE"
  exit 2
fi

# Prompt for password securely (hidden input)
read -s -p "Enter git password for user $GIT_USER: " GIT_PASSWORD
echo

USER_DIR="$GIT_USER"

echo "[$(date)] Starting GitOps script for user '$GIT_USER'" | tee -a "$LOGFILE"

# Create user directory if it doesn't exist
if [ ! -d "$USER_DIR" ]; then
  mkdir -p "$USER_DIR"
  echo "[$(date)] Directory '$USER_DIR' created." | tee -a "$LOGFILE"
else
  echo "[$(date)] Directory '$USER_DIR' already exists." | tee -a "$LOGFILE"
fi

# Prepare repo URL with credentials for HTTPS cloning
REPO_URL_AUTH=$(echo "$REPO_URL" | sed "s#https://#https://$GIT_USER:$GIT_PASSWORD@#")

cd "$USER_DIR"

# Clone repo
git clone "$REPO_URL_AUTH" 2>&1 | tee -a "../$LOGFILE"
REPO_NAME=$(basename "$REPO_URL" .git)
cd "$REPO_NAME"

# Set git user and email config
git config user.name "$GIT_USER"
git config user.email "$GIT_EMAIL"
echo "[$(date)] Set git user.name='$GIT_USER' and user.email='$GIT_EMAIL'." | tee -a "../../$LOGFILE"

# Checkout target branch
git checkout "$CHECKOUT_BRANCH" 2>&1 | tee -a "../../$LOGFILE"

# Pull changes from pull branch
git pull origin "$PULL_BRANCH" 2>&1 | tee -a "../../$LOGFILE"

# Show diff between branches
echo "[$(date)] Diff between $CHECKOUT_BRANCH and $PULL_BRANCH:" | tee -a "../../$LOGFILE"
git diff "$CHECKOUT_BRANCH" "origin/$PULL_BRANCH" 2>&1 | tee -a "../../$LOGFILE"

# Push changes to remote
git push origin "$CHECKOUT_BRANCH" 2>&1 | tee -a "../../$LOGFILE"

echo "[$(date)] Finished operations: checkout '$CHECKOUT_BRANCH', pull '$PULL_BRANCH', diff, and push." | tee -a "../../$LOGFILE"