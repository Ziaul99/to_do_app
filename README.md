# To-do list

An offline-first Flutter task list with local persistence, task search and
filters, completion tracking, deletion, and an optional profile image.

## Requirements

- Flutter 3.44.8 (Dart 3.12.2) or a compatible newer stable release
- Android Studio with Android SDK and Java 17 for Android
- Visual Studio 2022 with the Desktop development with C++ workload for Windows

## Develop and verify

```sh
flutter pub get
flutter analyze --fatal-infos
flutter test --coverage
flutter run
```

Run on a connected Android device with `flutter run -d <device-id>` or on
Windows with `flutter run -d windows`. Use `flutter build apk --debug` and
`flutter build windows --release` to verify native builds locally.

GitHub Actions runs analysis, tests, an optimized web build, an Android debug
build, and a Windows release build on pushes and pull requests.

## Android release setup

Before publishing, create a permanent reverse-domain application ID and set
`ANDROID_APP_ID` in the build environment. The template `com.example` ID is
rejected for release builds. Do not change the ID after publishing.

Create an upload keystore and copy `android/key.properties.example` to
`android/key.properties`. Fill it with the keystore path and credentials. Both
the properties file and keystore are ignored by Git. Never commit signing keys
or passwords. Then build with:

```sh
flutter build appbundle --release
```

Release builds fail rather than falling back to the debug key. Back up the
keystore securely; losing it can prevent future app updates.

## iOS and store setup

In Xcode, replace `com.example.newProject` with the permanent bundle identifier
and configure the Apple development team and distribution signing. Before
submission, also provide final app icons, store listing content, privacy
disclosures, and any required account-specific permissions.

## Data and service boundaries

Tasks and the compressed profile image are stored locally in a Sembast
database, using app-support storage on native targets and IndexedDB on web.
Preferences-backed data from earlier versions is migrated on first launch.
There is no account system, cloud sync, server backup, push notification, or
remote crash/analytics service configured. Browser data can be lost when site
storage is cleared. Add a backend only when those product requirements and
retention guarantees are defined.
