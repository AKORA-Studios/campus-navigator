import 'dart:async';
import 'dart:convert';

import 'package:campus_navigator/api/building/parsing/building_data.dart';
import 'package:campus_navigator/api/networking.dart';

import '../api_services.dart';
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

/// Server identity and layer/index are kept together so a label cannot select
/// a different polygon merely because two labels overlap.
class SelectedRoom {
  final String id;
  final String name;
  final RoomPolygon polygon;
  const SelectedRoom(this.id, this.name, this.polygon);
}

class BuildingPageData {
  final HTMLData htmlData;
  final RaumBezData raumBezData;
  final Map<String, double> numberVariables;
  final String pngFileName;
  final Map<String, List<RoomPolygon>> rooms;
  final List<LayerData> layers;
  final List<({int h, int v})> subpics;
  PageImageData? backgroundImageData;
  final BuildingData buildingData;
  final List<String> queryParts;
  final SelectedRoom? selectedRoom;

  BuildingPageData(
      {this.selectedRoom,
      required this.htmlData,
      required this.raumBezData,
      required this.numberVariables,
      required this.pngFileName,
      required this.rooms,
      required this.layers,
      required this.subpics,
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

    // Resolve the exact opaque room ID through the server's layer/index map.
    // The permahighlight call is a compatibility fallback for older pages only.
    Map<String, dynamic> readServerMap(String name) {
      final match = RegExp('this\\.$name = (\\{[^;]+)', multiLine: true)
          .firstMatch(htmlData.script);
      return match == null ? {} : jsonDecode(match[1]!) as Map<String, dynamic>;
    }

    final searchHelp = readServerMap('searchhelp');
    final roomClick = readServerMap('raumclick');
    final roomPart = queryParts.indexOf('raum');
    final requestedId = roomPart >= 0 && roomPart + 1 < queryParts.length
        ? queryParts[roomPart + 1]
        : null;
    SelectedRoom? selectedRoom;
    final identity = requestedId == null ? null : searchHelp[requestedId];
    final legacy = highlightedRoomExp.firstMatch(htmlData.script);
    final layer = identity != null
        ? identity[0] as String
        : searchHelp.isEmpty && legacy != null
            ? legacy[2]
            : null;
    final index = identity != null
        ? (identity[1] as num).toInt()
        : searchHelp.isEmpty && legacy != null
            ? int.parse(legacy[1]!)
            : null;
    if (layer != null && index != null) {
      final polygons =
          rooms['${layer}Data']?.expand((room) => room.points).toList() ??
              <List<double>>[];
      final info = roomClick['$layer$index'];
      final idMatches =
          requestedId == null || info == null || info[0] == requestedId;
      if (idMatches && index >= 0 && index < polygons.length) {
        final polygon = RoomPolygon(points: [polygons[index]], fill: '#ae0000');
        rooms['highlightedRoom'] = [polygon];
        if (info != null) {
          selectedRoom =
              SelectedRoom(info[0] as String, info[1] as String, polygon);
        }
      }
    }

    // The file name for the background image
    String pngFileName = htmlData.stringVariables["png_file_name"]!;

    // Figure out which image tiles we need
    final subpicsSize = htmlData.numberVariables["subpics_size"]!;
    final qualiSteps = [1, 2, 4, 8];
    final dataCanvWidth = htmlData.numberVariables["data_canv_width"]!;
    final dataCanvHeight = htmlData.numberVariables["data_canv_height"]!;

    List<({int h, int v})> subpics = [];
    for (var i = 0; i < qualiSteps.length; i++) {
      var h = ((dataCanvWidth * qualiSteps[i].toDouble()) / subpicsSize).ceil();
      var v = ((dataCanvHeight * qualiSteps[i]) / subpicsSize).ceil();
      subpics.add((h: h, v: v));
    }

    return BuildingPageData(
        selectedRoom: selectedRoom,
        htmlData: htmlData,
        raumBezData: raumBezData,
        pngFileName: pngFileName,
        numberVariables: htmlData.numberVariables,
        layers: layers,
        subpics: subpics,
        rooms: rooms,
        buildingData: buildingInfo,
        queryParts: queryParts);
  }

  /// Only fetch and cache the initial request without parsing the actual HTML data
  /// This does not download the associated images of the page and is only used
  /// to reduce latency
  static Future<void> preFetchQuery(String query) async {
    final uri = Uri.parse("$baseURL/etplan/$query");

    String? body = await APIServices.Shared.fetchHMTL(uri);
    if (body == null) {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to pre fetch query');
    }
  }

  static Future<BuildingPageData> fetchQuery(String query) async {
    final queryParts = query.split("/");
    final uri = Uri.parse("$baseURL/etplan/$query");

    String? body = await APIServices.Shared.fetchHMTL(uri);
    if (body == null) {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load search results');
    }

    // If the server did return a 200 OK response,
    // then parse the JSON.
    var roomResult = BuildingPageData.fromHTMLText(body, queryParts);

    // Get quality index from settings
    final qualityLevel = await APIServices.Shared.storage.getQualityLevel();

    // Start loading process for images
    roomResult.backgroundImageData = PageImageData.fetchLevelImages(
        roomResult.pngFileName, roomResult.layers, roomResult.subpics,
        qualiIndex: (qualityLevel - 1), adaptive: true);

    return roomResult;
  }

  List<RoomPolygon> getFlatRoomList() {
    return rooms.values.expand((e) => e).toList();
  }
}
