import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_app2/services/location_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationService _locationService = LocationService();
  Position? _position;
  Placemark? _placemark;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final position = await _locationService.getCurrentLocation();
      final placemark = await _locationService.getAddress(position);
      if (!mounted) return;
      setState(() {
        _position = position;
        _placemark = placemark;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current Location')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadLocation,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        _position!.latitude,
                        _position!.longitude,
                      ),
                      initialZoom: 16,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
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
                              _position!.latitude,
                              _position!.longitude,
                            ),
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_placemark?.locality ?? '--'}, '
                          '${_placemark?.administrativeArea ?? '--'}, '
                          '${_placemark?.country ?? '--'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _address.isEmpty ? 'Address unavailable' : _address,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Latitude: ${_position!.latitude.toStringAsFixed(6)}',
                        ),
                        Text(
                          'Longitude: ${_position!.longitude.toStringAsFixed(6)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _loadLocation,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
