# Shizuku & Near-Root Elevation Reference

On Android 16 (OneUI 8.5) under enforcing SELinux, standard Termux shell runs as a low-privilege untrusted app (`uid=10270`). For operations requiring system-level permissions (e.g. adb, package management, system setting queries), Shizuku provides a bridge.

---

## The `rish` Command

- `rish` runs a shell in the context of `uid=2000` (shell).
- This is equivalent to running `adb shell` directly on the device.
- It is located at `$PREFIX/bin/rish` if set up, or must be called by absolute path.

---

## Capabilities of `rish` (uid=2000)

| Action | Allowed | Notes |
|:---|:---:|:---|
| Read system properties | Yes | via `getprop` |
| Manage packages | Yes | via `pm install`, `pm uninstall` |
| View `logcat` | Yes | Includes system and crash logs |
| SELinux elevation | No | Still subject to shell-domain policy restrictions |
| Write to `/system` | No | Partition is read-only |

---

## SELinux & Debugging

- Standard context is `u:r:untrusted_app_27:s0`.
- Elevated context via `rish` is `u:r:shell:s0`.
- To debug SELinux policy denials (avc), use:
  ```bash
  logcat | grep avc
  ```
