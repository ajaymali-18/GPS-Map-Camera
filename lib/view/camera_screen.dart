import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:my_app2/services/location_service.dart';
import 'package:my_app2/view/gallery_screen.dart';
import '../viewModel/camera_viewmodel.dart';

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
  late XFile? imageFile;

  @override
  void initState() {
    super.initState();

    loadLocation();

    viewModel.initilizeCamera().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Future<void> loadLocation() async {
  //   Position currentPosition = await locationService.getCurrentLocation();
  //   Placemark currentPlacemark = await locationService.getAddress(
  //     currentPosition,
  //   );

  //   setState(() {
  //     position = currentPosition;
  //     placemark = currentPlacemark;
  //   });
  // }

  Future<void> loadLocation() async {
    try {
      Position currentPosition = await locationService.getCurrentLocation();

      print("Latitude: ${currentPosition.latitude}");
      print("Longitude: ${currentPosition.longitude}");

      Placemark currentPlacemark = await locationService.getAddress(
        currentPosition,
      );

      if (!mounted) return;

      setState(() {
        position = currentPosition;
        placemark = currentPlacemark;
      });

      print("UI Updated");
    } catch (e) {
      print("Location Error: $e");
    }
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

          // Map ---
          Positioned(
            top: 550,
            left: 20,
            right: 20,

            child: Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // Small Map ------------>
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: position == null
                          ? const Center(child: CircularProgressIndicator())
                          : FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                  position!.latitude,
                                  position!.longitude,
                                ),
                                initialZoom: 14,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.my_app2',
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
                          "City : ${placemark?.locality ?? '--'},${placemark?.administrativeArea ?? '--'}, ${placemark?.country ?? '--'}",
                          style: const TextStyle(color: Colors.white),
                        ),

                        Text(
                          "Address : "
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
                          maxLines: 3,
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
                          "Date & Time : ${DateTime.now()}",
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
