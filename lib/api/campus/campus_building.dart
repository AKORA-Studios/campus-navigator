import 'dart:convert';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Public TU mobile API: `punkte` contains independent geographic outlines.
/// x is longitude, y is latitude (degrees), NOT the legacy HTML canvas space.
class CampusFeature {
  final String code;
  final String name;
  final String? address;
  final List<String> partIds;
  final List<List<LatLng>> outlines;

  CampusFeature._(
      this.code, this.name, this.address, this.partIds, this.outlines);

  static CampusFeature? fromJson(dynamic value) {
    if (value is! Map) return null;
    final code = value['krz'];
    final name = value['name'];
    if (code is! String ||
        !RegExp(r'^[A-Za-z0-9ÄÖÜäöüß_-]{1,20}$').hasMatch(code) ||
        name is! String ||
        name.trim().isEmpty) return null;
    final outlines = <List<LatLng>>[];
    final raw = value['punkte'];
    if (raw is List) {
      for (final ring in raw.take(200)) {
        if (ring is! List || ring.length < 3 || ring.length > 10000) continue;
        final points = <LatLng>[];
        var valid = true;
        for (final p in ring) {
          if (p is! Map || p['x'] is! num || p['y'] is! num) {
            valid = false;
            break;
          }
          final lon = (p['x'] as num).toDouble();
          final lat = (p['y'] as num).toDouble();
          if (!lon.isFinite ||
              !lat.isFinite ||
              lon.abs() > 180 ||
              lat.abs() > 85) {
            valid = false;
            break;
          }
          final point = LatLng(lat, lon);
          if (points.isEmpty || points.last != point) points.add(point);
        }
        if (points.length > 1 && points.first == points.last) {
          points.removeLast();
        }
        if (!valid ||
            points.toSet().length < 3 ||
            _area(points).abs() < 1e-14) {
          continue;
        }
        // Reject projected metres or a broken outline spanning whole regions.
        final lats = points.map((p) => p.latitude);
        final lons = points.map((p) => p.longitude);
        if (lats.reduce(math.max) - lats.reduce(math.min) > 1 ||
            lons.reduce(math.max) - lons.reduce(math.min) > 1) continue;
        outlines.add(List.unmodifiable(points));
      }
    }
    final ids = <String>[];
    String? address;
    final parts = value['teilgeb'];
    if (parts is List) {
      for (final part in parts) {
        if (part is! Map) continue;
        final id = part['gebnr'];
        if (id is String && RegExp(r'^\d+$').hasMatch(id)) ids.add(id);
        // Preserve the actual server street name; don't invent a house number.
        if (address == null && part['str'] is String) {
          final street = (part['str'] as String).trim();
          final city = [part['plz'], part['ort']]
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .join(' ');
          if (street.isNotEmpty) {
            address = '$street${city.isEmpty ? '' : ', $city'}';
          }
        }
      }
    }
    // The accessibility address often includes house numbers but omits spaces.
    final info = value['barfrei_info'];
    final detailed = info is Map ? info['adresse'] : null;
    if (detailed is String &&
        detailed.trim().isNotEmpty &&
        !detailed.contains('<')) {
      final street = detailed.trim().replaceFirstMapped(
          RegExp(r'([A-Za-zäöüÄÖÜß])(\d)'), (m) => '${m[1]} ${m[2]}');
      final city = parts is List && parts.isNotEmpty && parts.first is Map
          ? [(parts.first as Map)['plz'], (parts.first as Map)['ort']]
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .join(' ')
          : '';
      address = '$street${city.isEmpty ? '' : ', $city'}';
    }
    return CampusFeature._(code.toUpperCase(), name.trim(), address,
        List.unmodifiable(ids), List.unmodifiable(outlines));
  }

  static double _area(List<LatLng> points) {
    if (points.length < 3) return 0;
    // Translate first to avoid cancellation in small geographic footprints.
    final origin = points.first;
    var area = 0.0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      area +=
          (a.longitude - origin.longitude) * (b.latitude - origin.latitude) -
              (b.longitude - origin.longitude) * (a.latitude - origin.latitude);
    }
    return area / 2;
  }

  List<LatLng> get largestOutline =>
      outlines.reduce((a, b) => _area(a).abs() >= _area(b).abs() ? a : b);

  /// Center of the largest outline's bounds; deliberately not called entrance.
  LatLng? get mapPoint {
    if (outlines.isEmpty) return null;
    final ring = largestOutline;
    return LatLng(
        (ring.map((p) => p.latitude).reduce(math.min) +
                ring.map((p) => p.latitude).reduce(math.max)) /
            2,
        (ring.map((p) => p.longitude).reduce(math.min) +
                ring.map((p) => p.longitude).reduce(math.max)) /
            2);
  }

  String get floorCode => code.toLowerCase();

  /// No entrance coordinates are verified in the public TU catalog. Use only
  /// its validated geographic footprint, never floor-plan or guessed entrances.
  /// The universal HTTPS URL opens Maps when available, otherwise a browser.
  Uri? get routeUri {
    final point = mapPoint;
    if (point == null ||
        !point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude.abs() > 90 ||
        point.longitude.abs() > 180) return null;
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${point.latitude},${point.longitude}',
      'travelmode': 'walking',
    });
  }
}

List<CampusFeature> parseCampusBuildings(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! List || decoded.isEmpty || decoded.length > 5000) {
    throw const FormatException('Unexpected TU building catalog');
  }
  final buildings = <String, CampusFeature>{};
  for (final record in decoded) {
    final feature = CampusFeature.fromJson(record);
    if (feature != null) buildings.putIfAbsent(feature.code, () => feature);
  }
  if (buildings.isEmpty || buildings.values.every((b) => b.outlines.isEmpty)) {
    throw const FormatException('No usable TU building geometries');
  }
  return List.unmodifiable(
      buildings.values.toList()..sort((a, b) => a.name.compareTo(b.name)));
}
