import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraErrorView extends StatelessWidget {
  final String cameraError;
  final bool cameraPermissionDenied;
  final bool cameraPermissionPermanentlyDenied;
  final VoidCallback onRetryPressed;

  const CameraErrorView({
    super.key,
    required this.cameraError,
    required this.cameraPermissionDenied,
    required this.cameraPermissionPermanentlyDenied,
    required this.onRetryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white70),
              const SizedBox(height: 12),
              Text(
                cameraError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: cameraPermissionPermanentlyDenied
                    ? openAppSettings
                    : onRetryPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  cameraPermissionPermanentlyDenied
                      ? 'Open Settings'
                      : cameraPermissionDenied
                      ? 'Allow camera'
                      : 'Retry camera',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
