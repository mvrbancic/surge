/// State management for the training list.
library;

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../data/training_repository.dart';
import '../models/training_model.dart';

/// Manages the list of trainings and exposes CRUD operations to the UI.
class TrainingListProvider extends ChangeNotifier {
  TrainingListProvider(this._repository);

  final TrainingRepository _repository;

  List<TrainingModel> _trainings = [];
  bool _isLoading = false;
  String? _error;

  List<TrainingModel> get trainings => _trainings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads all trainings from the database.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trainings = await _repository.getAllTrainings();
    } catch (e, s) {
      _error = 'Failed to load trainings.';
      developer.log(
        'TrainingListProvider.load failed',
        name: 'surge.provider',
        level: 1000,
        error: e,
        stackTrace: s,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves (insert or update) a training and reloads the list.
  Future<void> save(TrainingModel training) async {
    try {
      await _repository.saveTraining(training);
      await load();
    } catch (e, s) {
      _error = 'Failed to save training.';
      developer.log(
        'TrainingListProvider.save failed',
        name: 'surge.provider',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      notifyListeners();
    }
  }

  /// Deletes a training by id and reloads the list.
  Future<void> delete(int id) async {
    try {
      await _repository.deleteTraining(id);
      await load();
    } catch (e, s) {
      _error = 'Failed to delete training.';
      developer.log(
        'TrainingListProvider.delete failed',
        name: 'surge.provider',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      notifyListeners();
    }
  }
}
