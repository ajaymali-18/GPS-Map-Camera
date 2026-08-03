import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:my_app2/view/gallery_screen.dart';
import '../viewModel/camera_viewmodel.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraViewModel viewModel = CameraViewModel();
  late XFile? imageFile;
  @override
  void initState() {
    super.initState();

    viewModel.initilizeCamera().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (viewModel.controller == null ||
        !viewModel.controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // backgroundColor: Colors.black,
      appBar: AppBar(),

      body: Stack(
        children: [
          CameraPreview(viewModel.controller!),

          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Gallery
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      elevation: 0,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GalleryScreen(),
                          ),
                        );
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF3C096C),
                      child: const Icon(Icons.image),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Gallery",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),

                // Camera
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      elevation: 0,

                      onPressed: () async {
                        final XFile? image = await viewModel.capturePhoto();

                        if (image != null) {
                          await viewModel.saveCapturedImage(image.path);

                          setState(() {
                            imageFile = image;
                          });

                          // print("Image captured: ${image.path}");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Photo Saved in Device"),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },

                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF3C096C),
                      shape: const CircleBorder(
                        side: BorderSide(color: Colors.white),
                      ),
                      child: const Icon(Icons.camera_alt),
                    ),
                    const SizedBox(height: 8),
                    const Text("Camera", style: TextStyle(color: Colors.white)),
                  ],
                ),

                // Location
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      elevation: 0,
                      onPressed: () {},
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF3C096C),
                      child: const Icon(Icons.location_on),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Location",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
