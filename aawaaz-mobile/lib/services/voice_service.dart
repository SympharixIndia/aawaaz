import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper over text-to-speech (prompts) and speech-to-text (query capture).
///
/// Kept deliberately small so the UI drives the flow and this stays swappable
/// (e.g. a cloud Indic speech provider later) without touching the screens.
class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();
  bool _sttInitialized = false;

  /// Speaks [text] in [languageCode] and completes when playback finishes.
  Future<void> speak(String text, String languageCode) async {
    await _tts.setLanguage(languageCode);
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();

  /// Initializes STT once; returns false if speech recognition is unavailable.
  Future<bool> initStt() async {
    if (_sttInitialized) return true;
    _sttInitialized = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _sttInitialized;
  }

  bool get isListening => _speech.isListening;

  /// Listens in [languageCode], streaming partial text via [onResult]; the
  /// final result has `isFinal == true`. [onDone] fires when listening stops.
  Future<void> listen({
    required String languageCode,
    required void Function(String text, bool isFinal) onResult,
    void Function()? onDone,
  }) async {
    if (!await initStt()) return;
    await _speech.listen(
      onResult: (r) {
        onResult(r.recognizedWords, r.finalResult);
        if (r.finalResult) onDone?.call();
      },
      listenOptions: SpeechListenOptions(
        localeId: languageCode,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() => _speech.stop();

  void dispose() {
    _tts.stop();
    _speech.cancel();
  }
}
