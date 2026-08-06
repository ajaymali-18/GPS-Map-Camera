import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_app2/services/location_service.dart';
import 'package:my_app2/view/gallery_screen.dart';
import 'package:my_app2/view/widgets/bottom_nav_dock.dart';
import 'package:my_app2/view/widgets/top_app_header.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  Position? _position;
  Placemark? _placemark;
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
          _isLocationServiceDisabled = error is LocationServiceDisabledException;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _locationCityStateCountry {
    if (_placemark == null) {
      return _position != null ? 'Fetching location...' : 'Fetching...';
    }
    final city = _placemark!.locality ?? _placemark!.subAdministrativeArea ?? '';
    final state = _placemark!.administrativeArea ?? '';
    final country = _placemark!.country ?? '';
    final parts = [city, state, country].where((s) => s.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown';
  }

  String get _fullAddressString {
    if (_placemark == null) {
      return _position != null ? 'Fetching address...' : 'Unavailable';
    }
    final parts = [
      _placemark!.street,
      _placemark!.subLocality,
      _placemark!.locality,
      _placemark!.administrativeArea,
      _placemark!.postalCode,
      _placemark!.country,
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

  String _formatCoordinate(double? val, bool isLat) {
    if (val == null) return '--';
    final absVal = val.abs().toStringAsFixed(4);
    final ref = isLat ? (val >= 0 ? 'N' : 'S') : (val >= 0 ? 'E' : 'W');
    return '$absVal° $ref';
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
                                ? const CircularProgressIndicator(color: Color(0xFF2563EB))
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _error ?? 'Location Unavailable',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      if (_isLocationServiceDisabled) ...[
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await _locationService.openLocationSettings();
                                            _loadLocation();
                                          },
                                          icon: const Icon(Icons.settings, size: 16),
                                          label: const Text('Turn on Location'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2563EB),
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
                  Positioned(
                    bottom: 19,
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
                            onTap: _position == null && _error != null
                                ? (_isLocationServiceDisabled
                                    ? () async {
                                        await _locationService.openLocationSettings();
                                        _loadLocation();
                                      }
                                    : _loadLocation)
                                : null,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 96,
                                height: 96,
                                child: _position == null
                                    ? Container(
                                        color: Colors.white10,
                                        child: Center(
                                          child: _error == null
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
                                            _position!.latitude,
                                            _position!.longitude,
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
                                                  _position!.latitude,
                                                  _position!.longitude,
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
                                        text: _formatCoordinate(_position?.latitude, true),
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
                                        text: _formatCoordinate(_position?.longitude, false),
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
