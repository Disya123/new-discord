import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class RNNoiseProcessor {
  bool _initialized = false;

  bool get isInitialized => _initialized;

  bool initialize() {
    if (kIsWeb) {
      // On web, noise suppression is handled by WebRTC's built-in
      // noiseSuppression constraint in getUserMedia
      _initialized = false;
      return false;
    }
    // On native platforms, load RNNoise via FFI
    // Requires native library to be bundled with the app
    _initialized = false;
    return false;
  }

  Float32List processFrame(Float32List input) => input;

  Int16List processFrameInt16(Int16List input) => input;

  void dispose() {
    _initialized = false;
  }
}
