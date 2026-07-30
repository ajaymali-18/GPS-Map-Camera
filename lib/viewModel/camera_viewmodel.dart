import 'package:camera/camera.dart';

class CameraViewModel {
  // CameraController is a class provided by the Flutter camera package. An object of this class is responsible for controlling the camera.
  //  ? means the variable is nullable.
  CameraController? controller;

  Future<void> initilizeCamera() async {
    final cameras =
        await availableCameras(); //available camera  means front camera & back camera

    controller = CameraController(cameras.first, ResolutionPreset.high);

    await controller!.initialize();
  }

  void dispose() {
    controller?.dispose();
  }
}
