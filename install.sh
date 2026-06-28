#!/data/data/com.termux/files/usr/bin/zsh
#
# install.sh — Symlink agyrc skills and rules into Antigravity config directories.
#
# Usage:
#   ./install.sh          # Install (symlink) everything
#   ./install.sh --check  # Dry run — show what would happen, change nothing
#
# What it does:
#   1. Symlinks each skill directory into ~/.gemini/config/skills/
#   2. Symlinks rules/AGENTS.md into ~/.agents/AGENTS.md
#
# Existing files/dirs at the target are backed up to *.bak before overwriting.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
RULES_SRC="$REPO_DIR/rules/AGENTS.md"

SKILLS_DST="$HOME/.gemini/config/skills"
RULES_DST="$HOME/.agents/AGENTS.md"

DRY_RUN=false
[[ "${1:-}" == "--check" ]] && DRY_RUN=true

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()  { echo -e "${GREEN}✓${RESET} $1"; }
warn()  { echo -e "${YELLOW}⚠${RESET} $1"; }
dry()   { echo -e "${CYAN}[dry-run]${RESET} $1"; }

backup_and_link() {
    local src="$1"
    local dst="$2"
    local label="$3"

    if $DRY_RUN; then
        if [[ -e "$dst" && ! -L "$dst" ]]; then
            dry "Would back up $dst → ${dst}.bak"
        fi
        dry "Would symlink $dst → $src"
        return
    fi

    # Back up existing non-symlink targets
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        mv "$dst" "${dst}.bak"
        warn "Backed up existing $label to ${dst}.bak"
    fi

    # Remove existing symlink if it points somewhere else
    if [[ -L "$dst" ]]; then
        local current
        current="$(readlink -f "$dst")"
        if [[ "$current" == "$(readlink -f "$src")" ]]; then
            info "$label already linked correctly"
            return
        fi
        rm "$dst"
    fi

    ln -s "$src" "$dst"
    info "Linked $label → $src"
}

# --- Skills ---
echo ""
echo "=== Skills ==="
mkdir -p "$SKILLS_DST"

for skill_dir in "$SKILLS_SRC"/*/; do
    skill_name="$(basename "$skill_dir")"
    backup_and_link "$skill_dir" "$SKILLS_DST/$skill_name" "skills/$skill_name"
done

# --- Rules ---
echo ""
echo "=== Rules ==="
mkdir -p "$(dirname "$RULES_DST")"
backup_and_link "$RULES_SRC" "$RULES_DST" "AGENTS.md"

echo ""
if $DRY_RUN; then
    echo "Dry run complete. No changes made."
else
    echo "Done. All skills and rules are symlinked."
fi
