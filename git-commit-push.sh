#!/bin/bash
# Development workflow script for cmdy
# Usage: ./dev-workflow.sh [commit_message] [git_remote] [git_branch]
set -e

# Colors
G='\033[0;32m' Y='\033[1;33m' R='\033[0;31m' N='\033[0m'

# Parameters
COMMIT_MSG="${1:-Update cmdy}"
GIT_REMOTE="${2:-origin}"
GIT_BRANCH="${3:-master}"

echo -e "${Y}🚀 Starting development workflow...${N}"

# Check if there are any changes first
echo -e "${Y}📊 Checking for changes...${N}"
if ! git status --porcelain | grep -q .; then
    echo -e "${Y}ℹ️  No changes to commit${N}"
    exit 0
fi

# Show what will be committed
echo -e "${Y}📋 Changes to be committed:${N}"
git status --short

# Git add
echo -e "${Y}📦 Staging changes...${N}"
if ! git add .; then
    echo -e "${R}❌ Git add failed${N}"
    exit 1
fi

# Git commit
echo -e "${Y}💾 Committing changes...${N}"
if ! git commit -m "$COMMIT_MSG" >/dev/null; then
    echo -e "${R}❌ Git commit failed${N}"
    exit 1
fi

# Git push
echo -e "${Y}📤 Pushing to $GIT_REMOTE/$GIT_BRANCH...${N}"
if ! git push "$GIT_REMOTE" "$GIT_BRANCH" >/dev/null 2>&1; then
    echo -e "${R}❌ Git push failed${N}"
    exit 1
fi

echo -e "${G}✓ Git workflow completed successfully${N}"