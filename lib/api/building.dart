import 'package:campus_navigator/api/BuildingLevels.dart';
import 'package:campus_navigator/api/roomAdress.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'dart:convert';

import 'dart:async';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

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

class BackgroundImageData {
  final int qualiStep;
  final Map<String, ui.Image> backgroundImages;

  BackgroundImageData({
    required this.qualiStep,
    required this.backgroundImages,
  });

  ui.Image? getImage(int x, int y) {
    return backgroundImages["${x}_$y"];
  }
}

class RoomResult {
  final HTMLData htmlData;
  final RaumBezData raumBezData;
  final Map<String, double> numberVariables;
  final String pngFileName;
  final List<List<RoomData>> rooms;
  final List<RoomData> hoersaele;
  final List<LayerData> layers;
  BackgroundImageData? backgroundImageData;
  final List<RoomAdress> adressInfo;

  RoomResult(
      {required this.htmlData,
      required this.raumBezData,
      required this.numberVariables,
      required this.pngFileName,
      required this.rooms,
      required this.layers,
      required this.hoersaele,
      required this.adressInfo});

  factory RoomResult.fromHTMLText(String body) {
    var htmlData = HTMLData.fromBody(body);

    var rightNavBarContent =
        htmlData.document.querySelector("#menu_cont_right");
    List<RoomAdress> adressInfo = [];
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
        var adressInfoRoom = RoomAdress(fullTitle, buildingInfo[3].innerHtml,
            buildingInfo[1].innerHtml, buildingInfo[2].innerHtml);
        adressInfo.add(adressInfoRoom);
      }
    }

    // Gebäude/Etagenpläne/Lehrräume
    List<BuildingLevel> buildingLevelInfo = [];
    var leftMenuParent = htmlData.document.querySelector("#menu_cont")?.children.where((element) => element.localName == "ul").first;
    if(leftMenuParent != null) { // Children: li: closed or open
      Element building =  leftMenuParent.children[0];
      Element studyRooms =  leftMenuParent.children[2];

      var levelPlan = leftMenuParent.children[1].children.where((element) => element.localName == "ul").first;

      if(levelPlan != null && levelPlan.children.isNotEmpty) {
          for(Element level in levelPlan.children) {
            List<BuildingRoom> roomInfos = [];

            if(level.children.length > 1) { // display rooms in selected level
              for(Element room in level.children) {
                if(room.children.isNotEmpty) {
                  for(Element singleRoom in room.children) {
                    roomInfos.add(BuildingRoom(singleRoom.children[0].text));
                  }
                }
              }
              buildingLevelInfo.add(BuildingLevel.fromRooms(level.children[0].innerHtml, roomInfos));
            } else { // No Rooms loaded for this level
              buildingLevelInfo.add(BuildingLevel(level.children[0].innerHtml));
            }
          }
      }
    }

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

    List<List<RoomData>> rooms = variables.entries
        .where((e) => !e.key.startsWith("slayer"))
        .map((e) => RoomData.fromJsonList(e.value))
        .toList();

    List<RoomData> highlightedRooms =
        RoomData.fromJsonList(variables["hoersaeleData"]);

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

    return RoomResult(
        htmlData: htmlData,
        raumBezData: raumBezData,
        pngFileName: pngFileName,
        numberVariables: numberVariables,
        layers: layers,
        rooms: rooms,
        hoersaele: highlightedRooms,
        adressInfo: adressInfo);
  }

  Future<void> fetchImage({int qualiIndex = 2}) async {
    final List<int> qualiSteps = [1, 2, 4, 8];
    final int qualiStep = qualiSteps[qualiIndex];

    List<Future<(String, ui.Image?)>> imageBuffer = [];
    for (int x = 0; x < qualiStep; x++) {
      for (int y = 0; y < qualiStep; y++) {
        final uri = Uri.parse(
            "https://navigator.tu-dresden.de/images/etplan_cache/${pngFileName}_$qualiStep/${x}_$y.png/nobase64");

        final imageFuture = http.get(uri).then((response) async {
          if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
            return ("${x}_$y", null);
          }

          final Completer<ui.Image> completer = Completer();
          ui.decodeImageFromList(response.bodyBytes, (ui.Image img) {
            return completer.complete(img);
          });

          var image = await completer.future;
          return ("${x}_$y", image);
        });

        imageBuffer.add(imageFuture);
      }
    }

    var imageList = await Future.wait(imageBuffer);

    Map<String, ui.Image> imageMap = {};
    for (final e in imageList) {
      if (e.$2 == null) continue;
      imageMap[e.$1] = e.$2!;
    }

    backgroundImageData =
        BackgroundImageData(backgroundImages: imageMap, qualiStep: qualiStep);
  }

  static Future<RoomResult> fetchRoom(String query) async {
    final uri = Uri.parse('https://navigator.tu-dresden.de/etplan/' + query);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      var roomResult = RoomResult.fromHTMLText(response.body);

      // Load background image
      await roomResult.fetchImage();

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

class RaumBezData {
  final String textFill;
  final List<RaumBezDataEntry> fills;

  const RaumBezData({
    required this.textFill,
    required this.fills,
  });

  factory RaumBezData.fromJson(Map<dynamic, dynamic> json) {
    String textFill = json["textFill"];
    List<RaumBezDataEntry> fills = (json["text"] as List<dynamic>)
        .map((e) => RaumBezDataEntry.fromJson(e))
        .toList();

    return RaumBezData(
      textFill: textFill,
      fills: fills,
    );
  }
}

class RaumBezDataEntry {
  final double x;
  final String qy;
  final double y;
  final double mx;
  final double my;
  final double? th;

  RaumBezDataEntry({
    required this.x,
    required this.qy,
    required this.y,
    required this.mx,
    required this.my,
    required this.th,
  });

  factory RaumBezDataEntry.fromJson(Map<dynamic, dynamic> json) {
    return RaumBezDataEntry(
      x: (json["x"] as num).toDouble(),
      qy: json["qy"],
      y: (json["y"] as num).toDouble(),
      mx: (json["mx"] as num).toDouble(),
      my: (json["my"] as num).toDouble(),
      th: 0, //json["th"],
    );
  }
}

class RoomData {
  final List<List<double>> points;
  final String? fill;

  const RoomData({
    required this.points,
    required this.fill,
  });

  static List<RoomData> fromJsonList(Map<dynamic, dynamic> json) {
    List<dynamic> points = json["points"];

    List<List<List<double>>> points3 = points
        .map((e) => (e as List<dynamic>)
            .map((e) => (e as List<dynamic>).map((e) => e as double).toList())
            .toList())
        .toList();
    List<String?> fills =
        (json["fills"] as List<dynamic>).map((e) => e as String?).toList();

    List<RoomData> rooms = [];
    for (int i = 0; i < points3.length; i++) {
      rooms.add(RoomData(points: points3[i], fill: fills[i]));
    }

    return rooms;
  }
}

class Position {
  final num x;
  final num y;

  const Position({
    required this.x,
    required this.y,
  });

  factory Position.fromJson(Map<dynamic, dynamic> json) {
    num x = json["x"];
    num y = json["y"];

    return Position(
      x: x,
      y: y,
    );
  }

  static List<Position> listFromJson(List<dynamic> json) {
    return json.map((jsonEntry) => Position.fromJson(jsonEntry)).toList();
  }
}

/*
{symbol: [{"x":-92.48137627634475,"y":129.45925411059233}], symbolPNG: "icon_wifi.png", symbscale: 0.3, name: "WLAN AccessPoints"};
*/

class LayerData {
  final List<Position> symbol;
  final String symbolPNG;
  final num symbscale;
  final String name;

  const LayerData({
    required this.symbol,
    required this.symbolPNG,
    required this.symbscale,
    required this.name,
  });

  factory LayerData.fromJson(Map<dynamic, dynamic> json) {
    List<Position> symbol = Position.listFromJson(json["symbol"]);
    String symbolPNG = json["symbolPNG"];
    num symbscale = json["symbscale"];
    String name = json["name"];

    return LayerData(
      symbol: symbol,
      symbolPNG: symbolPNG,
      symbscale: symbscale,
      name: name,
    );
  }

  static listFromJson(List<dynamic> json) {
    return json.map((jsonEntry) => LayerData.fromJson(jsonEntry)).toList();
  }
}
