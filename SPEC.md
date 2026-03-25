# TRAINING APP
## Technical Specification Document
**Version 1.0 | Flutter + SQLite | March 2026**

---

## 1. Project Overview

Training App is a mobile application built with Flutter that allows users to create, manage, and execute custom workout training sessions. The app provides a structured timer-driven experience with audio notifications to guide users through exercises, inter-rep pauses, and rest breaks.

| Property | Value |
|---|---|
| Platform | iOS and Android (Flutter cross-platform) |
| Language | Dart (Flutter framework) |
| Local Storage | SQLite via sqflite package |
| State Management | Provider or Riverpod (recommended) |
| Audio | audioplayers package |
| Min SDK | Android 6.0 (API 23) / iOS 13.0 |

---

## 2. Core Domain Concepts

The app operates around four key entities: Training, Exercise, Segment, and the active Session runtime state.

### 2.1 Training

A Training is a named, ordered collection of Exercises and Rest Breaks. It is the top-level object a user creates, saves, and later runs.

### 2.2 Exercise

An Exercise is a timed activity block within a Training. It has the following configurable parameters:

- **Duration** — how long one rep lasts (in seconds)
- **Rep count** — how many times the exercise is repeated
- **Inter-rep pause** — rest duration between each rep (in seconds; can be 0)

### 2.3 Rest Break

A Rest Break is a standalone pause block between exercises. It has a single configurable parameter: duration in seconds.

### 2.4 Training Segment

At runtime, the Training is exploded into a flat, ordered list of Segments. Each segment is one of the following types:

- `EXERCISE` — a single rep of an exercise
- `INTER_REP_PAUSE` — the pause between two reps of the same exercise
- `REST_BREAK` — the rest break between two different exercises

**Example** — the training described in this brief would expand into segments as follows:

```
[1]  EXERCISE         Exercise 1  —  60s
[2]  INTER_REP_PAUSE  Exercise 1  —  10s
[3]  EXERCISE         Exercise 1  —  60s
[4]  INTER_REP_PAUSE  Exercise 1  —  10s
[5]  EXERCISE         Exercise 1  —  60s
[6]  REST_BREAK                   —  30s
[7]  EXERCISE         Exercise 2  —  120s
[8]  INTER_REP_PAUSE  Exercise 2  —  30s
     ... (x5 reps)
[17] REST_BREAK                   —  60s
[18] EXERCISE         Exercise 3  —  60s  (3 reps, 0s inter-rep pause)
     ...
```

---

## 3. Data Model

### 3.1 SQLite Schema

#### 3.1.1 trainings

```sql
CREATE TABLE trainings (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL,
  created_at  TEXT    NOT NULL,
  updated_at  TEXT    NOT NULL
);
```

#### 3.1.2 exercises

```sql
CREATE TABLE exercises (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  training_id      INTEGER NOT NULL REFERENCES trainings(id) ON DELETE CASCADE,
  position         INTEGER NOT NULL,   -- order within training (0-based)
  type             TEXT    NOT NULL,   -- 'exercise' | 'rest_break'
  name             TEXT,               -- null for rest_break
  duration_seconds INTEGER NOT NULL,
  rep_count        INTEGER,            -- null for rest_break
  inter_rep_pause  INTEGER             -- null / 0 for rest_break or no pause
);
```

> **Note:** Both exercise blocks and rest break blocks are stored in the same table using the `type` discriminator. This simplifies ordering and allows arbitrary interleaving.

### 3.2 Dart Model Classes

#### TrainingModel

```dart
class TrainingModel {
  final int?   id;
  final String name;
  final List<TrainingItemModel> items;  // ordered
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### TrainingItemModel (sealed / union)

```dart
sealed class TrainingItemModel {}

class ExerciseItem extends TrainingItemModel {
  final int?   id;
  final int    position;
  final String name;
  final int    durationSeconds;
  final int    repCount;
  final int    interRepPauseSeconds;  // 0 = no pause
}

class RestBreakItem extends TrainingItemModel {
  final int? id;
  final int  position;
  final int  durationSeconds;
}
```

#### TrainingSegment (runtime only, not persisted)

```dart
enum SegmentType { exercise, interRepPause, restBreak }

