import 'dart:typed_data';

import 'package:camera/camera.dart';
import '../services/gallery_service.dart';

class CameraViewModel {
  final GalleryService galleryService = GalleryService();

  Future<void> saveCapturedImage(String imagePath) async {
    await galleryService.saveImage(imagePath);
  }

  Future<void> saveImageBytes(Uint8List bytes) async {
    await galleryService.saveImageBytes(bytes);
  }

  // CameraController is a class provided by the Flutter camera package. An object of this class is responsible for controlling the camera.
  //  ? means the variable is nullable.
  CameraController? controller;



  Future<void> initilizeCamera() async {
    final cameras =
        await availableCameras(); //available camera  means front camera & back camera

    controller = CameraController(cameras.first, ResolutionPreset.high);

    await controller!.initialize(); //controller is not null now
  }

  // Take Picture

  void dispose() {
    controller?.dispose();
  }

  Future<XFile?> capturePhoto() async {
    if (controller == null || !controller!.value.isInitialized) {
      return null;
    }

    try {
      return await controller!.takePicture();
    } catch (e) {
      print(e);
      return null;
    }
  }
}
