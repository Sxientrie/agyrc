# agyrc

Custom skills and rules for [Google Antigravity](https://github.com/anthropics/antigravity) (Gemini CLI agent).  
Drop-in config — back up, share, and sync your agent setup across devices.

---

## What's Inside

```
agyrc/
├── skills/            # Agent skills (slash-command workflows)
│   ├── critique/      # /critique — multi-lens code review
│   ├── feature-plus/  # /feature-plus — context-aware feature addition
│   ├── hygiene/       # /hygiene — structured tech debt cleanup
│   └── termux-device/ # Device-specific Termux/Android reference
├── rules/             # Global agent behavior rules
│   └── AGENTS.md      # Communication style, device info, ACL config
├── docs/              # Guides and references
│   ├── ADDING_SKILLS.md
│   └── TOOL_REFERENCE.md
├── install.sh         # Symlink installer
├── .gitignore
└── README.md
```

---

## Skills

| Skill | Trigger | What It Does |
|-------|---------|--------------|
| **critique** | `/critique [focus]` | Multi-lens code critique: correctness, design, safety, maintainability, performance, observability. Runs one, many, or all lenses. Produces a structured report with severity-ranked findings and actionable diffs. |
| **feature-plus** | `/feature-plus [hint]` | Reads the codebase, proposes 3 context-specific features (never generic), lets you pick, writes a spec, implements, and self-verifies. |
| **hygiene** | `/hygiene [focus]` | Structured cleanup across 7 tasks: dead code, naming, decomposition, feature flags, dependencies, formatting, coverage. Scans → surfaces → you pick → it cleans → verifies. |
| **termux-device** | *(auto)* | Device-specific reference for Android/Termux: API commands, system info, CPU throttling, storage layout. Not a slash command — the agent reads it automatically when relevant. |

---

## Rules

[`rules/AGENTS.md`](rules/AGENTS.md) defines global agent behavior:

- **Device profile** — hardware, OS, kernel, SELinux, Termux version
- **Communication style** — direct, structured, no filler
- **Filesystem layout** — known directories and their purposes
- **Permission ACL** — what the agent can read/write without asking
- **Interactive choices** — always use buttons, never make the user type yes/no

---

## Installation

### Quick Install (symlink)

```bash
git clone https://github.com/<your-username>/agyrc.git ~/Projects/agyrc
cd ~/Projects/agyrc
chmod +x install.sh
./install.sh
```

The install script creates symlinks from Antigravity's config directories to this repo, so edits in either location stay in sync.

### Manual Install

Copy the directories to the right locations:

```bash
# Skills → Antigravity global skills directory
cp -r skills/* ~/.gemini/config/skills/

# Rules → global agent rules
cp rules/AGENTS.md ~/.agents/AGENTS.md
```

---

## Adding a New Skill

See [`docs/ADDING_SKILLS.md`](docs/ADDING_SKILLS.md) for the full guide.

Quick version:

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`)
2. Add sub-files in subdirectories as needed (`focus/`, `tasks/`, `references/`, etc.)
3. Run `./install.sh` to symlink it into place
4. Update the skill table in this README

---

## Customizing for Your Device

The `termux-device` skill and `rules/AGENTS.md` contain device-specific details (Samsung SM-A076B, Android 16, etc.). If you're using a different device:

1. Edit `rules/AGENTS.md` — update the Device, Terminal, PATH, and Storage sections
2. Edit `skills/termux-device/` — update hardware specs, installed packages, API references

Everything else (critique, feature-plus, hygiene) is device-agnostic and works anywhere.

---

## License

MIT — see [LICENSE](LICENSE).
