# Productivity Hub — Flutter App

A Flutter mobile app for students: To-Do List, Study Planner, Pomodoro Timer,
Notes, GPA Calculator, and Motivational Quotes. Data is saved on-device with
SharedPreferences, so it persists between app launches. Runs on both iOS and
Android from one codebase.

## 1. Install Flutter (one-time setup)

If you don't already have Flutter installed:
- Follow the official installer for your OS: https://docs.flutter.dev/get-started/install
- After installing, run `flutter doctor` in a terminal and follow any instructions
  it gives you (it checks you have everything needed for Android/iOS builds).

## 2. Get the project running

```
cd productivity_hub_flutter
flutter pub get
```

Then, with a device connected or a simulator/emulator running:

```
flutter run
```

### Easiest way to get a device/emulator:
- **Android**: install Android Studio, open "Device Manager," and start a virtual
  device — or plug in an Android phone with USB debugging enabled.
- **iOS (Mac only)**: install Xcode, then run `open -a Simulator` to launch the
  iOS Simulator.
- **Physical phone**: plug it in via USB. Run `flutter devices` to confirm it's
  detected, then `flutter run`.

`flutter run` builds the app and installs it directly on the connected
device/emulator — this is a real native app, not a preview.

## 3. Building an installable app file

Android (.apk, installable directly on any Android phone):
```
flutter build apk --release
```
The file appears at `build/app/outputs/flutter-apk/app-release.apk`.

iOS (.ipa — requires a Mac and an Apple Developer account to install outside
Xcode or submit to the App Store):
```
flutter build ipa --release
```

## App icon

A custom icon is already included at `assets/icon/icon.png` (plus separate
`icon_foreground.png` / `icon_background.png` layers for Android's adaptive
icon system), and `flutter_launcher_icons` is pre-configured in `pubspec.yaml`.

To generate all the platform-specific icon files (every iOS size, every
Android density, the adaptive icon, and the web favicon) in one step:

```
flutter pub get
dart run flutter_launcher_icons
```

Then just `flutter run` or `flutter build apk` as usual — the new icon is
picked up automatically. Re-run that command any time you replace the source
PNGs in `assets/icon/`.

## Project structure

```
lib/main.dart                  App entry point, bottom navigation
lib/theme.dart                 Colors, fonts, shared ThemeData
lib/storage.dart               SharedPreferences persistence helper
lib/data/quotes.dart           Motivational quotes data
lib/screens/todo_screen.dart       To-Do list
lib/screens/planner_screen.dart    Weekly study planner
lib/screens/timer_screen.dart      Pomodoro timer
lib/screens/notes_screen.dart      Notes (list + full-screen editor)
lib/screens/gpa_screen.dart        GPA calculator
lib/screens/quotes_screen.dart     Motivational quotes
```

## Notes

- No backend/server required — everything runs and stores data locally on the device.
- To reset saved data during testing, uninstall and reinstall the app.
