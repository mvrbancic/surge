/// Bottom sheet for creating or editing an exercise item.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/training_item_model.dart';

/// Displays a modal bottom sheet for editing an [ExerciseItem].
///
/// Returns the updated [ExerciseItem] when the user taps Save,
/// or null if dismissed.
Future<ExerciseItem?> showExerciseEditorSheet(
  BuildContext context, {
  ExerciseItem? initial,
  required int position,
}) {
  return showModalBottomSheet<ExerciseItem>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _ExerciseEditorSheet(initial: initial, position: position),
  );
}

class _ExerciseEditorSheet extends StatefulWidget {
  const _ExerciseEditorSheet({this.initial, required this.position});

  final ExerciseItem? initial;
  final int position;

  @override
  State<_ExerciseEditorSheet> createState() => _ExerciseEditorSheetState();
}

class _ExerciseEditorSheetState extends State<_ExerciseEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _duration;
  late final TextEditingController _reps;
  late final TextEditingController _pause;

  @override
  void initState() {
    super.initState();
    final ex = widget.initial;
    _name = TextEditingController(text: ex?.name ?? '');
    _duration = TextEditingController(
      text: ex != null ? ex.durationSeconds.toString() : '',
    );
    _reps = TextEditingController(
      text: ex != null ? ex.repCount.toString() : '1',
    );
    _pause = TextEditingController(
      text: ex != null ? ex.interRepPauseSeconds.toString() : '0',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _duration.dispose();
    _reps.dispose();
    _pause.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ExerciseItem(
        id: widget.initial?.id,
        position: widget.position,
        name: _name.text.trim(),
        durationSeconds: int.parse(_duration.text),
        repCount: int.parse(_reps.text),
        interRepPauseSeconds: int.parse(_pause.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initial == null ? 'Add Exercise' : 'Edit Exercise',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Exercise name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _duration,
              decoration: const InputDecoration(
                labelText: 'Duration (seconds)',
                suffixText: 's',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reps,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pause,
              decoration: const InputDecoration(
                labelText: 'Inter-rep pause (seconds)',
                suffixText: 's',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Enter 0 or more';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
