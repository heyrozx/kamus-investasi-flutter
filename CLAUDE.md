# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

**Kamus Investasi** — an offline Indonesian investment-terms dictionary (Flutter, Android only — the iOS platform was removed in 1.1.0).
Package/bundle id: `com.caraguna.kamus.investasi`. Monetised with AdMob banner ads.
All 593 dictionary entries ship in the app bundle; there is no backend and no network API.

## Always update the changelog

**Whenever you make a change to this project, add an entry to [CHANGELOG.md](CHANGELOG.md).**

- Newest version goes at the **top** of the file.
- Heading format is `## <versionName> (<versionCode>)`, e.g. `## 1.0.9 (11)`.
- Entries are written in **Bahasa Indonesia**, one `*` bullet per change.
- When the change ships to users, bump `version:` in [pubspec.yaml](pubspec.yaml) as
  `versionName+versionCode` (both parts increment) and use those numbers in the heading.
- If several changes land under the same unreleased version, append bullets to the existing
  top section rather than creating a new one.

## Commands

The user builds and runs manually — do not run `flutter run`/`flutter build` unless asked.

```bash
flutter pub get
flutter analyze                 # lints: flutter_lints via analysis_options.yaml
flutter test
flutter build appbundle --release   # Play Store artifact
flutter build apk --release
dart run flutter_launcher_icons      # regenerate icons after changing assets/icon/*.png
```

## Build configuration

SDK levels in [android/app/build.gradle.kts](android/app/build.gradle.kts):

- `targetSdk = 36` (Android 16), pinned as a literal — Google Play requires target API ≥ 36 and
  this must not silently drop if an older Flutter SDK builds the project.
- `compileSdk = maxOf(flutter.compileSdkVersion, 36)` — floored at 36 for `targetSdk`, but it
  **must track the Flutter SDK upward**. Plugins compile against `flutter.compileSdkVersion`;
  if the app is pinned lower than a plugin, `checkReleaseAarMetadata` fails the build.
- `minSdk = flutter.minSdkVersion` (24 on the current Flutter SDK).

**A plugin with a hardcoded low `compileSdk` will break the release build.** This is what
`clipboard` 3.0.14 did (pinned at 33) — it was dropped in 1.0.9 in favour of Flutter's built-in
`Clipboard.setData`. If `checkReleaseAarMetadata` fails again, find the culprit with:

```bash
for p in $(python3 -c "import json;print('\n'.join(x['path'] for x in json.load(open('.flutter-plugins-dependencies'))['plugins']['android']))"); do
  echo "$(basename $p): $(grep -hE '^\s*compileSdk' $p/android/build.gradle* 2>/dev/null | tr -d '\n')"
done
```

Prefer replacing the dead plugin over forcing `compileSdk` on subprojects from the root Gradle file.

Toolchain (bump these together; these match the `flutter create` template of Flutter 3.47):

| Component | Version | File |
| --- | --- | --- |
| Gradle | 9.3.1 | [android/gradle/wrapper/gradle-wrapper.properties](android/gradle/wrapper/gradle-wrapper.properties) |
| Android Gradle Plugin | 9.1.0 | [android/settings.gradle.kts](android/settings.gradle.kts) |
| Kotlin | 2.4.0 | [android/settings.gradle.kts](android/settings.gradle.kts) |
| Java / JVM target | 17 | [android/app/build.gradle.kts](android/app/build.gradle.kts) |

AGP 9 runs with `android.builtInKotlin=false` and `android.newDsl=false` in
[android/gradle.properties](android/gradle.properties) (Flutter template defaults). The app module
does not apply `kotlin-android` itself — the Flutter Gradle Plugin applies it.

Release builds require `android/key.properties` (git-ignored) with `keyAlias`, `keyPassword`,
`storeFile`, `storePassword`. Without it the Gradle config throws on the `as String` casts —
that file is a local secret and must never be committed.

## Architecture

`lib/` is layered by responsibility, with no state-management package — plain `StatefulWidget`
plus `setState`, and repositories instantiated directly inside widgets.

