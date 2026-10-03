# studycrowd

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Installing on an iPhone

Debug builds only run while attached to Xcode or `flutter run`, so to test
on a phone on its own, install a release build. Run from this directory:

```sh
flutter devices                       # find your phone's device ID
flutter build ios --release
flutter install --release -d <device-id>
```

Or build, install and launch with logs in one step:

```sh
flutter run --release -d <device-id>
```

If the app says "Untrusted Developer", go to **Settings → General → VPN &
Device Management** on the phone and trust the developer profile. Apps signed
with a free Apple team expire after 7 days; reinstall to refresh.
