// Speech Bridge Stub for non-web platforms (Android, iOS, macOS, Desktop, Tests)

void bridgeCancelSpeech() {}

void bridgeSpeak({
  required String text,
  required String activeSpeechLocale,
  required String activeLangCode,
}) {}

void bridgeStartListening({
  required String activeSpeechLocale,
}) {}

String bridgeGetSpeechText() => '';

String bridgeStopListening() => '';
