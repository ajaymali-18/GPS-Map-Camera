import 'dart:io';
import 'package:flutter/material.dart';

class CameraBottomControls extends StatelessWidget {
  final File? lastCapturedImage;
  final bool isCapturing;
  final VoidCallback onGalleryTap;
  final VoidCallback onShutterTap;
  final VoidCallback onLocationTap;

  const CameraBottomControls({
    super.key,
    required this.lastCapturedImage,
    required this.isCapturing,
    required this.onGalleryTap,
    required this.onShutterTap,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          color: const Color(0xFF0F0F0F),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Last Photo Thumbnail / Gallery Trigger
              GestureDetector(
                onTap: onGalleryTap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: ClipOval(
                    child: lastCapturedImage != null
                        ? Image.file(lastCapturedImage!, fit: BoxFit.cover)
                        : Container(
                            color: Colors.white12,
                            child: const Icon(
                              Icons.image_outlined,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                  ),
                ),
              ),

              // Center: Shutter Ring Button
              GestureDetector(
                onTap: isCapturing ? null : onShutterTap,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isCapturing ? Colors.grey : Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),

              // Right: Location Inspector Trigger
              GestureDetector(
                onTap: onLocationTap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0x33262626),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
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
