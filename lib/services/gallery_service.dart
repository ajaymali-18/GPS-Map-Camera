import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';

class GalleryService {
  Future<void> saveImageBytes(Uint8List bytes) async {
    final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      final appDirectory = await getApplicationDocumentsDirectory();
      final galleryDirectory = Directory(
        path.join(appDirectory.path, 'Gallery'),
      );
      await galleryDirectory.create(recursive: true);
      await File(
        path.join(galleryDirectory.path, fileName),
      ).writeAsBytes(bytes);

      final result = await SaverGallery.saveImage(
        bytes,
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
