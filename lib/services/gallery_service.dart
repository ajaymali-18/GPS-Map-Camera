import 'dart:io';
// import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';

class GalleryService {
  Future<void> saveImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final file = File(imagePath); //file object

    final result = await SaverGallery.saveImage(
      bytes,
      fileName: "IMG_${DateTime.now().millisecondsSinceEpoch}",
      skipIfExists: false,
    );

    final appDir = await getApplicationDocumentsDirectory();
    final galleryDir = Directory("${appDir.path}/Gallery");

    if (!galleryDir.existsSync()) {
      galleryDir.createSync(recursive: true);
    }

    final fileName = p.basename(imagePath);

    await file.copy("${galleryDir.path}/$fileName");
  }
}
