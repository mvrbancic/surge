/// Audio playback service for session cues.
library;

import 'dart:developer' as developer;

import 'package:audioplayers/audioplayers.dart';

/// Plays short audio cues from the app's asset bundle.
///
/// Audio files must exist at `assets/audio/<cue>.mp3`.
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  /// Plays the named cue. Silently ignores errors (e.g. missing asset).
  Future<void> play(String cue) async {
    try {
      await _player.play(AssetSource('audio/$cue.mp3'));
    } catch (e, s) {
      developer.log(
        'AudioService: failed to play "$cue"',
        name: 'surge.audio',
        level: 800,
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
