import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart';
import 'package:my_app2/utils/formatters.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';

class GalleryService {
  Future<File?> getLastCapturedImage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final galleryDir = Directory("${appDir.path}/Gallery");
      if (galleryDir.existsSync()) {
        final files = galleryDir.listSync().whereType<File>().toList();
        if (files.isNotEmpty) {
          files.sort(
            (newer, older) => older.lastModifiedSync().compareTo(
              newer.lastModifiedSync(),
            ),
          );
          return files.first;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveImageBytes(Uint8List bytes, {Position? position}) async {
    final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      final appDirectory = await getApplicationDocumentsDirectory();
      final galleryDirectory = Directory(
        path.join(appDirectory.path, 'Gallery'),
      );
      await galleryDirectory.create(recursive: true);
      final filePath = path.join(galleryDirectory.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (position != null) {
        try {
          final exif = await Exif.fromPath(filePath);
          final lat = position.latitude;
          final lng = position.longitude;
          final nowString = AppFormatters.formatExifDate(DateTime.now());

          final attributes = <String, String>{
            'GPSLatitude': lat.toString(),
            'GPSLongitude': lng.toString(),
            'GPSLatitudeRef': lat >= 0 ? 'N' : 'S',
            'GPSLongitudeRef': lng >= 0 ? 'E' : 'W',
            'DateTimeOriginal': nowString,
            'DateTimeDigitized': nowString,
            'DateTime': nowString,
          };

          if (position.altitude != 0.0) {
            attributes['GPSAltitude'] = position.altitude.abs().toString();
            attributes['GPSAltitudeRef'] = position.altitude >= 0 ? '0' : '1';
          }

          await exif.writeAttributes(attributes);
          await exif.close();

          final verifyExif = await Exif.fromPath(filePath);
          final readAttributes = await verifyExif.getAttributes();
          final readLatLong = await verifyExif.getLatLong();
          await verifyExif.close();
          debugPrint("Verified EXIF Attributes: $readAttributes, LatLong: $readLatLong");
        } catch (exifError) {
          debugPrint("EXIF Write Error: $exifError");
        }
      }

      final result = await SaverGallery.saveFile(
        filePath: filePath,
        fileName: fileName,
        albumPath: 'GPS Camera',
        skipIfExists: false,
      );

      if (!result.isSuccess) {
        throw StateError(
          result.errorMessage ?? 'The device gallery rejected the image.',
        );
      }

      debugPrint("Save Result: $result");
    } catch (e) {
      debugPrint("Save Error: $e");
      rethrow;
    }
  }
}
