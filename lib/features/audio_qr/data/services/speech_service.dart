import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  SpeechService() : _tts = FlutterTts();

  final FlutterTts _tts;

  Future<void> speak(String text, {String language = 'fr-FR'}) async {
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  Future<void> dispose() => _tts.stop();
}