class TrainingSegment {
  final SegmentType type;
  final String?     exerciseName;   // null for restBreak
  final int         durationSeconds;
  final int?        repIndex;       // 1-based, for exercise/interRepPause
  final int?        totalReps;
}
```

---

## 4. Screen Architecture

| Screen | Purpose |
|---|---|
| HomeScreen | List of saved trainings with create, edit, delete, and start actions |
| CreateEditTrainingScreen | Form to set training name and manage the ordered list of exercises/rest breaks |
| ExerciseEditorSheet | Bottom sheet / dialog to configure a single exercise (name, duration, reps, pause) |
| RestBreakEditorSheet | Bottom sheet / dialog to configure a rest break duration |
| ActiveTrainingScreen | Full-screen timer view shown during a running training session |

### 4.1 HomeScreen

- Displays a scrollable list of `TrainingModel` objects fetched from SQLite
- Each card shows: training name, total duration (computed), number of exercises
- Actions per card: Start (play icon), Edit (pencil icon), Delete (trash icon with confirmation dialog)
- Floating action button to create a new training

### 4.2 CreateEditTrainingScreen

- Text field for training name (required, validated on save)
- Reorderable list (`ReorderableListView`) of training items
- Each item row shows type icon, name/label, duration summary, and edit/delete buttons
- Two add buttons at the bottom: "Add Exercise" and "Add Rest Break"
- Save button persists to SQLite (INSERT or UPDATE); back navigation prompts if unsaved changes exist

### 4.3 ActiveTrainingScreen

- Shown when user taps Start on HomeScreen
- Displays: current segment type label, exercise name (if applicable), rep counter (e.g. "Rep 2 of 5"), large countdown timer, progress bar or ring
- Next segment preview shown at the bottom (e.g. "Up next: 10s rest")
- Pause / Resume button; Stop button with confirmation
- Screen stays active (WakeLock) during session
- Audio cues fire automatically — see Section 6

---

## 5. Timer Engine

### 5.1 Segment Builder

Before starting a session the app builds the flat segment list from the `TrainingModel`. This is a pure function with no side effects:

```dart
List<TrainingSegment> buildSegments(TrainingModel training) {
  final segments = <TrainingSegment>[];
  for (final item in training.items) {
    if (item is RestBreakItem) {
      segments.add(TrainingSegment(type: SegmentType.restBreak, ...));
    } else if (item is ExerciseItem) {
      for (int rep = 1; rep <= item.repCount; rep++) {
        segments.add(TrainingSegment(type: SegmentType.exercise, repIndex: rep, ...));
        if (rep < item.repCount && item.interRepPauseSeconds > 0) {
          segments.add(TrainingSegment(type: SegmentType.interRepPause, ...));
        }
      }
    }
  }
  return segments;
}
```

### 5.2 Session Controller

The `SessionController` manages the live timer state. It should be implemented as a `ChangeNotifier` (or `StateNotifier` if using Riverpod).

| Field | Description |
|---|---|
| segments | `List<TrainingSegment>` — full segment list |
| currentIndex | `int` — index into segments |
| elapsed | `int` — seconds elapsed in current segment |
| isPaused | `bool` |
| isFinished | `bool` |

The controller drives a `dart:async` periodic Timer that fires every 1 second. On each tick:

1. Increment `elapsed`
2. Check audio cue triggers (see Section 6)
3. If `elapsed >= segment.durationSeconds`: advance to next segment (or set `isFinished`)

On pause: cancel the periodic timer but preserve state. On resume: restart the periodic timer from current state.

### 5.3 Remaining Time Calculation

```dart
int get remaining => current.durationSeconds - elapsed;
```

---

## 6. Audio Notification System

Audio cues are triggered by the `SessionController` on each timer tick. All cues should use short pre-recorded sound assets bundled in `assets/audio/`.

| Cue Name | Trigger Condition |
|---|---|
| `halfway` | Exercise segment only — fires once when `remaining == durationSeconds / 2` (integer division) |
| `ten_seconds` | Exercise segment only — fires once when `remaining == 10` (skip if segment duration <= 10s) |
| `countdown_3` | All segment types — fires once when `remaining == 3` |
| `countdown_2` | All segment types — fires once when `remaining == 2` |
| `countdown_1` | All segment types — fires once when `remaining == 1` |
| `segment_start` | Optional — plays at the start of each new segment |
| `session_complete` | Plays when `isFinished` becomes true |

To prevent a cue from firing more than once per segment, the controller tracks a `Set<String>` of cues already fired in the current segment, which resets on every segment transition.

### Recommended Flutter Package

`audioplayers ^6.0.0` — supports simultaneous playback, asset loading, and low-latency triggering on both iOS and Android.

### Audio Asset Bundle

```
assets/
  audio/
    halfway.mp3
    ten_seconds.mp3
    countdown_1.mp3
    countdown_2.mp3
    countdown_3.mp3
    segment_start.mp3
    session_complete.mp3
