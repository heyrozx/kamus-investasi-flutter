# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

**Kamus Investasi** — an offline Indonesian investment-terms dictionary (Flutter, Android only — the iOS platform was removed in 1.1.0).
Package/bundle id: `com.caraguna.kamus.investasi`. Monetised with AdMob banner ads.
All 1,018 dictionary entries ship in the app bundle; there is no backend and no network API.

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

**R8 + old Room = startup crash.** Release builds are minified with R8 full mode. `play-services-ads`
depends on `androidx.work:work-runtime:2.7.0` (Room 2.2.5), whose keep rules don't preserve
`WorkDatabase_Impl`'s no-arg constructor; 1.1.0 crashed on launch with *"Failed to create an
instance of androidx.work.impl.WorkDatabase"* from `androidx.startup.InitializationProvider`.
The app pins `work-runtime` 2.12.0 in `android/app/build.gradle.kts` and keeps `RoomDatabase`
constructors in [android/app/proguard-rules.pro](android/app/proguard-rules.pro) (Flutter picks
that file up automatically). Keep both; debug builds never show this, so test a **release** build
on a device before uploading.

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
                     Opens the DB on startup and gates the UI behind a loading screen.
  pages/             One screen per file. Feedback page exists but is commented out of the shell.
  models/            Plain classes with `fromJson`; snake_case DB columns → camelCase fields.
  databases/
    database_instance.dart      sqflite setup + column-name constants. Schema version 2.
    dictionaries/dictionary_db_version.dart   GENERATED — version of the bundled dictionary.db.
    <table>/<table>_repository.dart   All SQL lives here, written as raw query strings.
  utils/             date_instance.dart
  shared/widgets/    banner_ad_widget.dart
assets/datasets/dictionaries.json    1,018 entries — the source data (not bundled in the app)
assets/db/dictionary.db              GENERATED prebuilt SQLite database (bundled)
tool/dictionary_db/                  Standalone Dart package that generates the two files above
```

### Dictionary data

The dictionary ships as a prebuilt SQLite file; nothing is parsed or inserted at runtime.

- **Edit `assets/datasets/dictionaries.json`, then regenerate** with the VS Code task
  *Generate dictionary.db* (`.vscode/tasks.json`) or
  `cd tool/dictionary_db && dart pub get && dart run bin/build_dictionary_db.dart`.
  Commit both `assets/db/dictionary.db` and `dictionary_db_version.dart`.
- Two database files on device: `dictionary.db` (read-only, replaceable) and
  `kamus_investasi.db` (bookmarks, histories — user data). The user DB `ATTACH`es the dictionary
  as `dictionary_db` in `onOpen`, so the repositories' unqualified `dictionaries` and the JOINs
  against bookmarks/histories work unchanged. Never create a `dictionaries` table in the user DB:
  it would shadow the attached one.
- `dictionaryDbVersion` is a hash of the JSON (plus `schemaRevision` in the generator) and is
  written to the file's `PRAGMA user_version`. On startup `DatabaseInstance` re-copies the asset
  whenever the installed file's `user_version` differs — no manual version bump needed. Bump
  `schemaRevision` when the generator's table layout changes.
- **ids are the JSON order (1..n)**, matching what the pre-1.1.0 runtime seeding assigned.
  Bookmarks and histories store `dictionary_id`, so only append entries to the JSON; reordering
  or deleting entries silently repoints users' bookmarks.
- Schema v1 → v2 (`onUpgrade`) drops the old runtime-seeded `dictionaries` table from the user DB.
- `DatabaseInstance` caches one app-wide connection future in a static field; repositories still
  construct their own `DatabaseInstance` but share it.

### Data flow gotchas

- Repositories build SQL by string interpolation for identifiers. When touching a query, keep the
  existing `dbInstance.*` column constants — column names are not literals anywhere else.
- Values go in as `?` arguments, never interpolated. Never write string literals in double
  quotes (`col="x"`): SQLite builds without the legacy DQS quirk treat them as identifiers.
- Schema changes to the user DB need a `_databaseVersion` bump and an `onUpgrade` step.

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

- `assets/images/logo.png` — master logo, 1024px, gradient V on transparent background. Keeps
  the original icon's padding (V spans ~62% of the width); icons derive from it without re-cropping.
- `assets/icon/` — launcher icon sources: `launcher_icon.png` (legacy, white background),
  `launcher_foreground.png` (adaptive foreground, padding baked in, inset 0),
  `launcher_monochrome.png` (Android 13 themed icon).
- `store/` — Play Console assets (not bundled): `icon_512.png`, `feature_graphic_1024x500.png`,
  `screenshots/` (1080×1920, rendered from the real UI). See `store/README.md`. The hero
  screenshot and feature graphic say "1.000+" and "100% Offline" — keep both true (no
  network-only features, entries never drop below 1,000).

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
