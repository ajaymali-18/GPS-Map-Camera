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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Gallery")),
        body: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Number of columns
            mainAxisSpacing: 5.0,
            crossAxisSpacing: 5.0,
            childAspectRatio: 0.75, // Adjusts tile shape
          ),

          itemCount: images.length,
          itemBuilder: (context, index) {
            return Image.file(images[index], fit: BoxFit.cover);
          },
        ),
      ),
    );
  }
}
