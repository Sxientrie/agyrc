# System & Environment Reference

## Repositories

| Repo | Mirror |
| :--- | :--- |
| `termux-main` | mirror.nyist.edu.cn |
| `termux-x11` | provides X11/graphical packages for GUI apps via Termux:X11 |

Change mirrors anytime with `termux-change-repo`.

---

## Installed Packages (baseline)

| Package | Notes |
| :--- | :--- |
| `android-tools` | includes `adb` |
| `nmap` | |
| `openssl` | |
| `termux-api` | CLI bridge for Termux:API app |
| `glibc` | |
| `glibc-repo` | |

**This list is non-exhaustive.** Always run `pkg list-installed` before assuming a package is absent — the user may have installed more since this snapshot.

---

## CPU Throttling (OneUI 8.5)

When Termux is **backgrounded** on OneUI 8.5:

- Process moves from `/top-app` to `/moderate` cpuset
- Core access restricted to **cpu0-1 and cpu4-5 only** (mask `0x33`)
- Full 8-core access is not guaranteed during background execution
- Factor this into performance expectations for CPU-intensive or long-running background tasks
- Use `termux-wake-lock` to help prevent the process being deprioritized during critical tasks

---

## Other Notes

- **No external SD card** — internal storage only
- **Termux:X11** packages available via `termux-x11` repo for GUI applications
