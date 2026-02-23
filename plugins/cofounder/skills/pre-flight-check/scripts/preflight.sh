#!/usr/bin/env bash
set -euo pipefail

errors=()

# 1. Home folder check — must not be running from ~
current_dir=$(pwd -P)
home_dir="$HOME"
if [[ "$current_dir" == "$home_dir" ]]; then
    errors+=("IN_HOME_DIR: Current directory is the user's home folder. Initialize the project within a subfolder (e.g., ~/<project-name>).")
fi

# 2. Pre-existing content without a git repo
#    Blocks only when BOTH conditions are true:
#      - The folder contains items other than .claude, .venv
#      - No local git repository has been initialized (.git/ absent)
has_other_content=false
has_git=false

[[ -d ".git" ]] && has_git=true

for item in * .[!.]* ..?*; do
    [[ -e "$item" ]] || continue
    case "$item" in
        .git|.claude|.venv) continue ;;
    esac
    has_other_content=true
    break
done

if $has_other_content && ! $has_git; then
    errors+=("EXISTING_CONTENT_NO_GIT: Directory contains pre-existing files but no git repository. This looks like an attempt to initialize a project over existing content. Use an empty directory or initialize a git repo first.")
fi

# Report results
if [[ ${#errors[@]} -gt 0 ]]; then
    echo "PREFLIGHT_FAILED"
    for err in "${errors[@]}"; do
        echo "  - $err"
    done
    exit 1
else
    echo "PREFLIGHT_PASSED"
    exit 0
fi
