/// Home screen — displays the list of saved trainings.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/training_model.dart';
import '../providers/session_controller.dart';
import '../providers/training_list_provider.dart';
import '../widgets/training_card.dart';

/// Lists all saved trainings and provides create/start/edit/delete actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrainingListProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Surge')),
      body: Consumer<TrainingListProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          if (provider.trainings.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            itemCount: provider.trainings.length,
            itemBuilder: (context, index) {
              final training = provider.trainings[index];
              return TrainingCard(
                training: training,
                onStart: () => _startSession(context, training),
                onEdit: () => context.push('/training/${training.id}'),
                onDelete: () => _confirmDelete(context, provider, training),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/training/new'),
        tooltip: 'Create training',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _startSession(BuildContext context, TrainingModel training) {
    context.read<SessionController>().start(training);
    context.push('/session');
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TrainingListProvider provider,
    TrainingModel training,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete training?'),
        content: Text('Delete "${training.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && training.id != null) {
      await provider.delete(training.id!);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No trainings yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Tap + to create your first training.'),
        ],
      ),
    );
  }
}
