import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class AppFormatters {
  static String countryCodeToEmoji(String? countryCode) {
    if (countryCode == null || countryCode.length != 2) return '';
    final code = countryCode.toUpperCase();
    final firstChar = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondChar = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return ' ${String.fromCharCode(firstChar)}${String.fromCharCode(secondChar)}';
  }

  static String formatLocationCityStateCountry(Placemark? placemark, Position? position) {
    if (placemark == null) {
      return position != null ? 'Fetching location...' : 'Fetching...';
    }
    final city = placemark.locality ?? placemark.subAdministrativeArea ?? '';
    final state = placemark.administrativeArea ?? '';
    final country = placemark.country ?? '';
    final parts = [city, state, country].where((s) => s.trim().isNotEmpty).toList();
    final flag = countryCodeToEmoji(placemark.isoCountryCode);
    return parts.isNotEmpty ? '${parts.join(', ')}$flag' : 'Unknown';
  }

  static String formatFullAddress(Placemark? placemark, Position? position) {
    if (placemark == null) {
      return position != null ? 'Fetching address...' : 'Unavailable';
    }
    final parts = [
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Unavailable';
  }

  static String formatCoordinates(Position? position) {
    if (position == null) return 'Lat --° Long --°';
    final lat = position.latitude.toStringAsFixed(6);
    final lng = position.longitude.toStringAsFixed(6);
    return 'Lat $lat° Long $lng°';
  }

  static String formatCurrentDateTime([DateTime? dt]) {
    final now = (dt ?? DateTime.now()).toLocal();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final weekday = weekdays[now.weekday - 1];
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    int hour = now.hour % 12;
    if (hour == 0) hour = 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final offsetHours = offset.inHours.abs().toString().padLeft(2, '0');
    final offsetMinutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$weekday, $month/$day/$year $hour:$minute $period GMT $sign$offsetHours:$offsetMinutes';
  }

  static String formatLatLong(double? val, bool isLat) {
    if (val == null) return '--';
    final absVal = val.abs().toStringAsFixed(4);
    final ref = isLat ? (val >= 0 ? 'N' : 'S') : (val >= 0 ? 'E' : 'W');
    return '$absVal° $ref';
  }

  static String formatStitchDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final fileDate = DateTime(dt.year, dt.month, dt.day);

    if (fileDate == today) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:$minute $period';
    } else if (fileDate == yesterday) {
      return 'YEST';
    } else {
      const monthAbbrs = [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
      ];
      return '${monthAbbrs[dt.month - 1]} ${dt.day}';
    }
  }

  static String formatExifDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y:$m:$d $hh:$mm:$ss';
  }

  static List<String> wrapText(String text, int maximumCharacters) {
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
}
