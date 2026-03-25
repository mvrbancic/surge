/// Pure function that expands a [TrainingModel] into a flat segment list.
library;

import '../models/training_item_model.dart';
import '../models/training_model.dart';
import '../models/training_segment.dart';

/// Builds the ordered, flat list of [TrainingSegment]s for a session.
///
/// No side effects — safe to call from any context.
List<TrainingSegment> buildSegments(TrainingModel training) {
  final segments = <TrainingSegment>[];

  for (final item in training.items) {
    switch (item) {
      case RestBreakItem():
        segments.add(
          TrainingSegment(
            type: SegmentType.restBreak,
            durationSeconds: item.durationSeconds,
          ),
        );

      case ExerciseItem():
        for (var rep = 1; rep <= item.repCount; rep++) {
          segments.add(
            TrainingSegment(
              type: SegmentType.exercise,
              exerciseName: item.name,
              durationSeconds: item.durationSeconds,
              repIndex: rep,
              totalReps: item.repCount,
            ),
          );

          final hasMoreReps = rep < item.repCount;
          final hasPause = item.interRepPauseSeconds > 0;
          if (hasMoreReps && hasPause) {
            segments.add(
              TrainingSegment(
                type: SegmentType.interRepPause,
                exerciseName: item.name,
                durationSeconds: item.interRepPauseSeconds,
                repIndex: rep,
                totalReps: item.repCount,
              ),
            );
          }
        }
    }
  }

  return segments;
}
