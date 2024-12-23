import 'dart:async';
import 'dart:convert';

import 'package:campus_navigator/api/building/parsing/building_data.dart';
import 'package:campus_navigator/api/building/parsing/common.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

import 'page_image_data.dart';
import 'parsing/layer_data.dart';
import 'parsing/raum_bez_data.dart';
import 'parsing/room_polygon.dart';

/// Matches variables declarations that define a JS object
final RegExp variableDeclarationExp =
    RegExp(r"^var (\w+) = ({[^;]+)", multiLine: true);

/// Matches variables assignments that assign a JS object
final RegExp variableAssignmentsExp =
    RegExp(r"^(\w+) = ({[^;]+)", multiLine: true);

// Matches JS object attribute names
final RegExp jsObjectExp = RegExp(r'([,{\[]) *(\w+):', multiLine: true);

final RegExp raumbezExp = RegExp(r"^raumbezData = ({[^;]+)", multiLine: true);

final RegExp pngFileNameExp =
    RegExp(r'var png_file_name = "(\w+)";', multiLine: true);

final RegExp highlightedRoomExp =
    RegExp(r"ETplan\.permahighlightRaum\((\d+), (\w+)\);", multiLine: true);

final RegExp stringVariableExp =
    RegExp(r'var ([\w_]+) = "(\w+)";', multiLine: true);

final RegExp numberVariableExp =
    RegExp(r'(var)? ([\w_]+) = (\d+);', multiLine: true);

class RoomPage {
  final HTMLData htmlData;
  final RaumBezData raumBezData;
  final Map<String, double> numberVariables;
  final String pngFileName;
  final Map<String, List<RoomPolygon>> rooms;
  final List<LayerData> layers;
  PageImageData? backgroundImageData;
  final BuildingData buildingData;
  final List<String> queryParts;

  RoomPage(
      {required this.htmlData,
      required this.raumBezData,
      required this.numberVariables,
      required this.pngFileName,
      required this.rooms,
      required this.layers,
      required this.buildingData,
      required this.queryParts});

  factory RoomPage.fromHTMLText(String body, List<String> queryParts) {
    var htmlData = HTMLData.fromBody(body);

    var buildingInfo = BuildingData.fromHTMLDocument(htmlData.document);

    // Parse room labels
    final raumBezMatch = raumbezExp.firstMatch(htmlData.script)!;
    RaumBezData raumBezData =
        RaumBezData.fromJson(jsonDecode(raumBezMatch[1]!));

    // Parse all variables with JSON object like values
    Map<String, dynamic> declaredVariables =
        parseJSVariables(variableDeclarationExp, htmlData.script);

    // ignore: unused_local_variable
    Map<String, dynamic> assignedVariables =
        parseJSVariables(variableAssignmentsExp, htmlData.script);

    // Parse symbol layers
    List<LayerData> layers = declaredVariables.entries
        .where((e) => e.key.startsWith("slayer"))
        .map((e) => LayerData.fromJson(e.value))
        .toList();

    // Parse room polygons for drawing
    final roomVariables = declaredVariables.entries
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

    // String variables
    Map<String, String> stringVariables = {};
    for (final Match m in stringVariableExp.allMatches(htmlData.script)) {
      stringVariables[m[1]!] = m[2]!;
    }

    // Number variables
    Map<String, double> numberVariables = {};
    for (final Match m in numberVariableExp.allMatches(htmlData.script)) {
      var val = double.tryParse(m[3]!);
      if (val == null || numberVariables.containsKey(m[2])) continue;
      numberVariables[m[2]!] = val;
    }

    // The file name for the background image
    String pngFileName = stringVariables["png_file_name"]!;

    return RoomPage(
        htmlData: htmlData,
        raumBezData: raumBezData,
        pngFileName: pngFileName,
        numberVariables: numberVariables,
        layers: layers,
        rooms: rooms,
        buildingData: buildingInfo,
        queryParts: queryParts);
  }

  static Future<RoomPage> fetchRoom(String query) async {
    final queryParts = query.split("/");
    final uri = Uri.parse("$baseURL/etplan/$query");

    final cachedResponse =
        await DefaultCacheManager().getFileFromCache(uri.toString());

    String body;
    if (cachedResponse != null) {
      body = await cachedResponse.file.readAsString();
    } else {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        throw Exception('Failed to load search results');
      }

      body = response.body;
      // Save response in cache
      DefaultCacheManager().putFile(uri.toString(), response.bodyBytes);
    }

    // If the server did return a 200 OK response,
    // then parse the JSON.
    var roomResult = RoomPage.fromHTMLText(body, queryParts);

    // Start loading process for images
    roomResult.backgroundImageData = PageImageData.fetchLevelImages(
        roomResult.pngFileName, roomResult.layers);

    return roomResult;
  }

  List<RoomPolygon> getFlatRoomList() {
    return rooms.values.expand((e) => e).toList();
  }
}

Map<String, dynamic> parseJSVariables(RegExp regExp, String script) {
  Map<String, dynamic> declaredVariables = {};

  var matches = regExp.allMatches(script);
  for (final Match m in matches) {
    String varName = m[1]!;
    String valueJsNotation = m[2]!;

    // Convert javascript object notation to JSON object notation
    // { a: 1 }  ->  { "a": 1 }
    String valueJsonNotation =
        valueJsNotation.replaceAllMapped(jsObjectExp, (m) {
      return '${m[1]}"${m[2]!}":';
    });

    declaredVariables[varName] = jsonDecode(valueJsonNotation);
  }

  return declaredVariables;
}

class HTMLData {
  final Document document;
  final String script;

  const HTMLData({
    required this.document,
    required this.script,
  });

  factory HTMLData.fromBody(String body) {
    var document = parse(body);
    var elements = document.querySelectorAll('script[type="text/javascript"]');
    var script =
        elements.singleWhere((e) => e.innerHtml.length > 1000).innerHtml;

    return HTMLData(
      document: document,
      script: script,
    );
  }
}
