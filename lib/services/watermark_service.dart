import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
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
  }) async {
    final source = await File(image.path).readAsBytes();
    final decoded = img.decodeImage(source);
    if (decoded == null) {
      throw StateError('The captured photo could not be decoded.');
    }

    final photo = img.bakeOrientation(decoded);
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

    return Uint8List.fromList(img.encodeJpg(photo, quality: 95));
  }
}
