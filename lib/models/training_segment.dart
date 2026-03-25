/// Runtime-only representation of a single timed unit during a session.
///
/// A [TrainingSegment] is never persisted; it is built from a [TrainingModel]
/// by [SegmentBuilder] before a session starts.
library;

/// The type of a single segment in a flattened training session.
enum SegmentType {
  /// A single rep of an exercise.
  exercise,

  /// The pause between two consecutive reps of the same exercise.
  interRepPause,

  /// A rest break between two different exercises.
  restBreak,
}

/// A single timed unit within a running training session.
class TrainingSegment {
  const TrainingSegment({
    required this.type,
    required this.durationSeconds,
    this.exerciseName,
    this.repIndex,
    this.totalReps,
  });

  final SegmentType type;

  /// Null for [SegmentType.restBreak].
  final String? exerciseName;

  final int durationSeconds;

  /// 1-based rep number. Null for [SegmentType.restBreak].
  final int? repIndex;

  /// Total reps for the parent exercise. Null for [SegmentType.restBreak].
  final int? totalReps;
}
