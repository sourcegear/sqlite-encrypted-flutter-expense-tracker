# Encrypted Flutter Expense Tracker

A cross-platform Flutter sample that stores expenses in an encrypted SQLite
database using the published `sqlite_encrypted` package and official SQLite
Encryption Extension (SEE).

The sample demonstrates:

- installing SQLite.Encrypted packages from `packages.sourcegear.com`;
- activating SEE and reporting missing or invalid activation keys clearly;
- opening an encrypted database with the keyed `openDatabase()` API;
- ordinary `sqflite` inserts, queries, filtering, and deletes;
- generating a random database key and protecting it with the platform's secure
  credential store; and
- using the same application on Android, iOS, Windows, macOS, and Linux.

## Prerequisites

- Flutter with tooling for your target platform
- a SQLite.Encrypted activation key. You can request an evaluation key at
  <http://sqlite.sourcegear.com/#evaluation>.

The activation key must cover the platform and SQLite minor version bundled in
the selected `sqlite_encrypted` package. An activation key issued for an older
minor version will be rejected by a newer package.

The value passed to `activateSee()` is the activation hex string itself. Do not
include the `see-` prefix used by the PRAGMA form.

On iOS, the sample enables Keychain Sharing as required by
`flutter_secure_storage`. On macOS it uses the legacy Keychain so a local sample
build does not require a provisioning profile.

On Linux, `flutter_secure_storage` requires the system `libsecret` development
package. For Debian or Ubuntu:

```bash
sudo apt-get install libsecret-1-dev
```

## Run the sample

From this directory:

```bash
flutter pub get
flutter run \
  --dart-define=SQLITE_ENCRYPTED_ACTIVATION_KEY=<your-activation-key>
```

Select a target explicitly when more than one is available:

```bash
flutter run -d windows \
  --dart-define=SQLITE_ENCRYPTED_ACTIVATION_KEY=<your-activation-key>
```

PowerShell uses a backtick instead of a backslash for line continuation:

```powershell
flutter run -d windows `
  --dart-define=SQLITE_ENCRYPTED_ACTIVATION_KEY=<your-activation-key>
```

Other common device values include `macos`, `linux`, and the identifier shown by
`flutter devices` for a phone, simulator, or emulator.

The activation key is supplied as a compile-time definition for this compact
sample. Production applications should choose a delivery strategy appropriate
to their threat model rather than committing the key to source control.

## Package source

Both SQLite.Encrypted Flutter packages come from the SourceGear Pub repository:

```yaml
dependencies:
  sqflite_common_ffi:
    hosted: https://packages.sourcegear.com/pub
    version: 3.54.0
  sqlite_encrypted:
    hosted: https://packages.sourcegear.com/pub
    version: 3.54.0
```

The application calls `sqfliteFfiInit()` on desktop platforms before assigning
`databaseFactoryFfi`. Mobile platforms use the platform implementation selected
by the `sqlite_encrypted` package.

## Key handling

On first launch, the app creates a random 256-bit database key and stores it
with `flutter_secure_storage`. Later launches retrieve that same key before
opening `expense_tracker.db`. Expense data is manipulated through the ordinary
`sqflite` API after the keyed open succeeds.

Removing the application's secure-storage entry while retaining its database
will make that database unreadable. A real application should define its own
backup, recovery, and key-rotation policy.
