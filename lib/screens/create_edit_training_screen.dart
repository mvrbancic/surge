/// Screen for creating or editing a training.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/training_item_model.dart';
import '../models/training_model.dart';
import '../providers/training_list_provider.dart';
import '../widgets/exercise_editor_sheet.dart';
import '../widgets/rest_break_editor_sheet.dart';

/// Allows the user to set the training name and manage its ordered items.
class CreateEditTrainingScreen extends StatefulWidget {
  const CreateEditTrainingScreen({super.key, this.trainingId});

  /// Null when creating a new training.
  final int? trainingId;

  @override
  State<CreateEditTrainingScreen> createState() =>
      _CreateEditTrainingScreenState();
}

class _CreateEditTrainingScreenState extends State<CreateEditTrainingScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<TrainingItemModel> _items = [];
  bool _isDirty = false;
  bool _isSaving = false;
  TrainingModel? _original;

  @override
  void initState() {
    super.initState();
    if (widget.trainingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  Future<void> _loadExisting() async {
    final provider = context.read<TrainingListProvider>();
    final training = provider.trainings.firstWhere(
      (t) => t.id == widget.trainingId,
      orElse: () => TrainingModel(
        name: '',
        items: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    setState(() {
      _original = training;
      _nameController.text = training.name;
      _items = List.of(training.items);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.trainingId != null;

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final training = TrainingModel(
      id: _original?.id,
      name: _nameController.text.trim(),
      items: _reindexed(_items),
      createdAt: _original?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await context.read<TrainingListProvider>().save(training);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<TrainingItemModel> _reindexed(List<TrainingItemModel> items) {
    return [
      for (var i = 0; i < items.length; i++)
        switch (items[i]) {
          ExerciseItem ex => ExerciseItem(
            id: ex.id,
            position: i,
            name: ex.name,
            durationSeconds: ex.durationSeconds,
            repCount: ex.repCount,
            interRepPauseSeconds: ex.interRepPauseSeconds,
          ),
          RestBreakItem rb => RestBreakItem(
            id: rb.id,
            position: i,
            durationSeconds: rb.durationSeconds,
          ),
        },
    ];
  }

  Future<void> _addExercise() async {
    final item = await showExerciseEditorSheet(
      context,
      position: _items.length,
    );
    if (item != null) {
      setState(() {
        _items.add(item);
        _isDirty = true;
      });
    }
  }

  Future<void> _addRestBreak() async {
    final item = await showRestBreakEditorSheet(
      context,
      position: _items.length,
    );
    if (item != null) {
      setState(() {
        _items.add(item);
        _isDirty = true;
      });
    }
  }

  Future<void> _editItem(int index) async {
    final item = _items[index];
    if (item is ExerciseItem) {
      final updated = await showExerciseEditorSheet(
        context,
        initial: item,
        position: index,
      );
      if (updated != null) {
        setState(() {
          _items[index] = updated;
          _isDirty = true;
        });
      }
    } else if (item is RestBreakItem) {
      final updated = await showRestBreakEditorSheet(
        context,
        initial: item,
        position: index,
      );
      if (updated != null) {
        setState(() {
          _items[index] = updated;
          _isDirty = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final router = GoRouter.of(context);
          final leave = await _onWillPop();
          if (leave && mounted) router.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Training' : 'New Training'),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          onChanged: _markDirty,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Training name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                ),
              ),
              Expanded(child: _buildItemList()),
              _AddButtons(
                onAddExercise: _addExercise,
                onAddRestBreak: _addRestBreak,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemList() {
    if (_items.isEmpty) {
      return const Center(
        child: Text('Add exercises or rest breaks below.'),
      );
    }

    return ReorderableListView.builder(
      itemCount: _items.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
          _isDirty = true;
        });
      },
      itemBuilder: (context, index) {
        final item = _items[index];
        return _ItemRow(
          key: ValueKey(item),
          item: item,
          onEdit: () => _editItem(index),
          onDelete: () => setState(() {
            _items.removeAt(index);
            _isDirty = true;
          }),
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainingItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (item) {
      ExerciseItem ex => (
        Icons.fitness_center,
        ex.name,
        '${ex.durationSeconds}s × ${ex.repCount} rep${ex.repCount == 1 ? '' : 's'}'
            '${ex.interRepPauseSeconds > 0 ? ' · ${ex.interRepPauseSeconds}s pause' : ''}',
      ),
      RestBreakItem rb => (
        Icons.self_improvement,
        'Rest Break',
        '${rb.durationSeconds}s',
      ),
    };

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
          const Icon(Icons.drag_handle),
        ],
      ),
    );
  }
}

class _AddButtons extends StatelessWidget {
  const _AddButtons({
    required this.onAddExercise,
    required this.onAddRestBreak,
  });

  final VoidCallback onAddExercise;
  final VoidCallback onAddRestBreak;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAddExercise,
                icon: const Icon(Icons.fitness_center),
                label: const Text('Add Exercise'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAddRestBreak,
                icon: const Icon(Icons.self_improvement),
                label: const Text('Add Rest Break'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
