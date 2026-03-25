/// Card widget for displaying a training in the home screen list.
library;

import 'package:flutter/material.dart';

import '../models/training_item_model.dart';
import '../models/training_model.dart';

/// A card showing training summary with start, edit, and delete actions.
class TrainingCard extends StatelessWidget {
  const TrainingCard({
    super.key,
    required this.training,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainingModel training;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSeconds = _totalDuration(training);
    final exerciseCount = training.items.whereType<ExerciseItem>().length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    training.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'} · '
                    '${_formatDuration(totalSeconds)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: 'Start',
              onPressed: training.items.isEmpty ? null : onStart,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  int _totalDuration(TrainingModel t) {
    var total = 0;
    for (final item in t.items) {
      switch (item) {
        case ExerciseItem():
          final repTotal = item.durationSeconds * item.repCount;
          final pauseTotal =
              item.interRepPauseSeconds * (item.repCount - 1).clamp(0, 999);
          total += repTotal + pauseTotal;
        case RestBreakItem():
          total += item.durationSeconds;
      }
    }
    return total;
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return secs == 0 ? '${mins}m' : '${mins}m ${secs}s';
  }
}
