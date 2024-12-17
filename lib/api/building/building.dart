import 'package:campus_navigator/api/BuildingData.dart';
import 'package:campus_navigator/api/BuildingLevels.dart';
import 'package:campus_navigator/api/RoomInfo.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'dart:convert';

import 'dart:async';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

import 'parsing/raum_bez_data.dart';
import 'parsing/layer_data.dart';
import 'parsing/room_polygon.dart';
import 'parsing/common.dart' as common;

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
}

class RoomPage {
  final HTMLData htmlData;
  final RaumBezData raumBezData;
  final Map<String, double> numberVariables;
  final String pngFileName;
  final List<List<RoomPolygon>> rooms;
  final List<RoomPolygon> hoersaele;
  final List<LayerData> layers;
  final BuildingData buildingData;
  PageImageData? backgroundImageData;
  final List<RoomInfo> adressInfo;

  RoomPage(
      {required this.htmlData,
      required this.raumBezData,
      required this.numberVariables,
      required this.pngFileName,
      required this.rooms,
      required this.layers,
      required this.hoersaele,
      required this.buildingData});

  factory RoomPage.fromHTMLText(String body) {
    var htmlData = HTMLData.fromBody(body);

    // Gebäude/Etagenpläne/Lehrräume
    List<BuildingLevel> buildingLevelInfo = [];
    var leftMenuParent = htmlData.document
        .querySelector("#menu_cont")
        ?.children
        .where((element) => element.localName == "ul")
        .first;
    if (leftMenuParent != null) {
      // Children: li: closed or open
      Element building = leftMenuParent.children[0];
      Element studyRooms = leftMenuParent.children[2];

      var levelPlan = leftMenuParent.children[1].children
          .where((element) => element.localName == "ul")
          .first;

      if (levelPlan != null && levelPlan.children.isNotEmpty) {
        for (Element level in levelPlan.children) {
          List<BuildingRoom> roomInfos = [];

          if (level.children.length > 1) {
            // display rooms in selected level
            for (Element room in level.children) {
              if (room.children.isNotEmpty) {
                for (Element singleRoom in room.children) {
                  roomInfos.add(BuildingRoom(singleRoom.children[0].text));
                }
              }
            }
            buildingLevelInfo.add(BuildingLevel.fromRooms(
                level.children[0].innerHtml, roomInfos));
          } else {
            // No Rooms loaded for this level
            buildingLevelInfo.add(BuildingLevel(level.children[0].innerHtml));
          }
        }
      }
    }

    // Building Info
    var rightNavBarContent =
        htmlData.document.querySelector("#menu_cont_right");
    List<RoomInfo> adressInfo = [];
    if (rightNavBarContent != null) {
      var buildingInfos =
          rightNavBarContent.children[rightNavBarContent.children.length - 2];

      List<Element> childrenGiver = buildingInfos.children;
      List<List<Element>> buildingList = [];
      while (childrenGiver.length > 8) {
        buildingList.add(childrenGiver
            .take(8)
            .where((element) => element.localName != "p")
            .toList());
        childrenGiver.removeRange(0, 8);
      }
      for (List<Element> buildingInfo in buildingList) {
        var fullTitle = buildingInfo[0].innerHtml;
        var adressInfoRoom = RoomInfo(fullTitle, buildingInfo[3].innerHtml,
            buildingInfo[1].innerHtml, buildingInfo[2].innerHtml);
        adressInfo.add(adressInfoRoom);
      }
    }

    var BuildingInfo = BuildingData(buildingLevelInfo, adressInfo);

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

    String pngFileName = stringVariables["png_file_name"] ?? "AA";

    return RoomPage(
        htmlData: htmlData,
        raumBezData: raumBezData,
        pngFileName: pngFileName,
        numberVariables: numberVariables,
        layers: layers,
        rooms: rooms,
        hoersaele: highlightedRooms,
        buildingData: BuildingInfo);
  }

  Future<void> fecthImages({int qualiIndex = 2}) async {
    final List<int> qualiSteps = [1, 2, 4, 8];
    final int qualiStep = qualiSteps[qualiIndex];

    // Prepare buffer, this is to avoid concurrency bugs during fetching
    List<Future<(String, ui.Image?)>> imageBuffer = [];

    // Background tiles
    for (int x = 0; x < qualiStep; x++) {
      for (int y = 0; y < qualiStep; y++) {
        final uri = Uri.parse(
            "https://navigator.tu-dresden.de/images/etplan_cache/${pngFileName}_$qualiStep/${x}_$y.png/nobase64");

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

    backgroundImageData =
        PageImageData(backgroundImages: imageMap, qualiStep: qualiStep);
  }

  static Future<RoomPage> fetchRoom(String query) async {
    final uri = Uri.parse('https://navigator.tu-dresden.de/etplan/' + query);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      var roomResult = RoomPage.fromHTMLText(response.body);

      // Load background image
      await roomResult.fecthImages();

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
