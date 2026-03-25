/// Domain models for items within a [TrainingModel].
library;

/// Base type for items that make up a training.
sealed class TrainingItemModel {
  const TrainingItemModel({required this.id, required this.position});

  /// Null when not yet persisted.
  final int? id;

  /// 0-based order within the parent training.
  final int position;
}

/// A timed, repeatable exercise block.
class ExerciseItem extends TrainingItemModel {
  const ExerciseItem({
    super.id,
    required super.position,
    required this.name,
    required this.durationSeconds,
    required this.repCount,
    required this.interRepPauseSeconds,
  });

  final String name;
  final int durationSeconds;
  final int repCount;

  /// 0 means no pause between reps.
  final int interRepPauseSeconds;
}

/// A fixed-duration rest break between exercises.
class RestBreakItem extends TrainingItemModel {
  const RestBreakItem({
    super.id,
    required super.position,
    required this.durationSeconds,
  });

  final int durationSeconds;
}
