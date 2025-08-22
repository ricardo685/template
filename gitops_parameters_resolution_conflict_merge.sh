#!/bin/bash

# Usage:
# Load parameters
PARAM_FILE="gitops_parameters.yaml"
GIT_USER=$(grep GIT_USER $PARAM_FILE | awk '{print $2}' | tr -d '"')
GIT_EMAIL=$(grep GIT_EMAIL $PARAM_FILE | awk '{print $2}' | tr -d '"')
REPO_URL=$(grep REPO_URL $PARAM_FILE | awk '{print $2}' | tr -d '"')
CHECKOUT_BRANCH=$(grep CHECKOUT_BRANCH $PARAM_FILE | awk '{print $2}' | tr -d '"')
PULL_BRANCH=$(grep PULL_BRANCH $PARAM_FILE | awk '{print $2}' | tr -d '"')
LOGFILE=$(grep LOGFILE $PARAM_FILE | awk '{print $2}' | tr -d '"')

# Required parameters in gitops_parameters.yaml:
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
read -s -p "Enter Git password for $GIT_USER: " GIT_PASSWORD
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

# Set values config
git init
git config --global http.sslVerify false
git config --global ssh.postBuffer 524288000
git config --global core.compression 0
git config --global core.ignorecase false

# Set git user and email config
git config --global http.sslVerify false
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
echo "[$(date)] Set git user.name='$GIT_USER' and user.email='$GIT_EMAIL'." | tee -a "../../$LOGFILE"

# Checkout target branch
git checkout "$CHECKOUT_BRANCH" 2>&1 | tee -a "../../$LOGFILE"

# Pull changes from pull branch
# Strategy-option --theirs is used to perform a git pull operation while specifying a merge strategy option that favors "their" changes in case of conflicts.
git pull --strategy-option --theirs origin "$PULL_BRANCH" 2>&1 | tee -a "../../$LOGFILE"

# Show diff between branches
echo "[$(date)] Diff between origin/$CHECKOUT_BRANCH and $CHECKOUT_BRANCH:" | tee -a "../../$LOGFILE"
git diff "origin/$CHECKOUT_BRANCH" "$CHECKOUT_BRANCH" 2>&1 | tee -a "../../$LOGFILE"

# Push changes to remote
git push origin "$CHECKOUT_BRANCH" 2>&1 | tee -a "../../$LOGFILE"

# Log HEAD commit
git log HEAD -n 1 2>&1 | tee -a "../../$LOGFILE"

echo "[$(date)] Finished operations: checkout '$CHECKOUT_BRANCH', pull '$PULL_BRANCH', diff, and push." | tee -a "../../$LOGFILE"