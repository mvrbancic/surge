/// Bottom sheet for creating or editing a rest break item.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/training_item_model.dart';

/// Displays a modal bottom sheet for editing a [RestBreakItem].
///
/// Returns the updated [RestBreakItem] when the user taps Save,
/// or null if dismissed.
Future<RestBreakItem?> showRestBreakEditorSheet(
  BuildContext context, {
  RestBreakItem? initial,
  required int position,
}) {
  return showModalBottomSheet<RestBreakItem>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _RestBreakEditorSheet(initial: initial, position: position),
  );
}

class _RestBreakEditorSheet extends StatefulWidget {
  const _RestBreakEditorSheet({this.initial, required this.position});

  final RestBreakItem? initial;
  final int position;

  @override
  State<_RestBreakEditorSheet> createState() => _RestBreakEditorSheetState();
}

class _RestBreakEditorSheetState extends State<_RestBreakEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _duration;

  @override
  void initState() {
    super.initState();
    _duration = TextEditingController(
      text: widget.initial != null
          ? widget.initial!.durationSeconds.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _duration.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      RestBreakItem(
        id: widget.initial?.id,
        position: widget.position,
        durationSeconds: int.parse(_duration.text),
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
              widget.initial == null ? 'Add Rest Break' : 'Edit Rest Break',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
