import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_app2/utils/formatters.dart';

class LocationOverlayCard extends StatelessWidget {
  final Position? position;
  final String? locationError;
  final bool isLocationServiceDisabled;
  final VoidCallback? onMapTap;
  final String locationCityStateCountry;
  final String fullAddressString;
  final String latStr;
  final String lngStr;
  final String currentDateTimeString;
  final double bottomPosition;

  const LocationOverlayCard({
    super.key,
    required this.position,
    required this.locationError,
    required this.isLocationServiceDisabled,
    required this.onMapTap,
    required this.locationCityStateCountry,
    required this.fullAddressString,
    required this.latStr,
    required this.lngStr,
    required this.currentDateTimeString,
    this.bottomPosition = 138,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottomPosition,
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
              onTap: onMapTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: position == null
                      ? Container(
                          color: Colors.white10,
                          child: Center(
                            child: locationError == null
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    isLocationServiceDisabled
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
                  // Line 1: City, State, Country 🇮🇳
                  Text(
                    locationCityStateCountry,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Line 2 & 3: Full reverse-geocoded address
                  Text(
                    fullAddressString,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Line 4: Lat 19.986442° Long 73.748861°
                  Text(
                    position != null
                        ? AppFormatters.formatCoordinates(position)
                        : (latStr != '--' && lngStr != '--'
                            ? 'Lat $latStr Long $lngStr'
                            : 'Lat --° Long --°'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Line 5: Saturday, 08/08/2026 11:44 AM GMT +05:30
                  Text(
                    currentDateTimeString,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
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
    );
  }
}