```

Declare in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/audio/
```

---

## 7. Data Access Layer

### 7.1 Database Helper

A singleton `DatabaseHelper` class wraps the `sqflite` Database instance. It handles initialization, migrations, and exposes raw query methods.

### 7.2 TrainingRepository

All UI-facing data access goes through `TrainingRepository`. This keeps business logic decoupled from SQLite specifics.

| Method | Signature & Purpose |
|---|---|
| `getAllTrainings()` | `Future<List<TrainingModel>>` — returns all trainings with their items |
| `getTraining(int id)` | `Future<TrainingModel?>` — single training by id |
| `saveTraining(TrainingModel)` | `Future<int>` — INSERT or UPDATE; returns id |
| `deleteTraining(int id)` | `Future<void>` — cascades to exercises table |

On save, the repository uses a database transaction to delete existing exercise rows for the training and re-insert the current list, preserving position ordering.

---

## 8. Package Dependencies

| Package | Purpose |
|---|---|
| `sqflite: ^2.3.0` | SQLite database access |
| `path: ^1.9.0` | File path utilities for DB location |
| `audioplayers: ^6.0.0` | Sound playback for cues |
| `provider: ^6.1.0` | State management (or `riverpod: ^2.5.0`) |
| `wakelock_plus: ^1.2.0` | Keep screen on during active session |
| `uuid: ^4.3.3` | Optional: client-side ID generation |

---

## 9. Suggested Project Structure

```
lib/
  main.dart
  app.dart                         // MaterialApp, theme, routing
  data/
    database_helper.dart
    training_repository.dart
  models/
    training_model.dart
    training_item_model.dart        // ExerciseItem, RestBreakItem
    training_segment.dart
  providers/                        // or notifiers/ if using Riverpod
    training_list_provider.dart
    session_controller.dart
  screens/
    home_screen.dart
    create_edit_training_screen.dart
    active_training_screen.dart
  widgets/
    training_card.dart
    exercise_editor_sheet.dart
    rest_break_editor_sheet.dart
    timer_display.dart
    segment_progress_bar.dart
  services/
    audio_service.dart
    segment_builder.dart
```

---

## 10. Non-Functional Requirements

| Requirement | Detail |
|---|---|
| Timer accuracy | Use `Stopwatch` alongside periodic Timer to compensate for tick drift; resync on each tick |
| Background behaviour | Timer pauses if app is backgrounded (acceptable for v1.0); foreground notification optional for v2 |
| Offline-first | All data is local SQLite; no network required |
| Accessibility | Semantic labels on timer elements; audio cues supplement (not replace) visual feedback |
| Screen orientation | Lock to portrait during active session |
| Persistence | Training data must survive app restart and OS-level process kill |
| Error handling | Validate all form inputs before save; wrap DB calls in try/catch with user-visible error snackbars |

---

## 11. Out of Scope (v1.0) / Future Considerations

- Cloud sync or account system
- Exercise library / catalogue (exercises are currently ad-hoc named strings)
- Workout history and statistics
- Background timer with persistent notification (foreground service)
- Video or image guidance per exercise
- Custom audio cue upload
- Apple Watch / Wear OS companion

---

## 12. Open Questions for Clarification

The following items are not yet fully specified and should be resolved before implementation begins:

| ID | Question |
|---|---|
| OQ-1 | Can a training have zero rest breaks (exercises back-to-back)? Assumed yes. |
| OQ-2 | Is there a maximum number of exercises per training? No hard limit assumed. |
| OQ-3 | Should the inter-rep pause audio cues match exercise cues (halfway + 10s) or just the 3-2-1 countdown? Spec currently uses 3-2-1 only for pauses. |
| OQ-4 | Should the user be able to skip to the next segment manually during a session? |
| OQ-5 | What happens if the phone is locked mid-session? Pause automatically or continue with audio only? |
| OQ-6 | Are exercise names unique within a training, or across the whole app? |
| OQ-7 | Should training items be duplicatable (copy an exercise block)? |

---

*End of Specification — v1.0*