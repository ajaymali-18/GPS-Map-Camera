import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_app2/models/model.dart';
import 'package:my_app2/services/gallery_service.dart';
import 'package:my_app2/services/location_service.dart';
import 'package:my_app2/services/map_tile_service.dart';
import 'package:my_app2/services/watermark_service.dart';
import 'package:my_app2/utils/formatters.dart';
import 'package:my_app2/view/gallery_screen.dart';
import 'package:my_app2/view/location_screen.dart';
import 'package:my_app2/view/widgets/camera_bottom_controls.dart';
import 'package:my_app2/view/widgets/camera_error_view.dart';
import 'package:my_app2/view/widgets/camera_preview_widget.dart';
import 'package:my_app2/view/widgets/location_overlay_card.dart';
import 'package:my_app2/view/widgets/top_app_header.dart';
import 'package:my_app2/view/widgets/zoom_pill_switcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../viewModel/camera_viewmodel.dart';

import 'package:my_app2/services/camera_shutter_sound.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final GalleryService galleryService = GalleryService();
  final LocationService locationService = LocationService();
  final MapTileService mapTileService = MapTileService();
  final WatermarkService watermarkService = WatermarkService();
  final CameraViewModel viewModel = CameraViewModel();

  // Domain Models
  final LocationModel locationModel = LocationModel();
  PhotoModel? _lastCapturedPhoto;

  Position? get position => locationModel.position;
  set position(Position? val) => locationModel.position = val;

  Placemark? get placemark => locationModel.placemark;
  set placemark(Placemark? val) => locationModel.placemark = val;

  File? get _lastCapturedImage => _lastCapturedPhoto?.file;

  String? _cameraError;
  String? _locationError;
  bool _isCapturing = false;
  bool _showShutterFlash = false;
  bool _isInitializingCamera = false;
  bool _cameraPermissionDenied = false;
  bool _cameraPermissionPermanentlyDenied = false;
  bool _isLocationServiceDisabled = false;

  void _triggerShutterFlash() {
    if (!mounted) return;
    setState(() {
      _showShutterFlash = true;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _showShutterFlash = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
    _loadLastImage();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadLocation();
      _loadLastImage();
    }
  }

  Future<void> _loadLastImage() async {
    final photo = await galleryService.getLastCapturedImage();
    if (mounted) {
      setState(() {
        _lastCapturedPhoto = photo;
      });
    }
  }

  Future<void> _startCamera() async {
    if (_isInitializingCamera) return;
    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
      _cameraPermissionDenied = false;
      _cameraPermissionPermanentlyDenied = false;
    });

    try {
      var cameraPermission = await Permission.camera.status;
      if (!cameraPermission.isGranted) {
        cameraPermission = await Permission.camera.request();
      }

      if (!cameraPermission.isGranted) {
        if (!mounted) return;
        setState(() {
          _cameraPermissionDenied = true;
          _cameraPermissionPermanentlyDenied =
              cameraPermission.isPermanentlyDenied ||
              cameraPermission.isRestricted;
          _cameraError = _cameraPermissionPermanentlyDenied
              ? 'Camera permission is disabled. Enable it in Settings to use the camera.'
              : 'Camera permission is required to use this app.';
        });
        return;
      }

      await viewModel.initializeCamera();

      if (mounted) {
        setState(() {});
        await loadLocation();
      }
    } catch (error) {
      if (mounted) setState(() => _cameraError = error.toString());
    } finally {
      if (mounted) setState(() => _isInitializingCamera = false);
    }
  }

  Future<void> _openGallery() async {
    var permission = await Permission.photos.status;
    if (!permission.isGranted && !permission.isLimited) {
      permission = await Permission.photos.request();
    }

    if (Platform.isAndroid && !permission.isGranted && !permission.isLimited) {
      var storagePermission = await Permission.storage.status;
      if (!storagePermission.isGranted) {
        storagePermission = await Permission.storage.request();
      }
      if (storagePermission.isGranted) permission = storagePermission;
    }

    if (!permission.isGranted && !permission.isLimited) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Photo permission is required to open Gallery.'),
          action: permission.isPermanentlyDenied
              ? SnackBarAction(label: 'Settings', onPressed: openAppSettings)
              : null,
        ),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GalleryScreen()),
    );
    _loadLastImage();
  }

  Future<void> loadLocation() async {
    if (mounted) {
      setState(() {
        _locationError = null;
        _isLocationServiceDisabled = false;
      });
    }
    try {
      final currentPosition = await locationService.getCurrentLocation();

      if (!mounted) return;

      setState(() => position = currentPosition);

      try {
        final currentPlacemark = await locationService.getAddress(
          currentPosition,
        );
        if (mounted) setState(() => placemark = currentPlacemark);
      } catch (error) {
        debugPrint('Address lookup error: $error');
      }
    } catch (error) {
      debugPrint('Location error: $error');
      if (mounted) {
        setState(() {
          _locationError = error.toString();
          _isLocationServiceDisabled =
              error is LocationServiceDisabledException;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    viewModel.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError != null) {
      return CameraErrorView(
        cameraError: _cameraError!,
        cameraPermissionDenied: _cameraPermissionDenied,
        cameraPermissionPermanentlyDenied: _cameraPermissionPermanentlyDenied,
        onRetryPressed: _startCamera,
      );
    }

    if (viewModel.controller == null ||
        !viewModel.controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2563EB),
          ),
        ),
      );
    }

    final latStr = position != null ? AppFormatters.formatLatLong(position!.latitude, true) : '--';
    final lngStr = position != null ? AppFormatters.formatLatLong(position!.longitude, false) : '--';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full Screen Camera Viewport
          CameraPreviewWidget(
            viewModel: viewModel,
            onZoomChanged: () {
              if (mounted) {
                setState(() {});
              }
            },
          ),

          // 1b. Camera Shutter Flash Animation Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showShutterFlash ? 0.9 : 0.0,
                duration: Duration(milliseconds: _showShutterFlash ? 20 : 130),
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // 2. Top Header Bar (Stitch Design)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopAppHeader(
              title: '',
              trailing: const SizedBox(width: 48),
              leading: IconButton(
                onPressed: () async {
                  await viewModel.toggleFlash();
                  setState(() {});
                },
                icon: Icon(
                  viewModel.flashMode == FlashMode.off
                      ? Icons.bolt
                      : viewModel.flashMode == FlashMode.always
                      ? Icons.flash_on
                      : Icons.flashlight_on,
                  color: viewModel.flashMode == FlashMode.off
                      ? Colors.white
                      : Colors.amberAccent,
                  size: 26,
                ),
                tooltip: 'Toggle Flash',
              ),
            ),
          ),

          // 3. Floating Bottom Information Panel (Camera Overlay)
          LocationOverlayCard(
            position: position,
            locationError: _locationError,
            isLocationServiceDisabled: _isLocationServiceDisabled,
            onMapTap: position == null && _locationError != null
                ? (_isLocationServiceDisabled
                    ? () async {
                        await locationService.openLocationSettings();
                        loadLocation();
                      }
                    : loadLocation)
                : null,
            locationCityStateCountry: AppFormatters.formatLocationCityStateCountry(placemark, position),
            fullAddressString: AppFormatters.formatFullAddress(placemark, position),
            latStr: latStr,
            lngStr: lngStr,
            currentDateTimeString: AppFormatters.formatCurrentDateTime(),
          ),

          // 4. Zoom Pill Switcher (Stitch Design: 0.5x, 1x, 2x)
          ZoomPillSwitcher(
            viewModel: viewModel,
            onZoomChanged: () {
              if (mounted) setState(() {});
            },
          ),

          // 5. Bottom Controls Row (Stitch Design)
          CameraBottomControls(
            lastCapturedImage: _lastCapturedImage,
            isCapturing: _isCapturing,
            onGalleryTap: _openGallery,
            onShutterTap: () async {
              if (_isCapturing) return;
              final totalTimer = Stopwatch()..start();
              debugPrint('--------------------------------------------------');
              debugPrint('📸 CAPTURE START');

              setState(() {
                _isCapturing = true;
              });

              final messenger = ScaffoldMessenger.of(context);
              var didSave = false;

              try {
                final swTake = Stopwatch()..start();
                final XFile? image = await viewModel.capturePhoto();
                swTake.stop();
                debugPrint('⏱️ takePicture: ${swTake.elapsedMilliseconds} ms');

                if (image == null) {
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Could not capture photo. Please try again.'),
                      ),
                    );
                  }
                  return;
                }

                // Play shutter sound & trigger shutter flash animation on successful photo capture
                CameraShutterSound.play();
                _triggerShutterFlash();

                final swMap = Stopwatch()..start();
                final mapSnapshot = await mapTileService.createMapSnapshot(position);
                swMap.stop();
                debugPrint('⏱️ map snapshot total: ${swMap.elapsedMilliseconds} ms');

                final swWM = Stopwatch()..start();
                final stampedPhoto = await watermarkService.createStampedPhoto(
                  image,
                  mapSnapshot,
                  placemark: placemark,
                  position: position,
                );
                swWM.stop();
                debugPrint('⏱️ watermark total: ${swWM.elapsedMilliseconds} ms');

                final swSave = Stopwatch()..start();
                await viewModel.saveImageBytes(
                  stampedPhoto,
                  position: position,
                );
                swSave.stop();
                debugPrint('⏱️ gallery save total: ${swSave.elapsedMilliseconds} ms');
                didSave = true;
              } catch (error) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Unable to save photo: $error'),
                    ),
                  );
                }
              } finally {
                final swUI = Stopwatch()..start();
                if (mounted) {
                  setState(() {
                    _isCapturing = false;
                  });
                  _loadLastImage();
                }
                swUI.stop();
                debugPrint('⏱️ UI reset & load last image: ${swUI.elapsedMilliseconds} ms');
              }

              totalTimer.stop();
              debugPrint('🚀 TOTAL CAPTURE TIME: ${totalTimer.elapsedMilliseconds} ms');
              debugPrint('--------------------------------------------------');

              if (!mounted || !didSave) return;

              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Photo saved successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            onLocationTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LocationScreen(),
                ),
              );
              if (mounted) {
                SystemChrome.setEnabledSystemUIMode(
                  SystemUiMode.immersiveSticky,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
