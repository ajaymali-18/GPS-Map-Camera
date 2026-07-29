import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:my_app2/viewModel/camera_viewmodel.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();

    _controller = CameraController(cameras.first, ResolutionPreset.high);

    await _controller!.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      body: Stack(
        children: [
          CameraPreview(
            _controller!,
          ), //CameraPreview is a widget .Its job is to display the live camera feed on the screen.

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),

              // Column-1
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    elevation: 0,
                    onPressed: () {
                      // CapturePhoto.capturePhoto();
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3C096C),
                    child: const Icon(Icons.image),
                  ),
                  const SizedBox(height: 8),
                  const Text("Gallery"),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              // Column-2 (Camera)
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    elevation: 0,
                    onPressed: () {
                      // CapturePhoto.capturePhoto();
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3C096C),
                    shape: const CircleBorder(
                      side: BorderSide(
                        color: Color.fromARGB(255, 245, 246, 247),
                      ),
                    ),
                    child: const Icon(Icons.camera_alt),
                  ),
                  const SizedBox(height: 8),
                  const Text("Camera"),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              // Column -3 Location
              child: Column(
                // mainAxisSize: MainAxisSize.min,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    elevation: 0,
                    onPressed: () {
                      // CapturePhoto.capturePhoto();
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3C096C),
                    child: const Icon(Icons.location_on),
                  ),
                  const SizedBox(height: 8),
                  const Text("Location"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
