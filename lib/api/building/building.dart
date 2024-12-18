import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:campus_navigator/api/building/parsing/building_data.dart';
import 'package:campus_navigator/api/building/parsing/common.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

import 'parsing/common.dart' as common;
import 'parsing/layer_data.dart';
import 'parsing/raum_bez_data.dart';
import 'parsing/room_polygon.dart';

// Matches variables that define a json object
final RegExp variableDeclarationExp =
    RegExp(r"^var (\w+) = ({[^;]+)", multiLine: true);
final RegExp raumbezExp = RegExp(r"^raumbezData = ({[^;]+)", multiLine: true);
final RegExp jsObjectExp = RegExp(r"(\w+):", multiLine: true);

final RegExp pngFileNameExp =
    RegExp(r'var png_file_name = "(\w+)";', multiLine: true);

final RegExp stringVariableExp =
    RegExp(r'var ([\w_]+) = "(\w+)";', multiLine: true);

final RegExp numberVariableExp =
    RegExp(r'(var)? ([\w_]+) = (\d+);', multiLine: true);

class PageImageData {
  final int qualiStep;
  final Map<String, ui.Image> backgroundImages;

  PageImageData({
    required this.qualiStep,
    required this.backgroundImages,
  });

  ui.Image? getLayerSymbol(String symbolName) {
    return backgroundImages[symbolName];
  }

  ui.Image? getBackgroundImage(int x, int y) {
    return backgroundImages["${x}_$y"];
  }

  /// Fetches all images for a floor plan given the `pngFileName` of
  /// the current page and all it's layers(needed for fetching of the symbolds)
  static Future<PageImageData> fetchLevelImages(
      String pngFileName, List<LayerData> layers,
      {int qualiIndex = 2}) async {
    final List<int> qualiSteps = [1, 2, 4, 8];
    final int qualiStep = qualiSteps[qualiIndex];

    // Prepare buffer, this is to avoid concurrency bugs during fetching
    List<Future<(String, ui.Image?)>> imageBuffer = [];

    // Background tiles
    for (int x = 0; x < qualiStep; x++) {
      for (int y = 0; y < qualiStep; y++) {
        final uri = Uri.parse(
            "$baseURL/images/etplan_cache/${pngFileName}_$qualiStep/${x}_$y.png/nobase64");

        final imageFuture =
            common.fetchImage(uri).then((image) => ("${x}_$y", image));

        imageBuffer.add(imageFuture);
      }
    }

    // Layer symbols
    for (final layer in layers) {
      final imageFuture = common
          .fetchImage(layer.getSymbolUri())
          .then((image) => (layer.symbolPNG, image));

      imageBuffer.add(imageFuture);
    }

    var imageList = await Future.wait(imageBuffer);

    Map<String, ui.Image> imageMap = {};
    for (final e in imageList) {
      if (e.$2 == null) continue;
      imageMap[e.$1] = e.$2!;
    }

    return PageImageData(backgroundImages: imageMap, qualiStep: qualiStep);
  }
}

class RoomPage {
  final HTMLData htmlData;
  final RaumBezData raumBezData;
  final Map<String, double> numberVariables;
  final String pngFileName;
  final List<List<RoomPolygon>> rooms;
  final List<RoomPolygon> hoersaele;
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
      required this.hoersaele,
      required this.buildingData,
      required this.queryParts});

  factory RoomPage.fromHTMLText(String body, List<String> queryParts) {
    var htmlData = HTMLData.fromBody(body);

    var buildingInfo = BuildingData.fromHTMLDocument(htmlData.document);

    final raumBezMatch = raumbezExp.firstMatch(htmlData.script)!;
    final json = jsonDecode(raumBezMatch[1]!);
    RaumBezData raumBezData = RaumBezData.fromJson(json);

    var matches = variableDeclarationExp.allMatches(htmlData.script);
    Map<String, dynamic> variables = {};
    for (final Match m in matches) {
      String varName = m[1]!;
      String varValue =
          m[2]!.replaceAllMapped(jsObjectExp, (m) => '"' + m[1]! + '":');
      var json = jsonDecode(varValue);

      variables[varName] = json;
    }

    List<LayerData> layers = variables.entries
        .where((e) => e.key.startsWith("slayer"))
        .map((e) => LayerData.fromJson(e.value))
        .toList();

    List<List<RoomPolygon>> rooms = variables.entries
        .where((e) => !e.key.startsWith("slayer"))
        .map((e) => RoomPolygon.fromJsonList(e.value))
        .toList();

    List<RoomPolygon> highlightedRooms =
        RoomPolygon.fromJsonList(variables["hoersaeleData"]);

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

    String pngFileName = stringVariables["png_file_name"]!;

    return RoomPage(
        htmlData: htmlData,
        raumBezData: raumBezData,
        pngFileName: pngFileName,
        numberVariables: numberVariables,
        layers: layers,
        rooms: rooms,
        hoersaele: highlightedRooms,
        buildingData: buildingInfo,
        queryParts: queryParts);
  }

  static Future<RoomPage> fetchRoom(String query) async {
    final uri = Uri.parse("${baseURL}/etplan/$query");

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      var roomResult = RoomPage.fromHTMLText(response.body, query.split("/"));

      // Load background image
      roomResult.backgroundImageData = await PageImageData.fetchLevelImages(
          roomResult.pngFileName, roomResult.layers);

      return roomResult;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load search results');
    }
  }
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
