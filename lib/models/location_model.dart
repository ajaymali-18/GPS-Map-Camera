import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Represents domain GPS location and address data.
class LocationModel {
  Position? position;
  Placemark? placemark;

  LocationModel({
    this.position,
    this.placemark,
  });

  bool get hasLocation => position != null;
  bool get hasAddress => placemark != null;
}
