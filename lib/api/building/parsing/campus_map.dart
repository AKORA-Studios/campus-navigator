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

    final buildingName = "MS1";
    final building =
        buildings.firstWhere((element) => element.shortName == buildingName);
    final i = 0;
    final x = building.points[i];
    final y = building.points[i + 1];

    final (bLong, bLat) = offsetCoordinates(
        centerLong: centerLong, centerLat: centerLat, xPos: x, yPos: y);

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
