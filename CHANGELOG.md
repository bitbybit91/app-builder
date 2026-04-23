# Changelog

All notable changes to CapitalMonero will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nothing yet — contributions welcome.

### Changed
- Nothing yet.

### Fixed
- Nothing yet.

---

## [1.0.0] - 2026-04-23

### Added
- Initial Flutter project skeleton for CapitalMonero P2P trading platform.
- `pubspec.yaml` with all pinned dependencies (BLoC, GoRouter, Dio, Drift, Firebase, etc.).
- `analysis_options.yaml` with strict Dart lints and `flutter_lints` integration.
- `l10n.yaml` for ARB-based localisations (English template `app_en.arb`).
- `android/gradle.properties` tuned for 4 GB RAM / low-spec host machines.
- `android/app/build.gradle` with `production`, `staging`, and `fdroid` flavors.
- `android/app/src/main/AndroidManifest.xml` with permissions, MainActivity, and FileProvider.
- `android/app/src/fdroid/AndroidManifest.xml` — Firebase-free manifest override.
- `ios/Runner/Info.plist` with camera, FaceID, and background-modes entries.
- `ios/Runner/AppDelegate.swift` with conditional Firebase initialisation.
- `ios/Podfile` targeting iOS 14.0.
- Comprehensive `.gitignore` excluding secrets, generated files, and build artefacts.
- Professional `README.md` with architecture diagram, build tips, and publishing guide.
- `LICENSE` — MIT 2026, CapitalMonero Contributors.

### Changed
- N/A — initial release.

### Fixed
- N/A — initial release.

[Unreleased]: https://github.com/bitbybit91/app-builder/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/bitbybit91/app-builder/releases/tag/v1.0.0
