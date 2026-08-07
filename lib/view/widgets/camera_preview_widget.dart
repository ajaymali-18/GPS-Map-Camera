import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../viewModel/camera_viewmodel.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraViewModel viewModel;
  final VoidCallback onZoomChanged;

  const CameraPreviewWidget({
    super.key,
    required this.viewModel,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onScaleStart: (details) {
          viewModel.baseZoom = viewModel.currentZoom;
        },
        onScaleUpdate: (details) async {
          final zoom = (viewModel.baseZoom * details.scale).clamp(
            viewModel.minZoom,
            viewModel.maxZoom,
          );

          await viewModel.setZoom(zoom);
          onZoomChanged();
        },
        child: CameraPreview(viewModel.controller!),
      ),
    );
  }
}
