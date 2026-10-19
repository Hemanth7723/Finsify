import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceRecognitionService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _available = false;
  ValueChanged<String>? _onResult;
  ValueChanged<bool>? _onListeningChanged;
  ValueChanged<String>? _onError;

  Future<bool> listen({
    required ValueChanged<String> onResult,
    required ValueChanged<bool> onListeningChanged,
    required ValueChanged<String> onError,
  }) async {
    _onResult = onResult;
    _onListeningChanged = onListeningChanged;
    _onError = onError;

    if (!_initialized) {
      _available = await _speech.initialize(
        onStatus: (status) => _onListeningChanged?.call(status == 'listening'),
        onError: (error) => _onError?.call(error.errorMsg),
      );
      _initialized = true;
    }
    if (!_available) return false;

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 20),
      ),
      onResult: (result) => _onResult?.call(result.recognizedWords),
    );
    return true;
  }

  Future<void> stop() async {
    await _speech.stop();
    _onListeningChanged?.call(false);
  }
}
