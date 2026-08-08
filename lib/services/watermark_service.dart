import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import '../utils/formatters.dart';

class WatermarkService {
  Future<Uint8List> createStampedPhoto(
    XFile image,
    img.Image? mapSnapshot, {
    Placemark? placemark,
    Position? position,
    double? previewWidth,
    double? previewHeight,
    bool isFrontCamera = false,
  }) async {
    final swWMTotal = Stopwatch()..start();

    // 1. Prepare plain data strings on main isolate before crossing to background isolate
    final swPrep = Stopwatch()..start();
    final imagePath = image.path;
    final timestamp = DateTime.now();
    final locationCityStateCountry =
        AppFormatters.formatLocationCityStateCountry(placemark, position);
    final fullAddress = AppFormatters.formatFullAddress(placemark, position);
    final coords = AppFormatters.formatCoordinates(position);
    final dateTimeStr = AppFormatters.formatCurrentDateTime(timestamp);

    final unwrappedLines = <String>[
      locationCityStateCountry,
      fullAddress,
      coords,
      dateTimeStr,
    ];
    swPrep.stop();
    debugPrint('⏱️ image preparation on main isolate: ${swPrep.elapsedMilliseconds} ms');

    // 2. Offload CPU-heavy image processing to background Dart Isolate
    debugPrint('⚡ Offloading CPU-heavy watermark processing to Background Isolate...');
    final swIsoTotal = Stopwatch()..start();

    final resultBytes = await Isolate.run(() {
      final swIsoInner = Stopwatch()..start();

      final swRead = Stopwatch()..start();
      final source = File(imagePath).readAsBytesSync();
      swRead.stop();

      final swDecode = Stopwatch()..start();
      final decoded = img.decodeImage(source);
      swDecode.stop();
      if (decoded == null) {
        throw StateError('The captured photo could not be decoded.');
      }

      final swBake = Stopwatch()..start();
      var photo = img.bakeOrientation(decoded);
      swBake.stop();

      // 3. Match camera preview horizontal mirroring for front camera
      if (isFrontCamera) {
        photo = img.flipHorizontal(photo);
      }

      // 4. Crop image to match camera preview aspect ratio 1:1
      if (previewWidth != null &&
          previewHeight != null &&
          previewWidth > 0 &&
          previewHeight > 0) {
        final targetRatio = previewWidth / previewHeight;
        final currentRatio = photo.width / photo.height;

        if ((currentRatio - targetRatio).abs() > 0.001) {
          int cropX = 0;
          int cropY = 0;
          int cropW = photo.width;
          int cropH = photo.height;

          if (currentRatio > targetRatio) {
            // Photo is wider than preview aspect ratio -> crop horizontal sides
            cropH = photo.height;
            cropW = (photo.height * targetRatio).round().clamp(1, photo.width);
            cropX = ((photo.width - cropW) / 2).round().clamp(0, photo.width - 1);
            cropY = 0;
          } else {
            // Photo is taller than preview aspect ratio -> crop vertical sides
            cropW = photo.width;
            cropH = (photo.width / targetRatio).round().clamp(1, photo.height);
            cropX = 0;
            cropY = ((photo.height - cropH) / 2).round().clamp(0, photo.height - 1);
          }

          photo = img.copyCrop(
            photo,
            x: cropX,
            y: cropY,
            width: cropW,
            height: cropH,
          );
        }
      }

      final swRender = Stopwatch()..start();
      const horizontalPadding = 36;
      const lineHeight = 32;
      const verticalPadding = 20;
      final mapSize = mapSnapshot == null
          ? 0
          : (photo.width * 0.22).round().clamp(160, 280).toInt();
      final textStart = horizontalPadding + mapSize + (mapSize == 0 ? 0 : 24);
      final maximumCharacters =
          ((photo.width - textStart - horizontalPadding) ~/ 14)
              .clamp(24, 72)
              .toInt();
      final lines = unwrappedLines
          .expand((line) => AppFormatters.wrapText(line, maximumCharacters))
          .toList();
      final panelHeight = math.max(
        verticalPadding * 2 + lineHeight * lines.length,
        mapSize + verticalPadding * 2,
      );
      final top = (photo.height - panelHeight).clamp(0, photo.height - 1).toInt();
      img.fillRect(
        photo,
        x1: 0,
        y1: top,
        x2: photo.width - 1,
        y2: photo.height - 1,
        color: img.ColorRgba8(0, 0, 0, 185),
      );

      if (mapSnapshot != null) {
        img.compositeImage(
          photo,
          img.copyResize(mapSnapshot, width: mapSize, height: mapSize),
          dstX: horizontalPadding,
          dstY: top + (panelHeight - mapSize) ~/ 2,
        );
        img.drawRect(
          photo,
          x1: horizontalPadding,
          y1: top + (panelHeight - mapSize) ~/ 2,
          x2: horizontalPadding + mapSize - 1,
          y2: top + (panelHeight - mapSize) ~/ 2 + mapSize - 1,
          color: img.ColorRgb8(255, 255, 255),
        );
      }

      for (var index = 0; index < lines.length; index++) {
        img.drawString(
          photo,
          lines[index],
          font: img.arial24,
          x: textStart,
          y: top + verticalPadding + index * lineHeight,
          color: img.ColorRgb8(255, 255, 255),
        );
      }
      swRender.stop();

      final swEncode = Stopwatch()..start();
      final encodedBytes = Uint8List.fromList(img.encodeJpg(photo, quality: 95));
      swEncode.stop();
      swIsoInner.stop();

      debugPrint('   │ ⏱️ [BACKGROUND ISOLATE] file read: ${swRead.elapsedMilliseconds} ms (${(source.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB)');
      debugPrint('   │ ⏱️ [BACKGROUND ISOLATE] image decode: ${swDecode.elapsedMilliseconds} ms (${decoded.width}x${decoded.height})');
      debugPrint('   │ ⏱️ [BACKGROUND ISOLATE] bake orientation: ${swBake.elapsedMilliseconds} ms');
      debugPrint('   │ ⏱️ [BACKGROUND ISOLATE] watermark rendering: ${swRender.elapsedMilliseconds} ms');
      debugPrint('   │ ⏱️ [BACKGROUND ISOLATE] JPEG encoding: ${swEncode.elapsedMilliseconds} ms (${(encodedBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB)');
      debugPrint('   │ ⏱️ [BACKGROUND ISOLATE] total processing inside isolate: ${swIsoInner.elapsedMilliseconds} ms');

      return encodedBytes;
    });

    swIsoTotal.stop();
    debugPrint('⏱️ isolate total processing (wall time): ${swIsoTotal.elapsedMilliseconds} ms [UI THREAD WAS FREE & UNBLOCKED]');

    swWMTotal.stop();
    debugPrint('⏱️ total watermark service time: ${swWMTotal.elapsedMilliseconds} ms');
    return resultBytes;
  }
}
