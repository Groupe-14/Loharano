import 'package:flutter_tts/flutter_tts.dart';

class Speech {
  final _tts = FlutterTts();

  Future<void> speak(String text) async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.speak(text);
    } catch (_) {}
  }
}
