import 'package:camera/camera.dart';

/// Represents camera settings and configuration parameters.
class CameraModel {
  double baseZoom;
  double minZoom;
  double maxZoom;
  double currentZoom;
  FlashMode flashMode;

  CameraModel({
    this.baseZoom = 1.0,
    this.minZoom = 1.0,
    this.maxZoom = 1.0,
    this.currentZoom = 1.0,
    this.flashMode = FlashMode.off,
  });
}
