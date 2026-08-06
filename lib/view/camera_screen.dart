import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_app2/services/location_service.dart';
import 'package:my_app2/view/gallery_screen.dart';
import 'package:my_app2/view/location_screen.dart';
import 'package:my_app2/view/widgets/top_app_header.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../viewModel/camera_viewmodel.dart';

import 'package:image/image.dart' as img;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final LocationService locationService = LocationService();
  final CameraViewModel viewModel = CameraViewModel();
  Position? position;
  Placemark? placemark;
  String? _cameraError;
  String? _locationError;
  bool _isCapturing = false;
  bool _isInitializingCamera = false;
  bool _cameraPermissionDenied = false;
  bool _cameraPermissionPermanentlyDenied = false;
  bool _isLocationServiceDisabled = false;
  File? _lastCapturedImage;

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
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final galleryDir = Directory("${appDir.path}/Gallery");
      if (galleryDir.existsSync()) {
        final files = galleryDir.listSync().whereType<File>().toList();
        if (files.isNotEmpty) {
          files.sort(
            (newer, older) => older.lastModifiedSync().compareTo(
              newer.lastModifiedSync(),
            ),
          );
          if (mounted) {
            setState(() {
              _lastCapturedImage = files.first;
            });
          }
        }
      }
    } catch (_) {}
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

  Future<Uint8List> _createStampedPhoto(
    XFile image,
    img.Image? mapSnapshot,
  ) async {
    final source = await File(image.path).readAsBytes();
    final decoded = img.decodeImage(source);
    if (decoded == null) {
      throw StateError('The captured photo could not be decoded.');
    }

    final photo = img.bakeOrientation(decoded);
    final address = [
      placemark?.street,
      placemark?.subLocality,
      placemark?.locality,
      placemark?.administrativeArea,
      placemark?.postalCode,
      placemark?.country,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
    final timestamp = DateTime.now();
    final unwrappedLines = <String>[
      'Location: ${placemark?.locality ?? 'Unknown'}, ${placemark?.country ?? ''}',
      'Address: ${address.isEmpty ? 'Unavailable' : address}',
      'Latitude: ${position == null ? '--' : position!.latitude.toStringAsFixed(6)}',
      'Longitude: ${position == null ? '--' : position!.longitude.toStringAsFixed(6)}',
      'Date: ${timestamp.toLocal().toString().split('.').first}',
    ];

    const horizontalPadding = 36;
    const lineHeight = 32;
    const verticalPadding = 20;
    final mapSize = mapSnapshot == null
        ? 0
        : (photo.width * 0.22).round().clamp(160, 280).toInt();
    final textStart = horizontalPadding + mapSize + (mapSize == 0 ? 0 : 24);
    final maximumCharacters =
        ((photo.width - textStart - horizontalPadding) ~/ 14)
            .clamp(24, 72)
            .toInt();
    final lines = unwrappedLines
        .expand((line) => _wrapText(line, maximumCharacters))
        .toList();
    final panelHeight = math.max(
      verticalPadding * 2 + lineHeight * lines.length,
      mapSize + verticalPadding * 2,
    );
    final top = (photo.height - panelHeight).clamp(0, photo.height - 1).toInt();
    img.fillRect(
      photo,
      x1: 0,
      y1: top,
      x2: photo.width - 1,
      y2: photo.height - 1,
      color: img.ColorRgba8(0, 0, 0, 185),
    );

    if (mapSnapshot != null) {
      img.compositeImage(
        photo,
        img.copyResize(mapSnapshot, width: mapSize, height: mapSize),
        dstX: horizontalPadding,
        dstY: top + (panelHeight - mapSize) ~/ 2,
      );
      img.drawRect(
        photo,
        x1: horizontalPadding,
        y1: top + (panelHeight - mapSize) ~/ 2,
        x2: horizontalPadding + mapSize - 1,
        y2: top + (panelHeight - mapSize) ~/ 2 + mapSize - 1,
        color: img.ColorRgb8(255, 255, 255),
      );
    }

    for (var index = 0; index < lines.length; index++) {
      img.drawString(
        photo,
        lines[index],
        font: img.arial24,
        x: textStart,
        y: top + verticalPadding + index * lineHeight,
        color: img.ColorRgb8(255, 255, 255),
      );
    }

    return Uint8List.fromList(img.encodeJpg(photo, quality: 95));
  }

  Future<img.Image?> _createMapSnapshot() async {
    if (position == null) return null;

    const zoom = 15;
    const tileSize = 256;
    const mapSize = 256;
    final latitude = position!.latitude;
    final longitude = position!.longitude;
    final tilesAtZoom = 1 << zoom;
    final latitudeRadians = latitude * math.pi / 180;
    final tileX = (longitude + 180) / 360 * tilesAtZoom;
    final tileY =
        (1 -
            math.log(
                  math.tan(latitudeRadians) + 1 / math.cos(latitudeRadians),
                ) /
                math.pi) /
        2 *
        tilesAtZoom;
    final centerTileX = tileX.floor();
    final centerTileY = tileY.floor();

    Future<img.Image?> fetchTile(int x, int y) async {
      if (y < 0 || y >= tilesAtZoom) return null;
      final wrappedX = x % tilesAtZoom;
      try {
        final response = await http
            .get(
              Uri.parse(
                'https://tile.openstreetmap.org/$zoom/$wrappedX/$y.png',
              ),
              headers: const {'User-Agent': 'GPS Camera Flutter app'},
            )
            .timeout(const Duration(seconds: 8));
        return response.statusCode == 200
            ? img.decodeImage(response.bodyBytes)
            : null;
      } catch (_) {
        return null;
      }
    }

    final tileImages = await Future.wait([
      for (var y = -1; y <= 1; y++)
        for (var x = -1; x <= 1; x++)
          fetchTile(centerTileX + x, centerTileY + y),
    ]);
    if (tileImages.every((tile) => tile == null)) return null;

    final canvas = img.Image(width: tileSize * 3, height: tileSize * 3);
    for (var index = 0; index < tileImages.length; index++) {
      final tile = tileImages[index];
      if (tile == null) continue;
      final x = index % 3;
      final y = index ~/ 3;
      img.compositeImage(canvas, tile, dstX: x * tileSize, dstY: y * tileSize);
    }

    final pointX = ((tileX - centerTileX + 1) * tileSize).round();
    final pointY = ((tileY - centerTileY + 1) * tileSize).round();
    final snapshot = img.copyCrop(
      canvas,
      x: pointX - mapSize ~/ 2,
      y: pointY - mapSize ~/ 2,
      width: mapSize,
      height: mapSize,
    );
    img.drawCircle(
      snapshot,
      x: mapSize ~/ 2,
      y: mapSize ~/ 2,
      radius: 11,
      color: img.ColorRgb8(220, 45, 45),
      antialias: true,
    );
    img.fillCircle(
      snapshot,
      x: mapSize ~/ 2,
      y: mapSize ~/ 2,
      radius: 7,
      color: img.ColorRgb8(220, 45, 45),
      antialias: true,
    );
    return snapshot;
  }

  List<String> _wrapText(String text, int maximumCharacters) {
    final words = text.split(RegExp(r'\s+'));
    final wrappedLines = <String>[];
    var line = '';

    for (final word in words) {
      final candidate = line.isEmpty ? word : '$line $word';
      if (candidate.length <= maximumCharacters || line.isEmpty) {
        line = candidate;
      } else {
        wrappedLines.add(line);
        line = word;
      }
    }
    if (line.isNotEmpty) wrappedLines.add(line);
    return wrappedLines;
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

  String get _locationCityStateCountry {
    if (placemark == null) {
      return position != null ? 'Fetching location...' : 'Fetching...';
    }
    final city = placemark!.locality ?? placemark!.subAdministrativeArea ?? '';
    final state = placemark!.administrativeArea ?? '';
    final country = placemark!.country ?? '';
    final parts = [city, state, country].where((s) => s.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown';
  }

  String get _fullAddressString {
    if (placemark == null) {
      return position != null ? 'Fetching address...' : 'Unavailable';
    }
    final parts = [
      placemark!.street,
      placemark!.subLocality,
      placemark!.locality,
      placemark!.administrativeArea,
      placemark!.postalCode,
      placemark!.country,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Unavailable';
  }

  String get _currentDateTimeString {
    final now = DateTime.now().toLocal();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  String _formatLatLongString(double val, bool isLat) {
    final absVal = val.abs().toStringAsFixed(4);
    final ref = isLat ? (val >= 0 ? 'N' : 'S') : (val >= 0 ? 'E' : 'W');
    return '$absVal° $ref';
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError != null) {
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
                  _cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cameraPermissionPermanentlyDenied
                      ? openAppSettings
                      : _startCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _cameraPermissionPermanentlyDenied
                        ? 'Open Settings'
                        : _cameraPermissionDenied
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

    final latStr = position != null ? _formatLatLongString(position!.latitude, true) : '--';
    final lngStr = position != null ? _formatLatLongString(position!.longitude, false) : '--';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full Screen Camera Viewport
          Positioned.fill(
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

                if (mounted) {
                  setState(() {});
                }
              },
              child: CameraPreview(viewModel.controller!),
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
              onFlashPressed: () async {
                await viewModel.toggleFlash();
                setState(() {});
              },
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
          Positioned(
            bottom: 138,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Static Map Thumbnail (Left Side, Fixed Size 96x96 with Rounded Corners)
                  GestureDetector(
                    onTap: position == null && _locationError != null
                        ? (_isLocationServiceDisabled
                            ? () async {
                                await locationService.openLocationSettings();
                                loadLocation();
                              }
                            : loadLocation)
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: position == null
                            ? Container(
                                color: Colors.white10,
                                child: Center(
                                  child: _locationError == null
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          _isLocationServiceDisabled
                                              ? Icons.location_disabled
                                              : Icons.location_off,
                                          color: Colors.white70,
                                          size: 28,
                                        ),
                                ),
                              )
                            : FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    position!.latitude,
                                    position!.longitude,
                                  ),
                                  initialZoom: 14,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'com.tachyonbyte.opengps',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          position!.latitude,
                                          position!.longitude,
                                        ),
                                        width: 24,
                                        height: 24,
                                        child: const Icon(
                                          Icons.location_pin,
                                          color: Colors.redAccent,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Location Details (Right Side, Vertically Aligned)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Location: City, State, Country
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Location: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                              TextSpan(
                                text: _locationCityStateCountry,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),

                        // Address: Full address (wrapping allowed)
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Address: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                              TextSpan(
                                text: _fullAddressString,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),

                        // Latitude
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Latitude: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                              TextSpan(
                                text: latStr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),

                        // Longitude
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Longitude: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                              TextSpan(
                                text: lngStr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),

                        // Date & Time
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Date & Time: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                              TextSpan(
                                text: _currentDateTimeString,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Zoom Pill Switcher (Stitch Design: 0.5x, 1x, 2x)
          Positioned(
            bottom: 96,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0x99262626),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildZoomPillOption('1x', viewModel.currentZoom <= 1.5, () async {
                      await viewModel.setZoom(1.0);
                      if (mounted) setState(() {});
                    }),
                    _buildZoomPillOption('2x', viewModel.currentZoom > 1.5, () async {
                      await viewModel.setZoom(2.0.clamp(viewModel.minZoom, viewModel.maxZoom));
                      if (mounted) setState(() {});
                    }),
                  ],
                ),
              ),
            ),
          ),

          // 5. Bottom Controls Row (Stitch Design)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                color: const Color(0xFF0F0F0F),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Last Photo Thumbnail / Gallery Trigger
                    GestureDetector(
                      onTap: _openGallery,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 1.5),
                        ),
                        child: ClipOval(
                          child: _lastCapturedImage != null
                              ? Image.file(_lastCapturedImage!, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.white12,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // Center: Shutter Ring Button
                    GestureDetector(
                      onTap: _isCapturing
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final XFile? image = await viewModel.capturePhoto();

                              if (image == null) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not capture photo'),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isCapturing = true);
                              var didSave = false;
                              try {
                                final mapSnapshot = await _createMapSnapshot();
                                final stampedPhoto = await _createStampedPhoto(
                                  image,
                                  mapSnapshot,
                                );
                                await viewModel.saveImageBytes(
                                  stampedPhoto,
                                  position: position,
                                );
                                didSave = true;
                              } catch (error) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Could not save photo: $error'),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isCapturing = false);
                                  _loadLastImage();
                                }
                              }

                              if (!mounted || !didSave) return;

                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Photo saved successfully'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _isCapturing ? Colors.grey : Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right: Location Inspector Trigger
                    GestureDetector(
                      onTap: () async {
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
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0x33262626),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomPillOption(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
