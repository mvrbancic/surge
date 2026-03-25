/// Full-screen timer view for an active training session.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/training_segment.dart';
import '../providers/session_controller.dart';
import '../widgets/segment_progress_bar.dart';
import '../widgets/timer_display.dart';

/// Displays the running session with timer, progress, and controls.
class ActiveTrainingScreen extends StatefulWidget {
  const ActiveTrainingScreen({super.key});

  @override
  State<ActiveTrainingScreen> createState() => _ActiveTrainingScreenState();
}

class _ActiveTrainingScreenState extends State<ActiveTrainingScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _confirmStop(BuildContext context) async {
    final controller = context.read<SessionController>();
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop session?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      controller.stop();
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SessionController>(
        builder: (context, controller, _) {
          if (controller.isFinished) {
            return _CompletionView(onDone: () => context.pop());
          }

          final seg = controller.currentSegment;
          if (seg == null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.pop(),
            );
            return const SizedBox.shrink();
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _TopBar(onStop: () => _confirmStop(context)),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SegmentLabel(segment: seg),
                        const SizedBox(height: 8),
                        _RepCounter(segment: seg),
                        const SizedBox(height: 32),
                        TimerDisplay(seconds: controller.remaining),
                        const SizedBox(height: 32),
                        SegmentProgressBar(
                          elapsed: controller.elapsed,
                          total: seg.durationSeconds,
                        ),
                      ],
                    ),
                  ),
                  _NextSegmentPreview(segment: controller.nextSegment),
                  const SizedBox(height: 24),
                  _PauseResumeButton(
                    isPaused: controller.isPaused,
                    onToggle: controller.isPaused
                        ? controller.resume
                        : controller.pause,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Active Session', style: Theme.of(context).textTheme.titleMedium),
        TextButton.icon(
          onPressed: onStop,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
        ),
      ],
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({required this.segment});

  final TrainingSegment segment;

  @override
  Widget build(BuildContext context) {
    final label = switch (segment.type) {
      SegmentType.exercise => segment.exerciseName ?? 'Exercise',
      SegmentType.interRepPause => 'Rest',
      SegmentType.restBreak => 'Rest Break',
    };
    final color = switch (segment.type) {
      SegmentType.exercise => Theme.of(context).colorScheme.primary,
      SegmentType.interRepPause => Theme.of(context).colorScheme.tertiary,
      SegmentType.restBreak => Theme.of(context).colorScheme.secondary,
    };

    return Text(
      label,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _RepCounter extends StatelessWidget {
  const _RepCounter({required this.segment});

  final TrainingSegment segment;

  @override
  Widget build(BuildContext context) {
    if (segment.repIndex == null || segment.totalReps == null) {
      return const SizedBox.shrink();
    }
    return Text(
      'Rep ${segment.repIndex} of ${segment.totalReps}',
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

class _NextSegmentPreview extends StatelessWidget {
  const _NextSegmentPreview({this.segment});

  final TrainingSegment? segment;

  @override
  Widget build(BuildContext context) {
    if (segment == null) return const SizedBox.shrink();

    final label = switch (segment!.type) {
      SegmentType.exercise =>
        'Up next: ${segment!.exerciseName} · ${segment!.durationSeconds}s',
      SegmentType.interRepPause =>
        'Up next: Rest · ${segment!.durationSeconds}s',
      SegmentType.restBreak =>
        'Up next: Rest Break · ${segment!.durationSeconds}s',
    };

    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
    );
  }
}

class _PauseResumeButton extends StatelessWidget {
  const _PauseResumeButton({
    required this.isPaused,
    required this.onToggle,
  });

  final bool isPaused;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onToggle,
        icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
        label: Text(isPaused ? 'Resume' : 'Pause'),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Session Complete!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: onDone, child: const Text('Done')),
        ],
      ),
    );
  }
}
