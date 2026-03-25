/// Large countdown timer display widget.
library;

import 'package:flutter/material.dart';

/// Displays [seconds] in MM:SS format with a large, bold style.
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key, required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    final label = '${mins.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';

    return Text(
      label,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
      ),
    );
  }
}
