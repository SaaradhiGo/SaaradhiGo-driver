# saaradhigo_driver

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Branches and releases

- **Feature branches** open a PR into `dev`. CI must pass: `analyze and test` and `secret scan` (`ci.yml`; `flutter.yml` also builds a debug APK).
- **`dev` is QA.** The app has no QA server of its own: CI builds a debug APK from each commit as an artifact, pointed at the QA backend (which auto-deploys from the backend's `dev`).
- **`main` is production.** It takes pull requests from `dev` only (`source branch` check, `main-source.yml`), with every CI check green, merged with a merge commit. No direct pushes or force-pushes, for admins too.
- **Production releases only from `main`, through CI, never by hand.** When store releases exist, the signed build and the Play/App Store upload run from a push to `main` in CI, never from a laptop, `workflow_dispatch` or a console upload.
- **Today** there is no store release, so a merge to `main` publishes nothing.
