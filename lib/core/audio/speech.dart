import 'package:flutter_tts/flutter_tts.dart';

class Speech {
  Speech() : _tts = FlutterTts();

  final FlutterTts _tts;
  String? lastError;

  Future<void> speak(String text) async {
    lastError = null;
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.speak(text);
    } catch (error) {
      lastError = 'Voix indisponible sur cet appareil';
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
