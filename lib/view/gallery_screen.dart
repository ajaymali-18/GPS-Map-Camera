import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() {
    return _GalleryScreenState();
  }
}

class _GalleryScreenState extends State<GalleryScreen> {
  // File? image; (for single image)
  List<File> images = [];

  @override
  void initState() {
    super.initState();
    loadImage();
  }

  Future<void> loadImage() async {
    final appDir = await getApplicationDocumentsDirectory();
    final galleryDir = Directory("${appDir.path}/Gallery");

    if (galleryDir.existsSync()) {
      final files = galleryDir.listSync().whereType<File>().toList();
      // listSync()= will return all folder and files
      if (files.isNotEmpty) {
        setState(() {
          images = files;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gallery")),
      body: Center(
        child: images.isEmpty
            ? const Text("No Images Found")
            : Image.file(images.first, fit: BoxFit.contain),
      ),
    );
  }
}
