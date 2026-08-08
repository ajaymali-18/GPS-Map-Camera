import 'package:flutter/services.dart';

/// Service to trigger native camera shutter sound via MethodChannel.
class CameraShutterSound {
  static const MethodChannel _channel =
      MethodChannel('com.tachyonbyte.opengps/shutter_sound');

  /// Plays the camera shutter sound using native Android/iOS audio APIs.
  static Future<void> play() async {
    try {
      await _channel.invokeMethod('playShutterSound');
    } catch (_) {
      // Gracefully ignore on unsupported platforms or unexpected errors
    }
  }
}
