import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart';
import 'package:my_app2/models/photo_model.dart';
import 'package:my_app2/utils/formatters.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';

class GalleryService {
  Future<PhotoModel?> getLastCapturedImage() async {
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
          return PhotoModel(file: files.first);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<PhotoModel>> getGalleryPhotos() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final galleryDir = Directory("${appDir.path}/Gallery");
      if (galleryDir.existsSync()) {
        final files = galleryDir.listSync().whereType<File>().toList();
        files.sort(
          (newer, older) => older.lastModifiedSync().compareTo(
            newer.lastModifiedSync(),
          ),
        );
        return files.map((file) => PhotoModel(file: file)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveImageBytes(Uint8List bytes, {Position? position}) async {
    final swGalTotal = Stopwatch()..start();
    final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      final appDirectory = await getApplicationDocumentsDirectory();
      final galleryDirectory = Directory(
        path.join(appDirectory.path, 'Gallery'),
      );
      await galleryDirectory.create(recursive: true);
      final filePath = path.join(galleryDirectory.path, fileName);
      final file = File(filePath);

      final swWrite = Stopwatch()..start();
      await file.writeAsBytes(bytes);
      swWrite.stop();
      debugPrint('⏱️ local file write: ${swWrite.elapsedMilliseconds} ms (${(bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB)');

      if (position != null) {
        final swExif = Stopwatch()..start();
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
        swExif.stop();
        debugPrint('⏱️ EXIF write & verify: ${swExif.elapsedMilliseconds} ms');
      }

      final swSaver = Stopwatch()..start();
      final result = await SaverGallery.saveFile(
        filePath: filePath,
        fileName: fileName,
        albumPath: 'GPS Camera',
        skipIfExists: false,
      );
      swSaver.stop();
      debugPrint('⏱️ gallery save (SaverGallery): ${swSaver.elapsedMilliseconds} ms');

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
    swGalTotal.stop();
    debugPrint('⏱️ total gallery service time: ${swGalTotal.elapsedMilliseconds} ms');
  }
}