```
lib/
  main.dart          MaterialApp + BottomNavigationBar shell (Home / Bookmark / Riwayat).
                     Seeds the DB on startup and gates the UI behind a loading screen.
  pages/             One screen per file. Feedback page exists but is commented out of the shell.
  models/            Plain classes with `fromJson`; snake_case DB columns → camelCase fields.
  databases/
    database_instance.dart      sqflite schema + column-name constants (tables: dictionaries,
                                bookmarks, histories). Schema version 1.
    <table>/<table>_repository.dart   All SQL lives here, written as raw query strings.
  utils/             datasets.dart (asset → DB seeding), json_configuration.dart, date_instance.dart
  shared/widgets/    banner_ad_widget.dart
assets/datasets/dictionaries.json    593 entries, the seed data
```

### Data flow gotchas

- **Seeding is count-based.** `DataSets.initDictionaries()` compares the row count against the
  hard-coded literal `593`; if it differs it wipes and re-inserts every row. **If you add or remove
  entries in `assets/datasets/dictionaries.json`, you must update that literal in
  [lib/utils/datasets.dart](lib/utils/datasets.dart)** or the new data will never be picked up.
- `initDictionaries()` returns `false` on both branches; `main.dart` treats `false` as "ready".
- Repositories build SQL by string interpolation. When touching a query, keep the existing
  `dbInstance.*` column constants — column names are not literals anywhere else.
- `DatabaseInstance` is constructed per repository, but sqflite caches the open handle by path,
  so this is effectively a shared connection. Schema changes need a `_databaseVersion` bump and an
  `onUpgrade` handler — there is none today, so existing installs would keep the old schema.

### Ads

[lib/shared/widgets/banner_ad_widget.dart](lib/shared/widgets/banner_ad_widget.dart) is the single
ad entry point. It picks the unit id from a `BannerPlacement` enum and **always** returns Google's
test unit in debug builds. Sizing uses `getCurrentOrientationAnchoredAdaptiveBannerAdSize` and the
`AdWidget` is wrapped in a `SizedBox` matching the loaded ad's exact size — this shape was adopted
to resolve AdMob "Resizing Ad Frames" policy warnings (see changelog 1.0.7/1.0.8). Don't wrap the
`AdWidget` in anything that stretches or scales it.

The AdMob app id lives in [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml).

### Material UI package

Flutter 3.47 moved Material out of the framework into the `material_ui` package. App code imports
`package:material_ui/material_ui.dart`, not `package:flutter/material.dart`. `upgrader`,
`fluttertoast` and `infinite_scroll` still use the old library, so `MaterialApp.builder` wraps the
tree in `MaterialUiCompatibilityBridge` (deprecated, migration-only). Drop it once those packages
migrate.

### Branding assets

- `assets/images/logo.png` — master logo, 1024px, gradient V on transparent background.
- `assets/icon/` — launcher icon sources: `launcher_icon.png` (legacy, white background),
  `launcher_foreground.png` (adaptive foreground, padding baked in, inset 0),
  `launcher_monochrome.png` (Android 13 themed icon).
- `store/play_store_icon_512.png` — Play Console listing icon (not bundled in the app).

## Conventions

- User-facing strings are **Bahasa Indonesia**; code identifiers and comments are English.
- Material 2 (`useMaterial3: false`) with the Raleway text theme from `google_fonts`.
- Brand colour is `Color.fromRGBO(65, 83, 181, 1)`, repeated inline rather than themed.
- Debug logging goes through `if (kDebugMode) print(...)`.

## Things to watch on Android 16

Targeting API 36 makes edge-to-edge display mandatory — apps can no longer opt out. `Scaffold`
handles insets for `AppBar` and `BottomNavigationBar` automatically, but
[lib/pages/home.dart](lib/pages/home.dart) draws its blue header inside a bare `Stack` with no
`SafeArea` and no `SystemUiOverlayStyle`, so status-bar icons sit over the header. Verify that
screen on a device before shipping.
