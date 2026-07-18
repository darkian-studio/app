# Changelog

All notable changes to Darkian Studio public releases are documented here.
This file follows a simplified keep-a-changelog style. Releases are published
on GitHub Releases; APKs are attached there.

## [1.0.0-beta.1] - Unreleased (first public beta)

### Added
- First public beta of Darkian Studio (Android APK via GitHub Releases).
- Onboarding runtime setup with a single copy-paste command.
- `install.sh` setup script, runtime-aware for Termux, Linux, and macOS, with
  progress/error output and a post-install verification step.
- In-app **Check for updates** (Settings → About) plus a best-effort startup
  update check against GitHub Releases.
- In-app runtime verification during onboarding (node / dsterm / code-server).
- Diagnostics logs and crash reports surfaced entirely inside the app.

### Changed
- All `debugPrint()` diagnostics in the app are now routed through the DS
  logging system so they appear in Diagnostics logs and crash reports.

### Known limitations
- `dsterm` remote on Windows is not supported in this beta.
- No Play Store distribution; APKs are GitHub Releases only.

---

## Release notes template (used per release)

```
## [X.Y.Z] - YYYY-MM-DD

### Added
-

### Changed
-

### Fixed
-

### Known limitations
-
```
