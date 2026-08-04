import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_app2/view/image_preview.dart';
import 'package:path_provider/path_provider.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
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

      setState(() {
        images = files;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gallery"), centerTitle: true),
      body: SafeArea(
        child: images.isEmpty
            ? const Center(
                child: Text("No Images Found", style: TextStyle(fontSize: 18)),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 0.75,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      final deleted = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ImagePreviewScreen(image: images[index]),
                        ),
                      );

                      if (deleted == true) {
                        loadImage();
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(images[index], fit: BoxFit.cover),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
