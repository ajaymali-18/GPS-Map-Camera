import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:saver_gallery/saver_gallery.dart';

class GalleryService {
  Future<void> saveImage(String imagePath) async {
    debugPrint("GalleryService called");
    final bytes = await File(imagePath).readAsBytes();

    final result = await SaverGallery.saveImage(
      bytes,
      fileName: "IMG_${DateTime.now().millisecondsSinceEpoch}",
      skipIfExists: false,
    );
    debugPrint("Save Result: $result");
  }
}
