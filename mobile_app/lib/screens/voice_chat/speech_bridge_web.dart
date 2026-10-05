// Speech Bridge Web implementation for browser (Chrome / Safari / Edge / Firefox)
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';

@JS('eval')
external JSAny? _jsEval(JSString script);

void bridgeCancelSpeech() {
  try {
    _jsEval('window.speechSynthesis && window.speechSynthesis.cancel()'.toJS);
  } catch (_) {}
}

void bridgeSpeak({
  required String text,
  required String activeSpeechLocale,
  required String activeLangCode,
}) {
  try {
    final safeText = text
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ');

    final js = '''
    (() => {
      if (!window.speechSynthesis) return;
      window.speechSynthesis.cancel();
      const u = new SpeechSynthesisUtterance("$safeText");
      u.lang = '$activeSpeechLocale';
      u.rate = 0.98;   // Natural human conversational tempo
      u.pitch = 1.05;  // Youthful, energetic Sherpa companion tone

      // Prioritize energetic youthful Sherpa boy voice
      const voices = window.speechSynthesis.getVoices();
      if (voices && voices.length > 0) {
        let preferred = null;
        if ('$activeLangCode' === 'hinglish' || '$activeLangCode' === 'en') {
          preferred = voices.find(v => v.name === 'Rishi') ||
                      voices.find(v => v.lang.startsWith('en-IN')) ||
                      voices.find(v => (v.name.includes('Male') || v.name.includes('Natural')) && v.lang.includes('IN'));
        } else if ('$activeLangCode' === 'hi') {
          preferred = voices.find(v => v.name === 'Rishi') ||
                      voices.find(v => v.name === 'Lekha') ||
                      voices.find(v => v.lang.startsWith('hi'));
        } else {
          preferred = voices.find(v => v.lang.startsWith('$activeSpeechLocale')) ||
                      voices.find(v => v.lang.includes('IN'));
        }
        if (!preferred) {
          preferred = voices.find(v => v.name === 'Rishi') ||
                      voices.find(v => v.lang.startsWith('$activeSpeechLocale')) ||
                      voices.find(v => v.lang.includes('IN'));
        }
        if (preferred) u.voice = preferred;
      }

      u.onend = () => { window._copilotSpeaking = false; };
      u.onerror = () => { window._copilotSpeaking = false; };
      window._copilotSpeaking = true;
      window.speechSynthesis.speak(u);
    })()
    ''';
    _jsEval(js.toJS);
  } catch (_) {}
}

void bridgeStartListening({
  required String activeSpeechLocale,
}) {
  try {
    final js = '''
    (() => {
      const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (!SpeechRecognition) {
        window._copilotSttUnsupported = true;
        return;
      }
      window._copilotVoiceText = '';
      window._copilotFinalTranscript = '';
      window._copilotIsListeningActive = true;
      window._copilotLastSpokenTime = 0;

      if (!window._copilotRecog) {
        window._copilotRecog = new SpeechRecognition();
      }
      window._copilotRecog.lang = '$activeSpeechLocale';
      window._copilotRecog.continuous = true;
      window._copilotRecog.interimResults = true;

      window._copilotRecog.onresult = (e) => {
        let interim = '';
        for (let i = e.resultIndex; i < e.results.length; i++) {
          if (e.results[i].isFinal) {
            window._copilotFinalTranscript += e.results[i][0].transcript + ' ';
          } else {
            interim += e.results[i][0].transcript;
          }
        }
        const fullText = (window._copilotFinalTranscript + interim).trim();
        if (fullText) {
          window._copilotVoiceText = fullText;
          window._copilotLastSpokenTime = Date.now();
        }
      };

      window._copilotRecog.onerror = (e) => {
        console.log("SpeechRecognition notice:", e.error);
      };

      window._copilotRecog.onend = () => {
        if (window._copilotIsListeningActive) {
          try {
            window._copilotRecog.start();
          } catch (_) {}
        }
      };

      try {
        window._copilotRecog.start();
      } catch (_) {}
    })()
    ''';
    _jsEval(js.toJS);
  } catch (_) {}
}

String bridgeGetSpeechText() {
  try {
    final textRes = _jsEval('(window._copilotVoiceText || "").toString()'.toJS);
    if (textRes != null) {
      return (textRes as JSString).toDart.trim();
    }
  } catch (_) {}
  return '';
}

void bridgeSetSpeechText(String text) {
  try {
    final safe = text.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    _jsEval('window._copilotVoiceText = "$safe"'.toJS);
  } catch (_) {}
}

String bridgeStopListening() {
  String result = '';
  try {
    const js = '''
    (() => {
      window._copilotIsListeningActive = false;
      if (window._copilotRecog) {
        try { window._copilotRecog.stop(); } catch(_) {}
      }
    })()
    ''';
    _jsEval(js.toJS);

    final textRes = _jsEval('(window._copilotVoiceText || "").toString()'.toJS);
    if (textRes != null) {
      final t = (textRes as JSString).toDart.trim();
      if (t.isNotEmpty) result = t;
    }
  } catch (_) {}
  return result;
}
