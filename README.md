# Firebase Flutter Force Update

A Flutter package to enforce app updates based on a minimum version stored in Cloud Firestore.
Useful for preventing users from using outdated, broken, or deprecated versions of your app.

## Features

- **Real-time Version Check**: Listens to Firestore for immediate enforcement.
- **SemVer Comparison**: Accurately compares versions (e.g., `1.0.0` vs `1.0.1`).
- **Flexible UI**: Use the default "lock screen" or provide your own custom builder.
- **Safe**: Handles parsing errors gracefully.

## Installation

Add dependencies to `pubspec.yaml`:

```yaml
dependencies:
  cloud_firestore: latest_version
  package_info_plus: latest_version
  url_launcher: latest_version
  firebase_flutter_force_update:
    path: ./ # or git path
```

## Usage

Wrap your main app widget (or a high-level screen) with `ForceUpdateChecker`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_flutter_force_update/firebase_flutter_force_update.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return ForceUpdateChecker(
          firestoreCollection: 'app_config',
          firestoreDocument: 'force_update',
          versionField: 'minimumVersion', // e.g., "1.0.2"
          urlField: 'updateUrl', // e.g., "https://play.google.com/..."
          child: child!,
        );
      },
      home: const Scaffold(
        body: Center(child: Text('Hello World!')),
      ),
    );
  }
}
```

## Custom UI

You can provide a `updateScreenBuilder` to show a custom screen instead of the default one:

```dart
ForceUpdateChecker(
  // ... config
  updateScreenBuilder: (context, updateUrl) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text("Please update!"),
            ElevatedButton(
              onPressed: () => launchUrl(Uri.parse(updateUrl)),
              child: Text("Update"),
            ),
          ],
        ),
      ),
    );
  },
  child: child!,
)
```

## Firestore Structure

Create a document in Firestore:

- **Collection**: `app_config`
- **Document**: `force_update`
- **Fields**:
  - `minimumVersion` (string): e.g., "1.0.2"
  - `updateUrl` (string): e.g., "https://play.google.com/store/apps/details?id=com.example.app"

If the app's `version` (from pubspec.yaml) is lower than `minimumVersion`, the update screen will act as a barrier.
