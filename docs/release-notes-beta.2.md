# Darkian Studio 1.0.0-beta.2 — Stability Hotfix

## Overview

This is a **stability hotfix** for the first public beta (1.0.0-beta.1). It
does not add features. It fixes a critical startup crash that affected
**release** builds of Darkian Studio and could cause the app to exit
unexpectedly shortly after launch.

## Fixed

- Fixed a startup crash affecting release builds.
- Fixed an issue where the application could unexpectedly exit shortly after
  launch.
- Improved release stability.
- Corrected an Android dependency configuration issue.

## Technical details

- Removed an incorrect Android dependency that referenced the empty
  `com.google.guava:listenablefuture:9999.0-empty-to-avoid-conflict-with-guava`
  artifact.
- This resolved a runtime `NoClassDefFoundError` for
  `com.google.common.util.concurrent.ListenableFuture` that occurred on a
  background thread soon after startup.
- Debug builds were unaffected; the issue only impacted release APKs. Gradle
  now resolves the correct dependency graph naturally without the empty shim.

## Upgrade guidance

If you downloaded **1.0.0-beta.1**, please upgrade to **1.0.0-beta.2**. The
previous build can crash shortly after launch on a background thread; this
hotfix removes that failure. Install the new APK from the Releases page, or use
**Settings → About → Check for updates** inside DS.
