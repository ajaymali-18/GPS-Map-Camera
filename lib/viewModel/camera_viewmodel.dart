import 'dart:typed_data';

import 'package:camera/camera.dart';
import '../services/gallery_service.dart';

class CameraViewModel {
  final GalleryService galleryService = GalleryService();

  Future<void> saveImageBytes(Uint8List bytes) async {
    await galleryService.saveImageBytes(bytes);
  }

  CameraController? controller;

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No camera is available on this device.');
    }

    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller!.initialize();
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
