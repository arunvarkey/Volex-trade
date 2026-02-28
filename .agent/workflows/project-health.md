---
description: Steps to ensure the project environment is updated and verified
---

// turbo-all
# Project Health & Setup Workflow

Follow these steps when starting a work session or a new project to avoid version mismatches and build issues.

### 1. Update SDKs
Ensure you have the latest stable Flutter/Dart SDK.
```powershell
flutter upgrade
```

### 2. Synchronize Dependencies
Ensure all local packages match the `pubspec.yaml` state.
```powershell
flutter pub get
```

### 3. Verify Static Analysis
Catch lints and version-incompatible code before attempting to run.
```powershell
dart analyze
```

### 4. Check Platform Readiness
Verify that the intended target (Windows/Android/iOS) is ready.
```powershell
flutter doctor
```
