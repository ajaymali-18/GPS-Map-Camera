import 'dart:typed_data';

import 'package:camera/camera.dart';
import '../services/gallery_service.dart';

class CameraViewModel {
  // Flash & Zoom
  double baseZoom = 1.0;
  double minZoom = 1.0;
  double maxZoom = 1.0;
  double currentZoom = 1.0;

  // touch screen zoom variable

  FlashMode flashMode = FlashMode.off;

  final GalleryService galleryService = GalleryService();

  Future<void> saveImageBytes(Uint8List bytes) async {
    await galleryService.saveImageBytes(bytes);
  }

  CameraController? controller;

  Future<void> initializeCamera() async {
    // Retrying after a failed initialization must not leave the old native
    // camera instance open.
    await controller?.dispose();
    controller = null;

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No camera is available on this device.');
    }

    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final newController = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await newController.initialize();

      minZoom = await newController.getMinZoomLevel();
      maxZoom = await newController.getMaxZoomLevel();
      currentZoom = minZoom;

      controller = newController;
    } catch (_) {
      await newController.dispose();
      rethrow;
    }
  }

  // flash
  Future<void> toggleFlash() async {
    if (controller == null || !controller!.value.isInitialized) return;

    if (flashMode == FlashMode.off) {
      flashMode = FlashMode.always;
    } else if (flashMode == FlashMode.always) {
      flashMode = FlashMode.torch;
    } else {
      flashMode = FlashMode.off;
    }

    await controller!.setFlashMode(flashMode);
  }

  // zoom
  Future<void> setZoom(double zoom) async {
    if (controller == null || !controller!.value.isInitialized) return;
    final targetZoom = zoom.clamp(minZoom, maxZoom);
    await controller!.setZoomLevel(targetZoom);
    currentZoom = targetZoom;
  }

  void dispose() {
    controller?.dispose();
  }

  Future<XFile?> capturePhoto() async {
    if (controller == null || !controller!.value.isInitialized) {
      return null;
    }

    try {
      return await controller!.takePicture();
    } catch (_) {
      return null;
    }
  }
}
