---
description: Install the cofounder agent as the main thread for this project. This ensures the cofounder is always active in every session, managing your environment, requirements, and development workflow automatically.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Task
---

Install the cofounder agent into the current project so it runs automatically on every session.

## Steps

1. Check if `.claude/settings.json` already exists in the project root.
   - If it exists, read it and check if it already has `"agent": "cofounder:cofounder"`. If so, tell the user it's already installed and skip to step 3.
   - If it exists but has different content, merge the `"agent"` key into the existing settings (preserve other keys).
   - If it doesn't exist, create the `.claude/` directory if needed.

2. Write `.claude/settings.json` with the agent setting:
   ```json
   {
     "agent": "cofounder:cofounder"
   }
   ```
   Make sure to preserve any existing keys if the file already existed.

3. Confirm to the user that the cofounder agent is now installed for this project. Explain briefly:
   - From now on, the cofounder agent will be active in every Claude Code session in this project.
   - The setting is saved in `.claude/settings.json` which can be committed to git so all collaborators get the same experience (they need the cofounder plugin installed too).
   - To remove it later, they can delete the `"agent"` key from `.claude/settings.json`.

4. After confirming installation, launch the cofounder agent by using the Task tool with subagent_type set to the "cofounder" agent. Tell it to start a new session.
