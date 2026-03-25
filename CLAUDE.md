# CLAUDE.md

We're building the app described in @SPEC.MD. Read that file for general architectural tasks or to double-check the exact database structure, tech stack or application architecture.

Keep your replies extremely concise and focus on conveying the key information. No unnecessary fluff, no long code snippets.

Whenever working with any third-party library or something similar, you MUST look up the official documentation to ensure that you're working with up-to-date information.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run app in debug mode
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter analyze          # Lint and static analysis
flutter build apk        # Build Android APK
flutter build ios        # Build iOS
```

## Architecture

Surge is a Flutter training timer app (iOS/Android primary targets). The project is in early bootstrap stage — SPEC.md contains the full technical specification. `lib/main.dart` currently holds only the default Flutter counter template.

### Planned structure (from SPEC.md + README)

```
lib/
  main.dart
  app.dart
  data/
    database_helper.dart      # SQLite singleton (sqflite)
    training_repository.dart  # All UI-facing DB access
  models/
    training_model.dart       # Training + List<TrainingItemModel>
    training_item_model.dart  # Sealed: ExerciseItem | RestBreakItem
    training_segment.dart     # Runtime-only flat segment (SegmentType enum)
  providers/
    training_list_provider.dart
    session_controller.dart   # Timer state: segments, currentIndex, elapsed, isPaused
  screens/
    home_screen.dart
    create_edit_training_screen.dart
    active_training_screen.dart
  widgets/
    timer_display.dart
    segment_progress_bar.dart
    exercise_editor_sheet.dart
    rest_break_editor_sheet.dart
  services/
    audio_service.dart
    segment_builder.dart      # Pure fn: TrainingModel -> List<TrainingSegment>
```

### Key domain concepts

- **Training**: named, ordered list of `ExerciseItem` and `RestBreakItem`
- **TrainingSegment**: runtime-only flat expansion — one rep per segment, with `INTER_REP_PAUSE` segments inserted between reps
- **SessionController**: ChangeNotifier/StateNotifier; uses `dart:async` periodic Timer (1s) + Stopwatch for accuracy; drives audio cues based on `remaining = durationSeconds - elapsed`
- **Audio cues**: halfway, ten_seconds, countdown 3/2/1, segment_start, session_complete — assets live in `assets/audio/`

### SQLite schema

Two tables: `trainings` and `exercises`. The `exercises` table stores both `exercise` and `rest_break` types via a `type` TEXT column. `position` is 0-based ordering within a training. See SPEC.md for full DDL.

### Required packages (not yet added to pubspec.yaml)

| Package | Purpose |
|---|---|
| sqflite ^2.3.0 | SQLite |
| audioplayers ^6.0.0 | Audio cues |
| provider ^6.1.0 or riverpod ^2.5.0 | State management |
| wakelock_plus ^1.2.0 | Keep screen on during session |
| path ^1.9.0 | File path utilities |
