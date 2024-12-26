import 'dart:async';
import 'dart:math';

import 'package:campus_navigator/api/building/parsing/common.dart';
import 'package:campus_navigator/api/building/parsing/room_polygon.dart';
import 'package:campus_navigator/painter.dart';
import 'package:flutter/services.dart';

import 'html_data.dart';
import 'position.dart';

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

    final l = ["MS1", "SCH", "BAR", "JUD", "WÜR", "POT", "HEM"];

    String csv = "lat,long\n";
    for (final b in buildings.where((b) => l.contains(b.shortName))) {
      for (int i = 0; i < (b.points.length - 1); i += 2) {
        final (corrX, corrY) = offsetCoordinates(
            centerLong: centerLong,
            centerLat: centerLat,
            xPos: b.points[i],
            yPos: b.points[i + 1]);
        final bLong = centerLong + corrX;
        final bLat = centerLat + corrY;
        csv += "$bLat,$bLong\n";
      }
    }

    Clipboard.setData(ClipboardData(text: csv))
        .then((value) => print("copied"));

    /*



  */

    final buildingName = "JUD";
    final building =
        buildings.firstWhere((element) => element.shortName == buildingName);
    final i = 0;
    final x = building.points[i];
    final y = building.points[i + 1];

    final (corrX, corrY) = offsetCoordinates(
        centerLong: centerLong, centerLat: centerLat, xPos: x, yPos: y);

    final bLong = centerLong + corrX;
    final bLat = centerLat + corrY;

    print(
        "https://navigator.tu-dresden.de/~$bLong,$bLat,$buildingName@$bLong,$bLat,20.z");

    return CampusMapData(
        htmlData: htmlData,
        buildings: buildings,
        centerLong: centerLong,
        centerLat: centerLat);
  }

  static (double, double) offsetCoordinates({
    required double centerLong,
    required double centerLat,
    required double xPos,
    required double yPos,
  }) {
    // Pre scaled and flipped axises
    final x = xPos;
    final y = -yPos;

    // Scaling point, northes corner of MS1
    final xScalingOff = -1.7921564444444964;
    final yScalingOff = -0.6142086473036215;

    // Offsets to correct map translation
    // Found by manually adjusting them until they fit
    final xOff = -0.728;
    final yOff = 0.071;

    final scale = 0.01 * 1;

    // x and y positions relative to sclaing offset
    final xRel = x - xScalingOff;
    final yRel = y - yScalingOff;

    final xCorrected = ((((xRel) * 1.4062) + xScalingOff) + xOff);
    final yCorrected = ((((yRel) * 0.884) + yScalingOff) + yOff);

    return (xCorrected * 0.01, yCorrected * 0.01);
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
