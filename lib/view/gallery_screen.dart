import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app2/models/photo_model.dart';
import 'package:my_app2/services/gallery_service.dart';
import 'package:my_app2/utils/formatters.dart';
import 'package:my_app2/view/image_preview.dart';
import 'package:my_app2/view/location_screen.dart';
import 'package:my_app2/view/widgets/bottom_nav_dock.dart';
import 'package:my_app2/view/widgets/top_app_header.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final GalleryService _galleryService = GalleryService();
  List<PhotoModel> images = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    loadImage();
  }

  Future<void> loadImage() async {
    final photos = await _galleryService.getGalleryPhotos();
    if (!mounted) return;

    setState(() {
      images = photos;
    });
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
                        final photo = images[index];
                        final file = photo.file;
                        final modTime = photo.modifiedAt;

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
                                      AppFormatters.formatStitchDate(modTime),
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
