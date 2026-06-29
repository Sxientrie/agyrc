---
name: termux-device
description: >
  Device-specific reference for this Android/Termux environment. Read this
  skill whenever a task involves Android system behavior, Shizuku/rish elevation,
  Termux:API commands, package installation, CPU/battery constraints, or anything
  environment-specific to this device. This is the entry point — route to the
  correct sub-skill below. Never guess device-specific details; always read the
  relevant sub-skill first.
---

# Termux Device Reference

Samsung SM-A076B (Galaxy A07 5G) · aarch64 · Android 16 / OneUI 8.5 · Termux 0.119.0-beta.3

Read the sub-skill that matches the task:

## Sub-skills

- **Termux:API commands** → [references/termux-api.md](references/termux-api.md)
  - Any `termux-*` command, Android hardware interaction, storage symlinks.


- **System & environment** → [references/system.md](references/system.md)
  - Repos, installed packages, CPU throttling, background execution limits.

---

## Always-true constraints (no sub-skill needed)

These apply to every task on this device — no need to open a sub-skill for them:

- All native binaries must target **aarch64 (arm64-v8a)**
- `$PREFIX` = `/data/data/com.termux/files/usr` — use this, not `/usr`
- `$HOME` = `/data/data/com.termux/files/home`
- Binaries live in `$PREFIX/bin/` — `/usr/bin`, `/etc`, `/usr/lib` do not exist
- Package manager: `pkg install` — never `apt` directly
- Shell: zsh · config: `~/.zshrc`
- SELinux is **Enforcing** — unexpected failures may be policy denials, not bugs
- No external SD card — internal storage only
