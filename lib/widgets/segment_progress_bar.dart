/// Linear progress indicator for the current training segment.
library;

import 'package:flutter/material.dart';

/// Shows how much of the current segment has elapsed.
class SegmentProgressBar extends StatelessWidget {
  const SegmentProgressBar({
    super.key,
    required this.elapsed,
    required this.total,
  });

  final int elapsed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;
    return LinearProgressIndicator(
      value: progress,
      minHeight: 8,
      borderRadius: BorderRadius.circular(4),
    );
  }
}
