import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> playLoudAlarm({
    String message =
        'Perhatian! Ada permintaan barang baru dari Purchasing. Segera buka aplikasi dan ajukan penawaran sekarang!',
  }) async {
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      // Set completion handler BEFORE speak() so it fires correctly.
      _tts.setCompletionHandler(() {
        _isPlaying = false;
      });

      // Try Indonesian; fall back to English if the language pack is absent.
      final languages = await _tts.getLanguages as List?;
      final hasIndonesian = languages?.any(
              (l) => l.toString().toLowerCase().startsWith('id')) ??
          false;
      await _tts.setLanguage(hasIndonesian ? 'id-ID' : 'en-US');

      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.1);
      await _tts.speak(message);
    } catch (e) {
      debugPrint('AlarmService error: $e');
      _isPlaying = false;
    }
  }

  Future<void> stopAlarm() async {
    await _tts.stop();
    _isPlaying = false;
  }
}
