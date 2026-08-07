import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_app2/models/model.dart';
import 'package:my_app2/services/location_service.dart';
import 'package:my_app2/utils/formatters.dart';
import 'package:my_app2/view/gallery_screen.dart';
import 'package:my_app2/view/widgets/bottom_nav_dock.dart';
import 'package:my_app2/view/widgets/location_overlay_card.dart';
import 'package:my_app2/view/widgets/top_app_header.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();

  // Location domain model
  final LocationModel _locationModel = LocationModel();

  Position? get _position => _locationModel.position;
  set _position(Position? val) => _locationModel.position = val;

  Placemark? get _placemark => _locationModel.placemark;
  set _placemark(Placemark? val) => _locationModel.placemark = val;

  String? _error;
  bool _isLoading = true;
  final MapController _mapController = MapController();
  bool _isLocationServiceDisabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadLocation();
    }
  }

  Future<void> _loadLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isLocationServiceDisabled = false;
    });
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;

      setState(() => _position = position);
      try {
        final placemark = await _locationService.getAddress(position);
        if (mounted) setState(() => _placemark = placemark);
      } catch (_) {}
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLocationServiceDisabled =
              error is LocationServiceDisabledException;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // 1. Full Screen Interactive Map
                  _position != null
                      ? FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              _position!.latitude,
                              _position!.longitude,
                            ),
                            initialZoom: 16,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.tachyonbyte.opengps',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    _position!.latitude,
                                    _position!.longitude,
                                  ),
                                  width: 48,
                                  height: 48,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.redAccent,
                                    size: 44,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Container(
                          color: Colors.black,
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Color(0xFF2563EB),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _error ?? 'Location Unavailable',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      if (_isLocationServiceDisabled) ...[
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await _locationService
                                                .openLocationSettings();
                                            _loadLocation();
                                          },
                                          icon: const Icon(
                                            Icons.settings,
                                            size: 16,
                                          ),
                                          label: const Text('Turn on Location'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF2563EB,
                                            ),
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),

                  // 2. Top App Header (Stitch Design)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: TopAppHeader(
                      title: '',
                      onFlashPressed: () => Navigator.pop(context),
                      trailing: const SizedBox(width: 48),
                    ),
                  ),

                  // 3. Floating Location Information Panel (Identical design to Camera Page)
                  LocationOverlayCard(
                    bottomPosition: 19,
                    position: _position,
                    locationError: _error,
                    isLocationServiceDisabled: _isLocationServiceDisabled,
                    onMapTap: _position == null && _error != null
                        ? (_isLocationServiceDisabled
                            ? () async {
                                await _locationService.openLocationSettings();
                                _loadLocation();
                              }
                            : _loadLocation)
                        : null,
                    locationCityStateCountry: AppFormatters.formatLocationCityStateCountry(_placemark, _position),
                    fullAddressString: AppFormatters.formatFullAddress(_placemark, _position),
                    latStr: AppFormatters.formatLatLong(_position?.latitude, true),
                    lngStr: AppFormatters.formatLatLong(_position?.longitude, false),
                    currentDateTimeString: AppFormatters.formatCurrentDateTime(),
                  ),
                ],
              ),
            ),

            // Stitch Bottom Nav Dock (Location Active)
            BottomNavDock(
              activeIndex: 2,
              onGalleryTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GalleryScreen()),
                );
              },
              onShutterTap: () => Navigator.pop(context),
              onLocationTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
