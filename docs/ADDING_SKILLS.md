# Adding a New Skill

Step-by-step guide to adding a skill to this collection.

---

## 1. Create the Skill Directory

```bash
mkdir -p skills/<skill-name>
```

Use a short, kebab-case name: `code-review`, `deploy-check`, `api-gen`.

---

## 2. Write `SKILL.md`

Every skill **must** have a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: my-skill
description: >
  One paragraph describing what this skill does and when it activates.
  Keep it under 3 sentences. This text is what the agent uses to decide
  whether to load the skill, so be specific.
---

# /my-skill — Title

## Purpose
What problem does this solve?

## Activation
How does the user trigger it? (slash command, automatic, etc.)

## Steps
1. What the agent does first
2. What it does next
3. ...

## Hard Rules
- Non-negotiable constraints
```

### Frontmatter Rules

| Field | Required | Notes |
|-------|----------|-------|
| `name` | ✅ | Must match the directory name |
| `description` | ✅ | Trigger-matched — agent reads this to decide relevance |

The body (everything below the `---`) is loaded **only after** the skill triggers. Keep it under 500 lines.

---

## 3. Add Sub-files (Optional)

If the skill has sub-tasks, lenses, or reference material, organize them in subdirectories:

```
skills/my-skill/
├── SKILL.md              # Entry point
├── focus/                # Sub-lenses (like critique)
│   ├── lens-a.md
│   └── lens-b.md
├── tasks/                # Sub-tasks (like hygiene)
│   ├── task-a.md
│   └── task-b.md
├── references/           # Reference docs (like termux-device)
│   └── api-ref.md
├── scripts/              # Helper scripts
│   └── check.sh
└── examples/             # Example inputs/outputs
    └── sample.json
```

Use whichever subdirectory names make sense for your skill. The conventions above are just patterns from existing skills.

---

## 4. Install It

Run the installer to symlink your new skill into place:

```bash
./install.sh
```

Or manually:

```bash
ln -s ~/Projects/agyrc/skills/my-skill ~/.gemini/config/skills/my-skill
```

---

## 5. Update the README

Add a row to the skill table in [`README.md`](../README.md):

```markdown
| **my-skill** | `/my-skill [args]` | Description of what it does. |
```

---

## Tips

- **Keep SKILL.md focused.** The agent loads the entire file into context. Long files waste tokens.
- **Use sub-files for depth.** Put detailed instructions in `focus/`, `tasks/`, or `references/` — the agent reads them only when needed.
- **Test the trigger.** After installing, type the slash command and verify the agent picks it up.
- **Be specific in the description.** Vague descriptions like "helps with code" won't trigger reliably. Say exactly what it does.
