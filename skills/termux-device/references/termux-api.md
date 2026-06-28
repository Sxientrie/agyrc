# Termux:API — Command Reference

**Prerequisite**: The `Termux:API` companion app must be installed alongside Termux. These commands call into the app — they are not built-in shell tools. If a command fails silently, check the app is installed and has permissions.

---

## Available `termux-*` Commands

| Command | Description |
| :--- | :--- |
| `termux-am` | Wrapper to send arguments to Android activity manager. |
| `termux-audio-info` | Get information about audio capabilities. |
| `termux-backup` | Backup Termux files. |
| `termux-battery-status` | Get device battery status (JSON). |
| `termux-brightness` | Set screen brightness (0–255) or auto. |
| `termux-call-log` | List call log history. |
| `termux-camera-info` | Get info about device camera(s). |
| `termux-camera-photo` | Take a photo and save as JPEG. |
| `termux-change-repo` | Interactive utility to change package mirrors. |
| `termux-clipboard-get` | Get current system clipboard text. |
| `termux-clipboard-set` | Set clipboard text (args or stdin). |
| `termux-contact-list` | List all contacts. |
| `termux-dialog` | Prompt user input via interactive widgets. |
| `termux-download` | Download a resource via system download manager. |
| `termux-fingerprint` | Authenticate using fingerprint sensor. |
| `termux-fix-shebang` | Rewrite shebangs to target Termux's `$PREFIX/bin/`. |
| `termux-info` | Get Termux and system diagnostic info. |
| `termux-infrared-frequencies` | Query IR transmitter supported frequencies. |
| `termux-infrared-transmit` | Transmit an infrared pattern. |
| `termux-job-scheduler` | Schedule a script to run at intervals. |
| `termux-keystore` | Interact with the Android keystore. |
| `termux-location` | Get device location (gps / network / passive). |
| `termux-media-player` | Play media files. |
| `termux-media-scan` | Scan files and add to media content provider. |
| `termux-microphone-record` | Record audio from device microphone. |
| `termux-nfc` | Read/write NDEF NFC tags. |
| `termux-notification` | Display a system notification. |
| `termux-notification-channel` | Create or delete notification channels. |
| `termux-notification-list` | List currently shown notifications. |
| `termux-notification-remove` | Remove a notification by ID. |
| `termux-open` | Open a file or URL in an external app. |
| `termux-reload-settings` | Reload Termux settings (colors, terminal props). |
| `termux-reset` | Reset the Termux installation. |
| `termux-restore` | Restore Termux files from a backup. |
| `termux-saf-create` | Create a file in a SAF-managed folder. |
| `termux-saf-dirs` | List SAF directories allowed for Termux:API. |
| `termux-saf-ls` | List files in a SAF-managed folder. |
| `termux-saf-managedir` | Open file explorer to grant SAF directory access. |
| `termux-saf-mkdir` | Create a directory via SAF. |
| `termux-saf-read` | Read a SAF URI file to stdout. |
| `termux-saf-rm` | Remove a SAF file or folder. |
| `termux-saf-stat` | Return SAF file or folder info as JSON. |
| `termux-saf-write` | Write stdin to an existing SAF file. |
| `termux-scoped-env-variable` | Get/set/unset scoped environment variables. |
| `termux-sensor` | Get sensor types and live sensor data. |
| `termux-setup-storage` | Grant storage permission and create ~/storage/ symlinks. |
| `termux-share` | Share a file or stdin text via Android share sheet. |
| `termux-sms-list` | List SMS conversations and messages. |
| `termux-sms-send` | Send an SMS to one or more recipients. |
| `termux-speech-to-text` | Convert speech to text. |
| `termux-storage-get` | Request a file via system file picker, output to file. |
| `termux-telephony-call` | Call a phone number. |
| `termux-telephony-cellinfo` | Get cell info from all device radios. |
| `termux-telephony-deviceinfo` | Get telephony device information. |
| `termux-toast` | Show a transient toast popup message. |
| `termux-torch` | Toggle the LED torch on or off. |
| `termux-tts-engines` | List available TTS engines. |
| `termux-tts-speak` | Speak text using a TTS engine. |
| `termux-usb` | List or access USB devices. |
| `termux-vibrate` | Vibrate the device. |
| `termux-volume` | Change volume of an audio stream. |
| `termux-wake-lock` | Acquire wake lock to prevent CPU sleep. |
| `termux-wake-unlock` | Release the wake lock. |
| `termux-wallpaper` | Change the device wallpaper. |
| `termux-wifi-connectioninfo` | Get current Wi-Fi connection info. |
| `termux-wifi-enable` | Toggle Wi-Fi on or off. |
| `termux-wifi-scaninfo` | Get info from the last Wi-Fi scan. |

---

## Storage Symlinks

| Symlink | Real path |
| :--- | :--- |
| `~/storage/shared` | `/storage/emulated/0` |
| `~/storage/downloads` | `/storage/emulated/0/Download` |
| `~/storage/dcim` | `/storage/emulated/0/DCIM` |
| `~/storage/pictures` | `/storage/emulated/0/Pictures` |
| `~/storage/music` | `/storage/emulated/0/Music` |
| `~/storage/movies` | `/storage/emulated/0/Movies` |
| `~/storage/documents` | `/storage/emulated/0/Documents` |
