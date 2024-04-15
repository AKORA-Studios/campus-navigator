import 'package:flutter/widgets.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

final RegExp variableDeclarationExp =
    RegExp(r"^var (\w+) = ({[^;]+)", multiLine: true);
final RegExp raumbezExp = RegExp(r"^raumbezData = ({[^;]+)", multiLine: true);
final RegExp jsObjectExp = RegExp(r"(\w+):", multiLine: true);

class RoomResult {
  final HTMLData htmlData;
  final RaumBezData raumBezData;
  final String pngFileName;
  final List<RoomData> rooms;
  final List<LayerData> layers;

  const RoomResult({
    required this.htmlData,
    required this.raumBezData,
    required this.pngFileName,
    required this.rooms,
    required this.layers,
  });

  factory RoomResult.fromHTMLText(String body) {
    var htmlData = HTMLData.fromBody(body);

    print("BCC");

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

    List<RoomData> rooms = variables.entries
        .where((e) => !e.key.startsWith("slayer"))
        .map((e) => RoomData.fromJson(e.value))
        .toList();

    String pngFileName = variables["png_file_name"] ?? 'A';

    return RoomResult(
        htmlData: htmlData,
        raumBezData: raumBezData,
        pngFileName: pngFileName,
        layers: layers,
        rooms: rooms);
  }

  NetworkImage fetchImage() {
    final url = "https://navigator.tu-dresden.de/images/etplan_cache/" +
        pngFileName +
        "_1/0_0.png/nobase64";

    return NetworkImage(url);
  }

  static Future<RoomResult> fetchRoom(String query) async {
    final uri = Uri.parse('https://navigator.tu-dresden.de/etplan/' + query);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return RoomResult.fromHTMLText(response.body);
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
  final List<List<List<double>>> points;
  final List<String?> fills;

  const RoomData({
    required this.points,
    required this.fills,
  });

  factory RoomData.fromJson(Map<dynamic, dynamic> json) {
    List<dynamic> points = json["points"];

    List<List<List<double>>> points3 = points
        .map((e) => (e as List<dynamic>)
            .map((e) => (e as List<dynamic>).map((e) => e as double).toList())
            .toList())
        .toList();
    List<String?> fills =
        (json["fills"] as List<dynamic>).map((e) => e as String?).toList();

    return RoomData(
      points: points3,
      fills: fills,
    );
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
