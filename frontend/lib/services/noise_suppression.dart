import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

typedef RNNoiseCreateNative = Pointer<Void> Function(Pointer<Float>);
typedef RNNoiseCreate = Pointer<Void> Function(Pointer<Float>);

typedef RNNoiseProcessFrameNative = Float Function(
    Pointer<Void>, Pointer<Float>, Pointer<Float>, Int);
typedef RNNoiseProcessFrame = double Function(
    Pointer<Void>, Pointer<Float>, Pointer<Float>, int);

typedef RNNoiseDestroyNative = Void Function(Pointer<Void>);
typedef RNNoiseDestroy = void Function(Pointer<Void>);

class RNNoiseProcessor {
  static const int _frameSize = 480;
  static const int _sampleRate = 48000;

  DynamicLibrary? _lib;
  Pointer<Void>? _model;
  bool _initialized = false;

  late final RNNoiseCreate _rnnoiseCreate;
  late final RNNoiseProcessFrame _rnnoiseProcessFrame;
  late final RNNoiseDestroy _rnnoiseDestroy;

  bool get isInitialized => _initialized;

  bool initialize() {
    try {
      _lib = _loadLibrary();
      _rnnoiseCreate = _lib!
          .lookupFunction<RNNoiseCreateNative, RNNoiseCreate>('rnnoise_create');
      _rnnoiseProcessFrame = _lib!
          .lookupFunction<RNNoiseProcessFrameNative, RNNoiseProcessFrame>(
              'rnnoise_process_frame');
      _rnnoiseDestroy = _lib!
          .lookupFunction<RNNoiseDestroyNative, RNNoiseDestroy>(
              'rnnoise_destroy');

      final modelPtr = _rnnoiseCreate(nullptr);
      if (modelPtr == nullptr) return false;

      _model = modelPtr;
      _initialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('librnnoise.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('rnnoise.dll');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('librnnoise.so');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('librnnoise.dylib');
    }
    throw UnsupportedError('Platform not supported');
  }

  Float32List processFrame(Float32List input) {
    if (!_initialized || _model == null) return input;
    if (input.length != _frameSize) return input;

    final inputPtr = calloc<Float>(_frameSize);
    final outputPtr = calloc<Float>(_frameSize);

    try {
      for (int i = 0; i < _frameSize; i++) {
        inputPtr[i] = input[i];
      }

      _rnnoiseProcessFrame(_model!, outputPtr, inputPtr, 0);

      final output = Float32List(_frameSize);
      for (int i = 0; i < _frameSize; i++) {
        output[i] = outputPtr[i];
      }
      return output;
    } finally {
      calloc.free(inputPtr);
      calloc.free(outputPtr);
    }
  }

  Int16List processFrameInt16(Int16List input) {
    if (!_initialized || _model == null) return input;
    if (input.length != _frameSize) return input;

    final floatInput = Float32List(_frameSize);
    for (int i = 0; i < _frameSize; i++) {
      floatInput[i] = input[i].toDouble() / 32768.0;
    }

    final floatOutput = processFrame(floatInput);

    final output = Int16List(_frameSize);
    for (int i = 0; i < _frameSize; i++) {
      final sample = (floatOutput[i] * 32768.0).clamp(-32768.0, 32767.0);
      output[i] = sample.toInt();
    }
    return output;
  }

  void dispose() {
    if (_model != null) {
      _rnnoiseDestroy(_model!);
      _model = null;
    }
    _initialized = false;
  }
}

final calloc = Arena();
