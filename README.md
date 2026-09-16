# Debt Manager

A simple, modern, privacy-focused debt & lending tracker built around
**Qard Hasan** (interest-free loan) principles. It records who owes what,
tracks partial repayments, and reminds you of due dates — and it never
calculates interest, APR, or late-payment penalties.

> This app is a debt-recording and management tool. It does not provide a
> formal Shariah ruling or financial advice. Consult a qualified scholar
> for specific Islamic finance questions.

## What's included in this build (MVP)

Per the brief's own recommended path, this build ships the six-screen MVP
plus the full bottom-navigation shell, ready to extend:

- **Home** — greeting, "Money Owed to Me" / "Money I Owe" / "Net Debt
  Position" cards, upcoming due dates, recent activity, `+ Add Debt` FAB.
- **Add Debt** — Lent vs Borrowed selector, person (with a "pick from
  contacts" affordance), amount + currency, debt date, due date, notes.
  No interest field exists in the form, the model, or the database.
- **Debts** — "To Receive" / "To Pay" tabs, search, sort, and status
  filters.
- **Debt Details** — original / paid / remaining, progress bar, status
  badge, record payment / mark paid / delete (with confirmation), full
  payment history.
- **Record Payment** — partial or full repayment, payment method, blocks
  (with an explicit confirm) overpayment beyond the remaining balance.
- **Settings** — currency, appearance (light/dark/system), language
  (English/Arabic with full RTL), reminders toggle, PIN/biometric toggles,
  data section, and the Shariah disclaimer.
- **Calendar** and **Reports** screens are included and functional
  (color-coded due dates; totals + status/charts via `fl_chart`) so the
  5-tab bottom nav described in the brief is complete end to end.
- **Onboarding** — 3-screen intro with language switcher, explicitly
  stating the app never calculates interest.

## Architecture

```
lib/
  core/          constants, Material 3 theme, hand-written EN/AR
                 localization (no code-gen step required), formatters
  domain/        entities (Debt, Person, Payment, enums) + repository
                 interface — no framework or SQL leaks in here
  data/          sqflite schema (data/database) + repository
                 implementation (data/repositories)
  presentation/  Riverpod providers, screens, reusable widgets
  app_router.dart  go_router config (shell + pushed detail routes)
  main.dart        app entry point
```

Data flow: **UI → Riverpod providers → Repository interface → sqflite**.
All debt-status and remaining-balance math lives in
`domain/entities/debt.dart` (`DebtWithDetails`) — never hardcoded in a
widget — so it's covered by `test/debt_calculation_test.dart`.

### Why sqflite instead of Drift

The brief allows either. `sqflite` was chosen so the project **compiles
immediately with zero code-generation step** (`build_runner` isn't
required to build/run). Swapping to Drift later only touches
`data/database` and `data/repositories` — the domain layer and every
screen are unaffected because they only depend on `DebtRepository`.

### Why hand-written localization instead of `flutter gen-l10n`

Same reasoning: `lib/core/localization/app_localizations.dart` ships all
English/Arabic strings directly, so there's no ARB build step to run
before the app works. Add a string by adding one getter + one entry in
each of the `_en` / `_ar` maps.

## First-time setup (read this before `flutter run`)

This zip contains the Dart/Flutter source (`lib/`), `pubspec.yaml`, and
`test/` — **not** the native `android/`, `ios/` platform folders, since
generating those requires running the Flutter SDK, which isn't available
in the environment this project was built in. One command creates them:

```bash
flutter create . --org com.yourcompany --project-name debt_manager
flutter pub get
flutter run
```

`flutter create .` scaffolds `android/`, `ios/`, etc. **without touching**
any file already in `lib/`, `pubspec.yaml`, or `test/` — it only fills in
what's missing.

### Native permissions to add after scaffolding

A few features need entries in the generated platform files:

**`android/app/src/main/AndroidManifest.xml`** (inside `<manifest>`):
```xml
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```
And add `android:exported="true"` handling per `flutter_local_notifications`'
own setup docs for the notification receiver if you customize the manifest
further (the default `flutter create` manifest + plugin auto-registration
is sufficient for most cases).

**`ios/Runner/Info.plist`**:
```xml
<key>NSContactsUsageDescription</key>
<string>Used only when you tap "pick from contacts" when adding a debt.</string>
<key>NSFaceIDUsageDescription</key>
<string>Used to unlock the app when biometric app-lock is enabled.</string>
```

For the biometric app-lock's local-auth on Android, also confirm your
`android/app/build.gradle` `minSdkVersion` is **23+** (required by
`local_auth`).

## Building an Android APK

Building the APK itself has to run on your own machine — it needs the
Android SDK/toolchain, which isn't something that can be produced and
handed over as a file from outside a real build environment. The good
news is it's the simplest of the three build targets covered in this
README:

```bash
flutter create . --platforms=android
flutter pub get
flutter build apk --release
```

The output lands at `build\app\outputs\flutter-apk\app-release.apk`
(on Windows; same relative path on Mac/Linux). That single `.apk` file
is what you copy to a phone and install — enable "Install from unknown
sources" in Android's settings first, since it isn't from the Play
Store.

To test it on a connected phone or emulator without producing a file
first: `flutter run` (with a device connected/emulator open) works
exactly like the Windows/web instructions above.

If you'd rather test straight on your own phone while developing: plug
it in via USB, enable Developer Options → USB Debugging on the phone,
then `flutter devices` should list it, and `flutter run` will install
and launch the debug build directly.

## Building a portable Windows app (standalone, no browser/server needed)

This is the most self-contained way to run the app: one `.exe` with a
real, built-in SQLite database — no browser, no local web server, no
manual database asset setup. The database runs through
`sqflite_common_ffi` (native FFI bindings) on desktop, and
`sqlite3_flutter_libs` bundles the actual SQLite binary into your build
automatically, so nothing extra needs installing on the machine that
runs it.

### One-time setup: Visual Studio

Windows needs a C++ toolchain to compile desktop Flutter apps. If you
don't already have it:

1. Download **Visual Studio Community** (free) from
   [visualstudio.microsoft.com](https://visualstudio.microsoft.com/downloads/).
2. In the installer, check the **"Desktop development with C++"**
   workload, then install. This is a large download (several GB) and
   can take a while — it's the one unavoidable one-time cost of this
   approach.
3. Restart your PC after it finishes installing.

### Build and run

```bash
flutter create . --platforms=windows
flutter pub get
flutter run -d windows
```

`flutter run -d windows` opens the app in its own native window — no
browser tab, no `localhost` address. Add a debt and it saves instantly,
since the database is a real local file this time.

### Making it portable (a folder you can copy anywhere)

```bash
flutter build windows --release
```

This produces a folder at `build\windows\x64\runner\Release\` containing
`debt_manager.exe` plus a handful of `.dll` files it needs
alongside it. **Zip that entire folder** — that zip is your portable
app. Copy it to any other Windows machine, unzip, and double-click the
`.exe` — no Flutter, no Dart, nothing else needs installing there. (The
target machine does need the standard Microsoft Visual C++ Redistributable,
which the vast majority of Windows 10/11 PCs already have.)

## Running in a browser (Flutter Web)

The whole app runs in a browser via Flutter's web target. One codebase,
platform-aware where it has to be:

```bash
# If you haven't already scaffolded platform folders:
flutter create . --platforms=web

flutter pub get
flutter run -d chrome
```

To build a deployable static site instead of running the dev server:

```bash
flutter build web
# output lands in build/web/ — serve that folder with any static host
```

### One extra setup step: SQLite-on-web assets

The database uses `sqflite_common_ffi_web`, which runs SQLite in the
browser via WebAssembly and stores data in IndexedDB — so the same
`AppDatabase`/`DebtRepository` code works unchanged on web. That package
needs a couple of static files (typically `sqlite3.wasm` and
`sqflite_sw.js`) copied into your `web/` folder so the browser can load
them. The exact command/file names can change between package versions,
so check the **Web** setup section on the
[`sqflite_common_ffi_web` pub.dev page](https://pub.dev/packages/sqflite_common_ffi_web)
for the current instructions — it's normally a one-time `dart run` step
or a manual copy from the package's `example/web/` folder into yours.
If you skip this, the app will still build, but the database will fail
to open in the browser.

### What's different on the web build

Everything data-related — dashboard, Add Debt, Debts list, Debt Details,
Record Payment, Calendar, Reports, CSV/PDF export — works identically,
since it all goes through the same `DebtRepository` interface regardless
of platform. A few native-only features degrade gracefully instead of
crashing:

| Feature | Web behavior |
|---|---|
| PIN app-lock | **Works** — the PIN hash is stored via `flutter_secure_storage`'s web implementation (browser-side encrypted storage). |
| Biometric unlock | Not available (`local_auth` has no web implementation). The toggle is disabled with an explanatory note; the app just falls back to the PIN pad. |
| Reminders / notifications | Reminder rows still save to the database, but no browser notification fires (`flutter_local_notifications` has no official web target). The UI says so at save time. |
| Contacts picker | Hidden on web (`flutter_contacts` has no web implementation) — just type the name/phone directly in Add Debt. |
| Export (CSV/PDF) | **Works** — triggers a normal browser download instead of the native share sheet (see `core/services/export/`, which swaps implementations per platform via conditional imports). |

## Getting started (after the above)

```bash
flutter pub get
flutter run
```

Requires Flutter 3.22+ / Dart 3.3+. The app seeds a **small, clearly
separate demo dataset only when the database is empty** (see
`seedDemoData()` in `data/repositories/debt_repository_impl.dart`) so a
first run has something to look at; it never overwrites real data.

Run tests:

```bash
flutter test
```

## Security & privacy notes for this build

- 100% local-first: all data lives in a local SQLite file
  (`debt_manager.db`) under the app's documents directory.
  Nothing is transmitted anywhere by this codebase.
- **PIN lock**: `core/services/auth_service.dart` stores only a salted
  SHA-256 hash of the PIN in `flutter_secure_storage` (Android Keystore /
  iOS Keychain) — never the PIN itself. `presentation/screens/lock/`
  shows a full-screen PIN pad before any app content when app-lock is on
  (wired into `main.dart` via `MaterialApp.router`'s `builder`).
- **Biometric unlock**: `local_auth`-backed, offered automatically on the
  lock screen when enabled and available; falls back to the PIN pad if
  biometrics fail or aren't supported on the device.
- **Reminders**: `core/services/notification_service.dart` wraps
  `flutter_local_notifications` + `timezone` for fully offline scheduled
  reminders. Debt Details → "Add Reminder" opens a real offset picker
  (on due date / 1 / 3 / 7 days before) that writes to the `reminders`
  table and schedules the actual notification.
- **Contacts**: Add Debt's contacts icon requests **read-only** contacts
  permission only when tapped (never at launch), opens the OS contact
  picker via `flutter_contacts`, and fills in name + phone. Nothing is
  uploaded anywhere.
- **Export**: Settings → Export Data writes a CSV of all debts (no
  interest columns, obviously) and opens the OS share sheet. Debt
  Details has a PDF-export icon that generates the one-page report shown
  in the original spec, including the Shariah disclaimer in the footer.

## Known limitation: settings persistence

The PIN itself, and therefore whether app-lock is on, persists correctly
(it's derived from secure storage at every cold start — see
`_checkAppLock()` in `main.dart`). However, the *other* Settings values —
default currency, theme mode, language, reminders-enabled, biometric-
enabled — currently live in plain in-memory Riverpod `StateProvider`s
(`presentation/providers/settings_providers.dart`) and reset to their
defaults on a fresh app launch. Persisting them is a small, mechanical
change: swap each `StateProvider` for one backed by `shared_preferences`
(add the package, read the saved value in each provider's initial state,
write on every change).

## Roadmap (V2, as suggested in the original brief)

- CSV **import** and full backup/restore (export is done; the Settings
  rows for these are still placeholders).
- Attachments UI (the `attachments` table already exists in the schema;
  no picker/viewer screen yet).
- Cloud backup (explicitly opt-in only, per the privacy requirement).
- Swap the simple hand-rolled month grid in `calendar_screen.dart` for a
  richer calendar package if you want swipe gestures / multi-month views.
