# Darkian Studio 1.0.0-beta.1 — First Public Beta

Welcome to the first public beta of **Darkian Studio (DS)**, a real IDE that
runs on Android (via Termux) and Linux/macOS.

This release is about **release readiness**, not new IDE features: making DS
installable, supportable, and easy to debug for external users.

## Highlights

- **One-command setup.** Onboarding gives you a single command that installs
  the DS toolchain. The script is runtime-aware (Termux / Linux / macOS), shows
  progress, fails loudly on errors, and verifies the runtime before finishing.
- **In-app verification.** After running setup, tap **Verify setup** in DS to
  confirm node, dsterm, and code-server are present.
- **Check for updates.** Settings → About → Check for updates compares your
  installed build with the latest GitHub Release, shows release notes, and opens
  the APK. A lightweight startup check also nudges you when a newer beta exists.
- **Self-contained diagnostics.** All useful logs now flow into DS's own
  Diagnostics logs and Crash reports — no ADB/Flutter required to help us debug.

## How to get started

1. Install Termux from F-Droid.
2. Download the APK from the [Releases page](https://github.com/darkian-studio/app/releases).
3. Complete onboarding and run the setup command in Termux.
4. Tap **Verify setup**, then start coding.

## Known limitations

- **`dsterm` remote on Windows is not supported** in this beta.
- No Play Store build; GitHub Releases only.
- Beta tags may include breaking changes between releases.

## Feedback

File bugs and feature requests with the issue templates, and attach DS
diagnostics (Settings → Diagnostics). See the README for details.

Thank you for trying the first public beta.
