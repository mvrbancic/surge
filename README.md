# ⚡ Surge

> **Beat the clock. Own every rep.**

Surge is a personal project — a Flutter training app I built to run customised interval workouts without the bloat of most fitness apps. You define your exercises, set how long each rep lasts, how long to rest between reps, and how long to rest between exercises. Hit start and Surge handles the rest: countdown timer, audio cues, the works.

No account. No subscription. No ads. Just you and the clock.

---

## 📱 Screenshots

> _Coming soon_

---

## ✨ What it does

- **Build any workout** — chain exercises and rest breaks in any order, each with their own timing
- **Full rep control** — set duration, rep count, and inter-rep pause individually per exercise
- **Precise segment engine** — automatically expands your workout into the exact sequence of reps, pauses, and breaks
- **Big countdown timer** — clean full-screen timer with progress ring and a preview of what's coming next
- **Audio cues** — halfway point bell, 10-second warning, and a 3-2-1 countdown before every segment ends
- **Pause & resume** — pause mid-session without losing your place
- **100% offline** — everything saved locally with SQLite, no internet or account needed

---

## 🏗️ Built with

| | |
|---|---|
| Framework | Flutter (Dart) |
| Database | SQLite via `sqflite` |
| State | Riverpod |
| Audio | `audioplayers` |
| Wake lock | `wakelock_plus` |

---

## 🚀 Running it locally

```bash
git clone https://github.com/your-username/surge.git
cd surge
flutter pub get
flutter run
```

Requires Flutter `>=3.0.0` and a connected device or emulator.

---

## 📁 Structure

```
lib/
  main.dart
  app.dart
  data/
    database_helper.dart
    training_repository.dart
  models/
    training_model.dart
    training_item_model.dart
    training_segment.dart
  providers/
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

## 🗺️ What's next

- [ ] Background timer with lock screen notification
- [ ] Exercise library
- [ ] Wear OS / Apple Watch

---

## 📄 License

MIT — do whatever you want with it.
