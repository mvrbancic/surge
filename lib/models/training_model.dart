/// Top-level training domain model.
library;

import 'training_item_model.dart';

/// A named, ordered collection of exercises and rest breaks.
class TrainingModel {
  const TrainingModel({
    this.id,
    required this.name,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Null when not yet persisted.
  final int? id;
  final String name;

  /// Ordered list of [ExerciseItem] and [RestBreakItem] entries.
  final List<TrainingItemModel> items;

  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingModel copyWith({
    int? id,
    String? name,
    List<TrainingItemModel>? items,
    DateTime? updatedAt,
  }) {
    return TrainingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
