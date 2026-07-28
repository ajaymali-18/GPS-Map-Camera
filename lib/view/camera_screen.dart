import 'package:flutter/material.dart';
import 'package:my_app2/viewModel/capture_photo.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),

        body: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                // capture button
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),

                  child: FloatingActionButton(
                    elevation: 0,

                    onPressed: () {
                      CapturePhoto.capturePhoto();
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3c096c),
                    child: Icon(Icons.image),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                // capture button
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: FloatingActionButton(
                    elevation: 0,

                    onPressed: () {
                      CapturePhoto.capturePhoto();
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3c096c),
                    shape: const CircleBorder(
                      side: BorderSide(
                        color: Color.fromARGB(255, 245, 246, 247),
                      ),
                    ),
                    child: Icon(Icons.camera),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                // capture button
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: FloatingActionButton(
                    elevation: 0,

                    onPressed: () {
                      CapturePhoto.capturePhoto();
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3c096c),

                    child: Icon(Icons.location_on),
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
