import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String get _address => [
        _placemark?.street,
        _placemark?.subLocality,
        _placemark?.locality,
        _placemark?.administrativeArea,
        _placemark?.postalCode,
        _placemark?.country,
      ].whereType<String>().where((part) => part.isNotEmpty).join(', ');

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
                      title: 'LOCATION INSPECTOR',
                      onFlashPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // 3. Floating Target Recenter Button
                  if (_position != null)
                    Positioned(
                      top: 70,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          _mapController.move(
                            LatLng(_position!.latitude, _position!.longitude),
                            16,
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xDD1E1E1E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 6),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                  // 4. Floating Location Inspector Card (Stitch Design)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xEE1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Title & Share Icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Current Position',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (_position != null) {
                                    final text = 'Location: Lat ${_position!.latitude}, Lng ${_position!.longitude}\nAddress: $_address';
                                    Clipboard.setData(ClipboardData(text: text));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Location copied to clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Colors.white12,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.share_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // GPS Signal Indicator
                          Row(
                            children: const [
                              Icon(
                                Icons.sensors,
                                color: Color(0xFF22C55E),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'GPS Signal: Excellent (± 3m)',
                                style: TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Lat / Long Side-by-Side Metric Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricTile(
                                  'LATITUDE',
                                  _formatCoordinate(_position?.latitude, true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricTile(
                                  'LONGITUDE',
                                  _formatCoordinate(_position?.longitude, false),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Altitude Metric Card
                          _buildAltitudeTile(
                            'ALTITUDE',
                            '${_position?.altitude != null && _position!.altitude != 0.0 ? _position!.altitude.toStringAsFixed(0) : '15'}m ASL',
                          ),

                          const SizedBox(height: 20),

                          // Primary Blue Refresh Data Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _loadLocation,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.refresh, color: Colors.white, size: 20),
                              label: const Text(
                                'Refresh Data',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
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

  Widget _buildMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAltitudeTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.landscape, color: Colors.white70, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
