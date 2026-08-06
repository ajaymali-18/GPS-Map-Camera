import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:native_exif/native_exif.dart';
import 'package:path/path.dart' as path;

class ImagePreviewScreen extends StatefulWidget {
  final File image;

  const ImagePreviewScreen({super.key, required this.image});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  Map<String, Object> _exifData = {};
  double? _latitude;
  double? _longitude;
  Placemark? _placemark;
  bool _isLoadingExif = true;
  int? _imageWidth;
  int? _imageHeight;
  int _fileSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadExif();
  }

  Future<void> _loadExif() async {
    try {
      final file = widget.image;
      if (await file.exists()) {
        _fileSizeBytes = await file.length();
        final exif = await Exif.fromPath(file.path);
        final attributes = await exif.getAttributes() ?? <String, Object>{};
        final latLong = await exif.getLatLong();
        await exif.close();

        _exifData = attributes;

        final widthAttr = attributes['ImageWidth'];
        final heightAttr = attributes['ImageLength'];
        if (widthAttr != null && heightAttr != null) {
          _imageWidth = int.tryParse(widthAttr.toString());
          _imageHeight = int.tryParse(heightAttr.toString());
        }

        if (latLong != null) {
          _latitude = latLong.latitude;
          _longitude = latLong.longitude;
        } else {
          final latAttr = attributes['GPSLatitude'];
          final latRef = attributes['GPSLatitudeRef'];
          final lngAttr = attributes['GPSLongitude'];
          final lngRef = attributes['GPSLongitudeRef'];
          if (latAttr != null && lngAttr != null) {
            double? parsedLat = double.tryParse(latAttr.toString());
            double? parsedLng = double.tryParse(lngAttr.toString());
            if (parsedLat != null && parsedLng != null) {
              if (latRef?.toString().toUpperCase() == 'S') {
                parsedLat = -parsedLat.abs();
              }
              if (lngRef?.toString().toUpperCase() == 'W') {
                parsedLng = -parsedLng.abs();
              }
              _latitude = parsedLat;
              _longitude = parsedLng;
            }
          }
        }

        if (_latitude != null && _longitude != null) {
          try {
            final placemarks = await placemarkFromCoordinates(
              _latitude!,
              _longitude!,
            );
            if (placemarks.isNotEmpty) {
              _placemark = placemarks.first;
            }
          } catch (e) {
            debugPrint("Reverse geocoding error in preview: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading EXIF in preview: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExif = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formattedFileDate(DateTime value) {
    return '${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Future<void> deleteImage(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Delete Image", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to delete this image?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await widget.image.delete();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image deleted successfully")),
    );
    Navigator.pop(context, true);
  }

  void _showExifDetailsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final address = [
          _placemark?.street,
          _placemark?.subLocality,
          _placemark?.locality,
          _placemark?.administrativeArea,
          _placemark?.postalCode,
          _placemark?.country,
        ].whereType<String>().where((p) => p.isNotEmpty).join(', ');

        final dateTimeStr = _exifData['DateTimeOriginal']?.toString() ??
            _exifData['DateTime']?.toString() ??
            _formattedFileDate(widget.image.lastModifiedSync());

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    "Exif Metadata & Photo Info",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTile(
                    Icons.insert_drive_file_outlined,
                    "File Name",
                    path.basename(widget.image.path),
                  ),
                  _buildInfoTile(
                    Icons.sd_storage_outlined,
                    "File Size",
                    _formatFileSize(_fileSizeBytes),
                  ),
                  if (_imageWidth != null && _imageHeight != null)
                    _buildInfoTile(
                      Icons.aspect_ratio_outlined,
                      "Resolution",
                      "$_imageWidth × $_imageHeight",
                    ),
                  _buildInfoTile(
                    Icons.calendar_today_outlined,
                    "Date & Time",
                    dateTimeStr,
                  ),
                  _buildInfoTile(
                    Icons.location_on_outlined,
                    "Latitude",
                    _latitude != null
                        ? "${_latitude!.abs().toStringAsFixed(6)}° ${_latitude! >= 0 ? 'N' : 'S'}"
                        : "Not recorded in EXIF",
                  ),
                  _buildInfoTile(
                    Icons.location_on_outlined,
                    "Longitude",
                    _longitude != null
                        ? "${_longitude!.abs().toStringAsFixed(6)}° ${_longitude! >= 0 ? 'E' : 'W'}"
                        : "Not recorded in EXIF",
                  ),
                  if (address.isNotEmpty)
                    _buildInfoTile(
                      Icons.map_outlined,
                      "Address",
                      address,
                    ),
                  if (_exifData.containsKey('GPSAltitude'))
                    _buildInfoTile(
                      Icons.height_outlined,
                      "Altitude",
                      "${_exifData['GPSAltitude']} m",
                    ),
                  if (_exifData.isNotEmpty) ...[
                    const Divider(color: Colors.white12, height: 24),
                    const Text(
                      "Raw EXIF Tags",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._exifData.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 140,
                              child: Text(
                                "${entry.key}: ",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = [
      _placemark?.locality,
      _placemark?.country,
    ].whereType<String>().where((p) => p.isNotEmpty).join(', ');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Photo Preview"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image.file(widget.image),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: _showExifDetailsSheet,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xDD1C1C1C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _isLoadingExif
                          ? const Text(
                              "Loading EXIF metadata...",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _latitude != null && _longitude != null
                                      ? "Lat: ${_latitude!.toStringAsFixed(6)}°, Lng: ${_longitude!.toStringAsFixed(6)}°"
                                      : "No GPS EXIF recorded",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (address.isNotEmpty)
                                  Text(
                                    address,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: const Color(0xFF0F0F0F),
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Delete Image',
                onPressed: () => deleteImage(context),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
