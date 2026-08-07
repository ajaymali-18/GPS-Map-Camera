import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
                          text: locationCityStateCountry,
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
                          text: fullAddressString,
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
                          text: currentDateTimeString,
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
    );
  }
}
