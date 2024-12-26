import 'dart:async';
import 'dart:convert';

import 'package:campus_navigator/api/building/parsing/building_data.dart';
import 'package:campus_navigator/api/building/parsing/campus_map.dart';
import 'package:campus_navigator/api/building/parsing/common.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

import 'page_image_data.dart';
import 'parsing/html_data.dart';
import 'parsing/layer_data.dart';
import 'parsing/raum_bez_data.dart';
import 'parsing/room_polygon.dart';

final RegExp raumbezExp = RegExp(r"^raumbezData = ({[^;]+)", multiLine: true);

final RegExp pngFileNameExp =
    RegExp(r'var png_file_name = "(\w+)";', multiLine: true);

final RegExp highlightedRoomExp =
    RegExp(r"ETplan\.permahighlightRaum\((\d+), (\w+)\);", multiLine: true);

class BuildingPageData {
  final HTMLData htmlData;
  final RaumBezData raumBezData;
  final Map<String, double> numberVariables;
  final String pngFileName;
  final Map<String, List<RoomPolygon>> rooms;
  final List<LayerData> layers;
  PageImageData? backgroundImageData;
  final BuildingData buildingData;
  final List<String> queryParts;

  BuildingPageData(
      {required this.htmlData,
      required this.raumBezData,
      required this.numberVariables,
      required this.pngFileName,
      required this.rooms,
      required this.layers,
      required this.buildingData,
      required this.queryParts});

  factory BuildingPageData.fromHTMLText(String body, List<String> queryParts) {
    final htmlData = HTMLData.fromBody(body);

    final buildingInfo = BuildingData.fromHTMLDocument(htmlData.document);

    // Parse room labels
    final raumBezMatch = raumbezExp.firstMatch(htmlData.script)!;
    RaumBezData raumBezData =
        RaumBezData.fromJson(jsonDecode(raumBezMatch[1]!));

    // Parse symbol layers
    List<LayerData> layers = htmlData.declaredVariables.entries
        .where((e) => e.key.startsWith("slayer"))
        .map((e) => LayerData.fromJson(e.value))
        .toList();

    // Parse room polygons for drawing
    final roomVariables = htmlData.declaredVariables.entries
        .where((e) => !e.key.startsWith("slayer") && e.key != "raumbezData");
    Map<String, List<RoomPolygon>> rooms = {
      for (final roomsEntry in roomVariables)
        roomsEntry.key: RoomPolygon.fromJsonList(roomsEntry.value),
    };

    // Outline of current building
    final highlightedRoomMatch = highlightedRoomExp.firstMatch(htmlData.script);
    if (highlightedRoomMatch != null) {
      final [roomIndexString!, containingVariable!] =
          highlightedRoomMatch.groups([1, 2]);

      final roomIndex = int.parse(roomIndexString);
      // `containingVariable` describes the kinetic layer, adding "Data" gives
      // variable that actually holds the point data
      final variableName = "${containingVariable}Data";

      final roomPolygons = rooms[variableName]!;

      // Search for matching polygon, the index is a index of drawed polygons
      // One RoomPolygon contains multiple polygons so we possibly have to traverse all
      // A List<double> is a single polygon in this case
      List<List<double>> flattendPolygons =
          roomPolygons.expand((element) => element.points).toList();

      // Add new room list that only contains the highlighted polygon
      final newRoomPolygon =
          RoomPolygon(points: [flattendPolygons[roomIndex]], fill: "#ae0000");
      rooms["hightlightedRoom"] = [newRoomPolygon];
    }

    // The file name for the background image
    String pngFileName = htmlData.stringVariables["png_file_name"]!;

    return BuildingPageData(
        htmlData: htmlData,
        raumBezData: raumBezData,
        pngFileName: pngFileName,
        numberVariables: htmlData.numberVariables,
        layers: layers,
        rooms: rooms,
        buildingData: buildingInfo,
        queryParts: queryParts);
  }

  static Future<BuildingPageData> fetchQuery(String query) async {
    final queryParts = query.split("/");
    final uri = Uri.parse("$baseURL/etplan/$query");

    String? body = await fetchHMTL(uri);
    if (body == null) {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load search results');
    }

    await CampusMapData.fetch();

    // If the server did return a 200 OK response,
    // then parse the JSON.
    var roomResult = BuildingPageData.fromHTMLText(body, queryParts);

    // Start loading process for images
    roomResult.backgroundImageData = PageImageData.fetchLevelImages(
        roomResult.pngFileName, roomResult.layers);

    return roomResult;
  }

  List<RoomPolygon> getFlatRoomList() {
    return rooms.values.expand((e) => e).toList();
  }
}
