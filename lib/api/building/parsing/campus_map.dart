import 'dart:async';
import 'html_data.dart';
import 'package:campus_navigator/api/building/parsing/common.dart';

class CampusBuilding {
  /// kurzz
  final String shortName;

  /// points
  final List<double> points;

  CampusBuilding({
    required this.shortName,
    required this.points,
  });

  factory CampusBuilding.fromJson(Map<String, dynamic> json) {
    final shortName = json["kurzz"] as String;
    final points = json["points"] as List<dynamic>;

    return CampusBuilding(
        points: points.map((e) => (e as num).toDouble()).toList(),
        shortName: shortName);
  }

  /// Translates the building points to latitude and longitude values
  List<(double, double)> translatePoints({
    required double centerLong,
    required double centerLat,
  }) {
    List<(double, double)> coords = [];

    for (int i = 0; i < (points.length - 1); i += 2) {
      final xPos = points[i];
      final yPos = points[i + 1];

      coords.add(translateCoordinates(
          centerLong: centerLong,
          centerLat: centerLat,
          xPos: xPos,
          yPos: yPos));
    }

    return coords;
  }

  /// Converts the given x and y values to a pair of (long, lat)
  static (double, double) translateCoordinates({
    required double centerLong,
    required double centerLat,
    required double xPos,
    required double yPos,
  }) {
    // Flipp y axis for some reason
    final x = xPos;
    final y = -yPos;

    // Scaling point, this can in theory be an arbitraty point (even 0,0)
    // In this case it is the northest corner of MS1, as seen in the link
    // https://navigator.tu-dresden.de/~13.72979843,51.032567,ScalingOff@13.729798,51.032539,20.z
    const xScalingPoint = -1.7921564444444964;
    const yScalingPoint = -0.6142086473036215;

    // Offsets to correct map translation
    // Found by manually adjusting them until they fit
    const xOff = -0.728;
    const yOff = 0.071;

    // This is used because the provided x and y positions
    // Are in the map local coordinate system and not in the
    // Global lat/long coordinate system
    const scale = 0.01;

    // x and y positions relative to scaling offset
    final xRel = x - xScalingPoint;
    final yRel = y - yScalingPoint;

    // This scales the x and y corrdinates realtive from the scaling point,
    // to achieve relative latitude and longitude
    // The scaling amounts are found by trial and error.
    // Using the return values of this function print the following:
    // print("https://navigator.tu-dresden.de/~$long,$lat,$buildingName@$long,$lat,20.z");
    // Do this with a known building corner and adjust the scaliong values accordingly
    final longOffset = (((xRel * 1.40627) + xScalingPoint) + xOff) * scale;
    final latOffset = (((yRel * 0.88485) + yScalingPoint) + yOff) * scale;

    // Translate local coordinates to global coordinates
    final long = centerLong + longOffset;
    final lat = centerLat + latOffset;

    return (long, lat);
  }
}

class CampusMapData {
  final HTMLData htmlData;

  /// Longitude of map center
  final double centerLong;

  /// Latitude of map center
  final double centerLat;

  /// List of all buildings
  final List<CampusBuilding> buildings;

  CampusMapData({
    required this.htmlData,
    required this.centerLong,
    required this.centerLat,
    required this.buildings,
  });

  factory CampusMapData.fromHTMLText(String body) {
    final htmlData = HTMLData.fromBody(body);

    // Parse building polygon data
    final gebaeudeData =
        htmlData.assignedVariables["gebaeudeData"] as List<dynamic>;
    final buildings = gebaeudeData
        .map((e) => CampusBuilding.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parse center coordinates
    final centerLong = htmlData.numberVariables["s_long"]!;
    final centerLat = htmlData.numberVariables["s_lat"]!;

    // Separate multi polygons
    /*
    {
      for (final (i, b) in buildings.indexed) {
        final duplicatedPoints = b.points.indexed
            .map((p) {
              final pIndex = p.$1;
              final pValue = p.$2;

              final isX = (pIndex % 2) == 0;
              // Coordinates that are also x | y
              final sameCoordPoints = b.points.indexed
                  .where((p) => (p.$1 % 2 == 0) == isX)
                  .map((e) => e.$2);

              return (p.$1, sameCoordPoints.where((pp) => p.$2 == pp).length);
            })
            .where((p) => p.$2 > 1)
            .toList();

        if (duplicatedPoints.isEmpty) continue;

        // Filter for points where the x and y coordinates are duplicated
        final duplicatedEnds = duplicatedPoints.where((e) {
          final pIndex = e.$1;
          final pValue = e.$2;
          return duplicatedPoints.any((element) =>
              ((element.$1 == (pIndex + 2)) || (element.$1 == (pIndex - 2))) &&
              element.$2 == pValue);
        });

        print("${b.shortName} ${duplicatedEnds.map((e) => e.$1)}");
      }
    }

    for (final b in buildings) {
      final c = b.points
          .map((p) => b.points.where((pp) => p == pp).length)
          .where((element) => element > 1)
          .length;

      // print("${b.shortName}: $c");
    }
    */

    return CampusMapData(
        htmlData: htmlData,
        buildings: buildings,
        centerLong: centerLong,
        centerLat: centerLat);
  }

  static Future<CampusMapData> fetch() async {
    final uri = Uri.parse(baseURL);

    String? body = await fetchHMTL(uri);
    if (body == null) {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load search results');
    }

    return CampusMapData.fromHTMLText(body);
  }
}
