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
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../viewModel/camera_viewmodel.dart';

import 'package:image/image.dart' as img;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}
// Location Class

class _CameraScreenState extends State<CameraScreen> {
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

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _startCamera();
  }

  /// Runtime permission prompts must be requested one at a time on Android.
  /// Starting location at the same time as the camera can cause the camera
  /// plugin to report a false "permission denied" initialization error.
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

      // Request location only after the camera permission dialog is complete.
      // A location failure must not prevent the camera preview from opening.
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

    // The photo can be much narrower than the preview, so wrap address text
    // based on the actual photo width instead of cutting it off.
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

  String _countryFlag(String? countryCode) {
    if (countryCode == null || countryCode.length != 2) return '';

    final code = countryCode.toUpperCase();
    return String.fromCharCodes(
      code.codeUnits.map((letter) => 0x1F1E6 + letter - 0x41),
    );
  }

  String _formattedDateTime(DateTime value) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '${weekdays[value.weekday - 1]}, ${value.day} '
        '${months[value.month - 1]} ${value.year}, $hour:$minute $period';
  }

  Future<void> loadLocation() async {
    if (mounted) setState(() => _locationError = null);
    try {
      Position currentPosition = await locationService.getCurrentLocation();

      Placemark currentPlacemark = await locationService.getAddress(
        currentPosition,
      );

      if (!mounted) return;

      setState(() {
        position = currentPosition;
        placemark = currentPlacemark;
      });
    } catch (error) {
      debugPrint('Location error: $error');
      if (mounted) setState(() => _locationError = error.toString());
    }
  }

  @override
  void dispose() {
    viewModel.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 48),
                const SizedBox(height: 12),
                Text(_cameraError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cameraPermissionPermanentlyDenied
                      ? openAppSettings
                      : _startCamera,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Native-camera style preview: it fills the complete portrait
          // screen, including the space previously occupied by the AppBar.
          Positioned.fill(child: CameraPreview(viewModel.controller!)),

          // Map ---
          Positioned(
            bottom: 150,
            left: 12,
            right: 12,

            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // Small Map ------------>
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: position == null
                          ? Center(
                              child: _locationError == null
                                  ? const CircularProgressIndicator()
                                  : const Icon(
                                      Icons.location_off,
                                      color: Colors.white,
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
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: Color.fromARGB(
                                          255,
                                          235,
                                          101,
                                          92,
                                        ),
                                        size: 35,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Location Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${placemark?.locality ?? '--'}, ${placemark?.administrativeArea ?? '--'}, ${placemark?.country ?? '--'} ${_countryFlag(placemark?.isoCountryCode)}",
                          style: const TextStyle(color: Colors.white),
                        ),

                        Text(
                          "${placemark?.street ?? ''}, "
                          "${placemark?.subLocality ?? ''}, "
                          "${placemark?.locality ?? ''}, "
                          "${placemark?.administrativeArea ?? ''}, "
                          "${placemark?.postalCode ?? ''}, "
                          "${placemark?.country ?? ''}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Latitude : ${position?.latitude ?? '--'}°",
                          style: const TextStyle(color: Colors.white),
                        ),

                        Text(
                          "Longitude : ${position?.longitude ?? '--'}°",
                          style: const TextStyle(color: Colors.white),
                        ),

                        Text(
                          _formattedDateTime(DateTime.now()),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
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
                      ],
                    ),

                    // Camera
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          elevation: 0,

                          onPressed: _isCapturing
                              ? null
                              : () async {
                                  final XFile? image = await viewModel
                                      .capturePhoto();

                                  if (image == null) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not capture photo',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _isCapturing = true);
                                  var didSave = false;
                                  try {
                                    final mapSnapshot =
                                        await _createMapSnapshot();
                                    final stampedPhoto =
                                        await _createStampedPhoto(
                                          image,
                                          mapSnapshot,
                                        );
                                    await viewModel.saveImageBytes(
                                      stampedPhoto,
                                    );
                                    didSave = true;
                                  } catch (error) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        this.context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not save photo: $error',
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isCapturing = false);
                                    }
                                  }

                                  if (!mounted || !didSave) return;

                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text('Photo saved successfully'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },

                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF3C096C),
                          shape: const CircleBorder(
                            side: BorderSide(color: Colors.white),
                          ),
                          child: const Icon(Icons.camera_alt),
                        ),
                      ],
                    ),

                    // Location
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          elevation: 0,
                          onPressed: () async {
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
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF3C096C),
                          child: const Icon(Icons.location_on),
                        ),
                      ],
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
}
