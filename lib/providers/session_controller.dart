/// Timer engine and audio cue manager for an active training session.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/training_model.dart';
import '../models/training_segment.dart';
import '../services/audio_service.dart';
import '../services/segment_builder.dart';

/// Manages the live state of a running training session.
///
/// Uses a [dart:async] periodic Timer (1 s) paired with a [Stopwatch] to
/// compensate for tick drift.
class SessionController extends ChangeNotifier {
  SessionController(this._audio);

  final AudioService _audio;

  List<TrainingSegment> _segments = [];
  int _currentIndex = 0;
  int _elapsed = 0;
  bool _isPaused = false;
  bool _isFinished = false;

  Timer? _timer;
  Stopwatch? _stopwatch;
  int _stopwatchBaseSeconds = 0;

  /// The full ordered segment list for the current session.
  List<TrainingSegment> get segments => _segments;

  /// Index into [segments] for the currently active segment.
  int get currentIndex => _currentIndex;

  TrainingSegment? get currentSegment =>
      _segments.isEmpty ? null : _segments[_currentIndex];

  TrainingSegment? get nextSegment {
    final next = _currentIndex + 1;
    return next < _segments.length ? _segments[next] : null;
  }

  /// Seconds elapsed within the current segment.
  int get elapsed => _elapsed;

  /// Seconds remaining in the current segment.
  int get remaining {
    final seg = currentSegment;
    if (seg == null) return 0;
    return (seg.durationSeconds - _elapsed).clamp(0, seg.durationSeconds);
  }

  bool get isPaused => _isPaused;
  bool get isFinished => _isFinished;

  final Set<String> _firedCues = {};

  /// Starts a new session for the given [training].
  void start(TrainingModel training) {
    _cleanup();
    _segments = buildSegments(training);
    _currentIndex = 0;
    _elapsed = 0;
    _isPaused = false;
    _isFinished = false;
    _firedCues.clear();

    _audio.play('segment_start');
    _startTimer();
    notifyListeners();
  }

  /// Pauses the session.
  void pause() {
    if (_isPaused || _isFinished) return;
    _isPaused = true;
    _timer?.cancel();
    _stopwatch?.stop();
    notifyListeners();
  }

  /// Resumes a paused session.
  void resume() {
    if (!_isPaused || _isFinished) return;
    _isPaused = false;
    _startTimer();
    notifyListeners();
  }

  /// Stops the session and resets state.
  void stop() {
    _cleanup();
    _segments = [];
    _currentIndex = 0;
    _elapsed = 0;
    _isPaused = false;
    _isFinished = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  void _startTimer() {
    _stopwatch = Stopwatch()..start();
    _stopwatchBaseSeconds = _elapsed;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (_isFinished) return;

    // Use stopwatch for accuracy.
    _elapsed =
        _stopwatchBaseSeconds + (_stopwatch?.elapsed.inSeconds ?? 0);

    final seg = currentSegment;
    if (seg == null) return;

    _checkAudioCues(seg);

    if (_elapsed >= seg.durationSeconds) {
      _advanceSegment();
    } else {
      notifyListeners();
    }
  }

  void _checkAudioCues(TrainingSegment seg) {
    final r = remaining;

    void fireOnce(String cue) {
      if (!_firedCues.contains(cue)) {
        _firedCues.add(cue);
        _audio.play(cue);
      }
    }

    if (seg.type == SegmentType.exercise) {
      final halfway = seg.durationSeconds ~/ 2;
      if (r == halfway && seg.durationSeconds > 1) fireOnce('halfway');
      if (r == 10 && seg.durationSeconds > 10) fireOnce('ten_seconds');
    }

    if (r == 3) fireOnce('countdown_3');
    if (r == 2) fireOnce('countdown_2');
    if (r == 1) fireOnce('countdown_1');
  }

  void _advanceSegment() {
    final next = _currentIndex + 1;
    if (next >= _segments.length) {
      _isFinished = true;
      _timer?.cancel();
      _stopwatch?.stop();
      _audio.play('session_complete');
      notifyListeners();
      return;
    }

    _currentIndex = next;
    _elapsed = 0;
    _stopwatchBaseSeconds = 0;
    _stopwatch
      ?..reset()
      ..start();
    _firedCues.clear();
    _audio.play('segment_start');
    notifyListeners();
  }

  void _cleanup() {
    _timer?.cancel();
    _stopwatch?.stop();
    _timer = null;
    _stopwatch = null;
  }
}
