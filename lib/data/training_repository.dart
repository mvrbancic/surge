/// All UI-facing data access for trainings and their items.
library;

import 'dart:developer' as developer;

import 'package:sqflite/sqflite.dart';

import '../models/training_item_model.dart';
import '../models/training_model.dart';
import 'database_helper.dart';

/// Provides CRUD operations for [TrainingModel] objects backed by SQLite.
class TrainingRepository {
  Future<Database> get _db => DatabaseHelper.instance.database;

  /// Returns all trainings with their items, ordered by creation date.
  Future<List<TrainingModel>> getAllTrainings() async {
    try {
      final db = await _db;
      await db.execute('PRAGMA foreign_keys = ON');
      final rows = await db.query('trainings', orderBy: 'created_at ASC');
      final trainings = <TrainingModel>[];
      for (final row in rows) {
        final id = row['id'] as int;
        final items = await _getItems(db, id);
        trainings.add(_trainingFromRow(row, items));
      }
      return trainings;
    } catch (e, s) {
      developer.log(
        'getAllTrainings failed',
        name: 'surge.repository',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Returns a single training by [id], or null if not found.
  Future<TrainingModel?> getTraining(int id) async {
    try {
      final db = await _db;
      await db.execute('PRAGMA foreign_keys = ON');
      final rows = await db.query(
        'trainings',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) return null;
      final items = await _getItems(db, id);
      return _trainingFromRow(rows.first, items);
    } catch (e, s) {
      developer.log(
        'getTraining($id) failed',
        name: 'surge.repository',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Inserts or updates a training and its items. Returns the training id.
  Future<int> saveTraining(TrainingModel training) async {
    try {
      final db = await _db;
      await db.execute('PRAGMA foreign_keys = ON');
      final now = DateTime.now().toIso8601String();

      return db.transaction<int>((txn) async {
        final int trainingId;
        if (training.id == null) {
          trainingId = await txn.insert('trainings', {
            'name': training.name,
            'created_at': now,
            'updated_at': now,
          });
        } else {
          trainingId = training.id!;
          await txn.update(
            'trainings',
            {'name': training.name, 'updated_at': now},
            where: 'id = ?',
            whereArgs: [trainingId],
          );
          await txn.delete(
            'exercises',
            where: 'training_id = ?',
            whereArgs: [trainingId],
          );
        }

        for (final item in training.items) {
          await txn.insert('exercises', _itemToRow(item, trainingId));
        }

        return trainingId;
      });
    } catch (e, s) {
      developer.log(
        'saveTraining failed',
        name: 'surge.repository',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Deletes a training and all its items (via CASCADE).
  Future<void> deleteTraining(int id) async {
    try {
      final db = await _db;
      await db.execute('PRAGMA foreign_keys = ON');
      await db.delete('trainings', where: 'id = ?', whereArgs: [id]);
    } catch (e, s) {
      developer.log(
        'deleteTraining($id) failed',
        name: 'surge.repository',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<List<TrainingItemModel>> _getItems(Database db, int trainingId) async {
    final rows = await db.query(
      'exercises',
      where: 'training_id = ?',
      whereArgs: [trainingId],
      orderBy: 'position ASC',
    );
    return rows.map(_itemFromRow).toList();
  }

  TrainingModel _trainingFromRow(
    Map<String, Object?> row,
    List<TrainingItemModel> items,
  ) {
    return TrainingModel(
      id: row['id'] as int,
      name: row['name'] as String,
      items: items,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  TrainingItemModel _itemFromRow(Map<String, Object?> row) {
    final type = row['type'] as String;
    final id = row['id'] as int;
    final position = row['position'] as int;

    if (type == 'rest_break') {
      return RestBreakItem(
        id: id,
        position: position,
        durationSeconds: row['duration_seconds'] as int,
      );
    }

    return ExerciseItem(
      id: id,
      position: position,
      name: row['name'] as String,
      durationSeconds: row['duration_seconds'] as int,
      repCount: row['rep_count'] as int,
      interRepPauseSeconds: (row['inter_rep_pause'] as int?) ?? 0,
    );
  }

  Map<String, Object?> _itemToRow(TrainingItemModel item, int trainingId) {
    return switch (item) {
      RestBreakItem() => {
        'training_id': trainingId,
        'position': item.position,
        'type': 'rest_break',
        'name': null,
        'duration_seconds': item.durationSeconds,
        'rep_count': null,
        'inter_rep_pause': null,
      },
      ExerciseItem() => {
        'training_id': trainingId,
        'position': item.position,
        'type': 'exercise',
        'name': item.name,
        'duration_seconds': item.durationSeconds,
        'rep_count': item.repCount,
        'inter_rep_pause': item.interRepPauseSeconds,
      },
    };
  }
}
