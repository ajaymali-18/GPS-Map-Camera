import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class MapTileService {
  Future<img.Image?> createMapSnapshot(Position? position) async {
    if (position == null) return null;

    const zoom = 15;
    const tileSize = 256;
    const mapSize = 256;
    final latitude = position.latitude;
    final longitude = position.longitude;
    final tilesAtZoom = 1 << zoom;
    final latitudeRadians = latitude * math.pi / 180;
    final tileX = (longitude + 180) / 360 * tilesAtZoom;
    final tileY =
        (1 -
            math.log(
                  math.tan(latitudeRadians) + 1 / math.cos(latitudeRadians),
                ) /
                math.pi) /
        2 *
        tilesAtZoom;
    final centerTileX = tileX.floor();
    final centerTileY = tileY.floor();

    Future<img.Image?> fetchTile(int x, int y) async {
      if (y < 0 || y >= tilesAtZoom) return null;
      final wrappedX = x % tilesAtZoom;
      try {
        final response = await http
            .get(
              Uri.parse(
                'https://tile.openstreetmap.org/$zoom/$wrappedX/$y.png',
              ),
              headers: const {'User-Agent': 'GPS Camera Flutter app'},
            )
            .timeout(const Duration(seconds: 8));
        return response.statusCode == 200
            ? img.decodeImage(response.bodyBytes)
            : null;
      } catch (_) {
        return null;
      }
    }

    final tileImages = await Future.wait([
      for (var y = -1; y <= 1; y++)
        for (var x = -1; x <= 1; x++)
          fetchTile(centerTileX + x, centerTileY + y),
    ]);
    if (tileImages.every((tile) => tile == null)) return null;

    final canvas = img.Image(width: tileSize * 3, height: tileSize * 3);
    for (var index = 0; index < tileImages.length; index++) {
      final tile = tileImages[index];
      if (tile == null) continue;
      final x = index % 3;
      final y = index ~/ 3;
      img.compositeImage(canvas, tile, dstX: x * tileSize, dstY: y * tileSize);
    }

    final pointX = ((tileX - centerTileX + 1) * tileSize).round();
    final pointY = ((tileY - centerTileY + 1) * tileSize).round();
    final snapshot = img.copyCrop(
      canvas,
      x: pointX - mapSize ~/ 2,
      y: pointY - mapSize ~/ 2,
      width: mapSize,
      height: mapSize,
    );
    img.drawCircle(
      snapshot,
      x: mapSize ~/ 2,
      y: mapSize ~/ 2,
      radius: 11,
      color: img.ColorRgb8(220, 45, 45),
      antialias: true,
    );
    img.fillCircle(
      snapshot,
      x: mapSize ~/ 2,
      y: mapSize ~/ 2,
      radius: 7,
      color: img.ColorRgb8(220, 45, 45),
      antialias: true,
    );
    return snapshot;
  }
}
