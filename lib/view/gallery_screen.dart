import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app2/view/image_preview.dart';
import 'package:my_app2/view/location_screen.dart';
import 'package:my_app2/view/widgets/bottom_nav_dock.dart';
import 'package:my_app2/view/widgets/top_app_header.dart';
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    loadImage();
  }

  Future<void> loadImage() async {
    final appDir = await getApplicationDocumentsDirectory();
    final galleryDir = Directory("${appDir.path}/Gallery");
    if (!mounted) return;

    if (galleryDir.existsSync()) {
      final files = galleryDir.listSync().whereType<File>().toList();
      files.sort(
        (newer, older) => older.lastModifiedSync().compareTo(
          newer.lastModifiedSync(),
        ),
      );

      setState(() {
        images = files;
      });
    } else {
      setState(() {
        images = [];
      });
    }
  }

  String _formatStitchDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final fileDate = DateTime(dt.year, dt.month, dt.day);

    if (fileDate == today) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:$minute $period';
    } else if (fileDate == yesterday) {
      return 'YEST';
    } else {
      const monthAbbrs = [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ];
      return '${monthAbbrs[dt.month - 1]} ${dt.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: TopAppHeader(
        title: 'Photo Gallery',
        onFlashPressed: () {
          Navigator.pop(context);
        },
        trailing: const SizedBox(width: 48),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: images.isEmpty
                  ? const Center(
                      child: Text(
                        "No Images Found",
                        style: TextStyle(fontSize: 18, color: Colors.white54),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final file = images[index];
                        final modTime = file.lastModifiedSync();

                        return GestureDetector(
                          onTap: () async {
                            final deleted = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImagePreviewScreen(image: file),
                              ),
                            );

                            if (deleted == true) {
                              loadImage();
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(file, fit: BoxFit.cover),

                                // Stitch Timestamp Dark Pill Badge
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _formatStitchDate(modTime),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Stitch Bottom Nav Dock (Gallery Active)
            BottomNavDock(
              activeIndex: 0,
              onGalleryTap: () {},
              onShutterTap: () => Navigator.pop(context),
              onLocationTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
