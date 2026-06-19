#!/bin/bash
set -e

SKILL_NAME="proto-refactor-pipeline"
REPO="WeiSelfdiscipline/proto-refactor-pipeline"
DEST="$HOME/.claude/skills/$SKILL_NAME"

echo "Installing $SKILL_NAME..."

if [ -d "$DEST" ]; then
  echo "Already installed at $DEST, updating..."
  rm -rf "$DEST"
fi

mkdir -p "$HOME/.claude/skills"

if command -v git &>/dev/null; then
  git clone --depth=1 "https://github.com/$REPO.git" "$DEST"
else
  # fallback: download zip
  TMP=$(mktemp -d)
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.zip" -o "$TMP/skill.zip"
  unzip -q "$TMP/skill.zip" -d "$TMP"
  mv "$TMP/$SKILL_NAME-main" "$DEST"
  rm -rf "$TMP"
fi

echo ""
echo "Done! Skill installed to: $DEST"
echo ""
echo "Usage: tell Claude Code「重构到目标项目 /path/to/prototype」"
