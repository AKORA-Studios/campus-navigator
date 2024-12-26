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

    final l = ["MS1", "SCH", "BAR", "POT", "HEM"];

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

    final buildingName = "MS1";
    final building =
        buildings.firstWhere((element) => element.shortName == buildingName);
    final x = building.points[0];
    final y = building.points[1];

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

  static (double, double) offsetCoordinates(
      {required double centerLong,
      required double centerLat,
      required double xPos,
      required double yPos,
      int quali_cur = 12}) {
    double long2tile(lon, zo) {
      return ((lon + 180) / 360) * pow(2, zo);
    }

    double lat2tile(lat, zo) {
      return (((1 -
                  log(tan((lat * pi) / 180) + 1 / cos((lat * pi) / 180)) / pi) /
              2) *
          pow(2, zo));
    }

    final g_tilex = long2tile(centerLong, quali_cur);
    final g_tiley = lat2tile(centerLat, quali_cur);

    final g_xtrans = g_tilex - g_tilex.floor();
    final g_ytrans = g_tiley - g_tiley.floor();

    //final g_tilex = g_tilex.floor();
    //final g_tiley = g_tiley.floor();

    // var quali_size = subpics_size / quali_steps[quali_cur];
    final subpics_size = 265;
    final quali_steps = [
      1,
      2,
      4,
      8,
      16,
      32,
      64,
      128,
      256,
      512,
      1024,
      2048,
      4096,
      8192,
      16384,
      32768,
      65536,
      131072,
      262144,
      524288,
      1048576,
    ];
    ;
    final quali_size = subpics_size / quali_steps[quali_cur];

    // final xCorrected = (xPos - g_tilex - g_xtrans) * quali_size;
    // final yCorrected = (yPos - g_tiley - g_ytrans) * quali_size;

    // final yCorrected = yPos - ((g_ytrans - 0.5) * quali_size);

    // final xOff = ((g_xtrans - 0.5) * quali_size);
    // final yOff = ((g_ytrans - 0.5) * quali_size);

    // final xCorrected = (xPos * 0.01) - 0.1; // - xOff;
    // final yCorrected = (yPos * 0.01) - 1.0; // - yOff;

    final xOff = -0.728;
    final yOff = 0.071;

    final xCorrected = ((xPos + xOff) * 0.01); // - xOff;
    final yCorrected = ((-yPos + yOff) * 0.01); // - yOff;

    // return (xCorrected, yCorrected);
    return (xCorrected, yCorrected);
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
