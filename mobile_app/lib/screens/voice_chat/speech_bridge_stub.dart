// Speech Bridge implementation for native desktop / macOS / mobile platforms
import 'dart:convert';
import 'dart:io' show Process;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';

String _desktopSpeechText = '';
bool _desktopIsListening = false;

void bridgeCancelSpeech() {
  try {
    http.post(Uri.parse(ApiConfig.stopSpeakUrl)).catchError((_) => http.Response('', 500));
  } catch (_) {}
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    try {
      Process.run('pkill', ['-f', 'afplay']);
      Process.run('pkill', ['-f', 'say']);
    } catch (_) {}
  }
}

void bridgeSpeak({
  required String text,
  required String activeSpeechLocale,
  required String activeLangCode,
}) async {
  bool playedViaBackend = false;
  try {
    final uri = Uri.parse(ApiConfig.speakUrl);
    final payload = jsonEncode({
      'text': text,
      'language': activeLangCode,
      'play_on_host': true,
    });
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    ).timeout(const Duration(seconds: 4));
    if (res.statusCode == 200) {
      playedViaBackend = true;
    }
  } catch (e) {
    debugPrint('Backend speak error: $e');
  }

  // macOS Native fallback if backend didn't play audio
  if (!playedViaBackend && !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    try {
      final voice = (activeLangCode == 'en') ? 'Aman' : 'Lekha';
      Process.run('say', ['-v', voice, text]);
    } catch (e) {
      debugPrint('macOS say fallback error: $e');
    }
  }
}

void bridgeStartListening({
  required String activeSpeechLocale,
}) {
  _desktopIsListening = true;
  _desktopSpeechText = '';
}

String bridgeGetSpeechText() => _desktopSpeechText;

void bridgeSetSpeechText(String text) {
  _desktopSpeechText = text;
}

String bridgeStopListening() {
  _desktopIsListening = false;
  return _desktopSpeechText;
}

bool bridgeIsListening() => _desktopIsListening;
