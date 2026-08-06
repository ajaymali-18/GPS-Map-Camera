import 'package:flutter/material.dart';

class BottomNavDock extends StatelessWidget {
  final int activeIndex; // 0: Gallery, 1: Camera, 2: Location
  final VoidCallback? onGalleryTap;
  final VoidCallback? onShutterTap;
  final VoidCallback? onLocationTap;
  final Widget? galleryThumbnail;

  const BottomNavDock({
    super.key,
    required this.activeIndex,
    this.onGalleryTap,
    this.onShutterTap,
    this.onLocationTap,
    this.galleryThumbnail,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2563EB); // Bright blue from Stitch design
    const darkBgColor = Color(0xFF0F0F0F); // Deep dark background

    return Container(
      color: darkBgColor,
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left: Gallery Button
              GestureDetector(
                onTap: onGalleryTap,
                child: activeIndex == 0
                    ? Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.image,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                    : galleryThumbnail ??
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
              ),

              // Center: Shutter / Camera Ring Button
              GestureDetector(
                onTap: onShutterTap,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: activeIndex == 1 ? Colors.white24 : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),

              // Right: Location Button
              GestureDetector(
                onTap: onLocationTap,
                child: activeIndex == 2
                    ? Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
