import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Lecteur d'un fichier audio déjà embarqué dans l'application.
class AudioEngineService {
  AudioEngineService() {
    _initAudioEngine();
  }

  final AudioPlayer _player = AudioPlayer();

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackRate = 1.0;
  String? _currentAsset;
  String? _errorMessage;

  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  // Callbacks pour mise à jour de l'UI
  VoidCallback? onStateChanged;

  PlayerState get playerState => _playerState;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  Duration get position => _position;
  Duration get duration => _duration;
  double get playbackRate => _playbackRate;
  String? get errorMessage => _errorMessage;

  void _initAudioEngine() {
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      onStateChanged?.call();
    });

    _positionSubscription = _player.onPositionChanged.listen((pos) {
      _position = pos;
      onStateChanged?.call();
    });

    _durationSubscription = _player.onDurationChanged.listen((dur) {
      _duration = dur;
      onStateChanged?.call();
    });
  }

  /// Joue un fichier MP3 local en gérant les erreurs d'autofocus et de lecture.
  Future<void> playAsset(String assetPath) async {
    try {
      _errorMessage = null;
      _currentAsset = assetPath;
      await _player.stop();
      await _player.setPlaybackRate(_playbackRate);
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      _errorMessage = 'Fichier audio manquant';
      onStateChanged?.call();
      debugPrint('Erreur Moteur Audio: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('Erreur pause audio: $e');
    }
  }

  Future<void> resume() async {
    try {
      if (_currentAsset != null && _playerState == PlayerState.paused) {
        await _player.resume();
      } else if (_currentAsset != null) {
        await playAsset(_currentAsset!);
      }
    } catch (e) {
      debugPrint('Erreur reprise audio: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration newPosition) async {
    try {
      await _player.seek(newPosition);
    } catch (e) {
      debugPrint('Erreur seek audio: $e');
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    try {
      _playbackRate = rate;
      await _player.setPlaybackRate(rate);
      onStateChanged?.call();
    } catch (e) {
      debugPrint('Erreur de vitesse audio: $e');
    }
  }

  Future<void> restart() async {
    await seek(Duration.zero);
    if (!isPlaying) {
      await resume();
    }
  }

  void dispose() {
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _player.dispose();
  }
}
