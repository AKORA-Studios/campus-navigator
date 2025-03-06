import 'dart:convert';
import 'dart:ui';

import 'package:campus_navigator/api/networking.dart';

import '../../../api_services.dart';
import '../room_polygon.dart';

class JsonEtage {
  final String etage;
  final double maxY;
  final double maxX;
  final String raumf;
  final List<Typen> typen;

  JsonEtage({
    required this.etage,
    required this.maxY,
    required this.maxX,
    required this.raumf,
    required this.typen,
  });

  factory JsonEtage.fromRawJson(String str) =>
      JsonEtage.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory JsonEtage.fromJson(Map<String, dynamic> json) => JsonEtage(
        etage: json["etage"],
        maxY: json["maxY"]?.toDouble(),
        maxX: json["maxX"]?.toDouble(),
        raumf: json["raumf"],
        typen: List<Typen>.from(json["typen"].map((x) => Typen.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "etage": etage,
        "maxY": maxY,
        "maxX": maxX,
        "raumf": raumf,
        "typen": List<dynamic>.from(typen.map((x) => x.toJson())),
      };

  static Future<List<JsonEtage>?> queryBuilding(String buildingName) async {
    final uri = Uri.parse("$baseURL/m/json_etagen/hsz");
    String? body = await APIServices.Shared.cachedStringRequest(uri);
    if (body == null) return null;

    final jsonData = json.decode(body);

    if (jsonData is Map) {
      final error = jsonData["error"];
      print("JsonEtagen.queryBuilding: $error");
      return null;
    }

    return (jsonData as List<dynamic>)
        .map((d) => JsonEtage.fromJson(d))
        .toList();
  }

  Map<int, String> roomFills() {
    // "1:#575757|2:#dbd8db|4:#8…7|27:#a0accd|29:#f0f0f0"
    final Map<int, String> fillMap = {};
    for (final f in raumf.split("|")) {
      final parts = f.split(":");

      final roomType = int.parse(parts[0]);
      final hexString = parts[1];
      fillMap[roomType] = hexString;
    }

    return fillMap;
  }
}

class Typen {
  final List<Room> rooms;
  final int typ;

  Typen({
    required this.rooms,
    required this.typ,
  });

  factory Typen.fromRawJson(String str) => Typen.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Typen.fromJson(Map<String, dynamic> json) => Typen(
        rooms: List<Room>.from(json["räume"].map((x) => Room.fromJson(x))),
        typ: json["typ"],
      );

  Map<String, dynamic> toJson() => {
        "räume": List<dynamic>.from(rooms.map((x) => x.toJson())),
        "typ": typ,
      };
}

class Room {
  final List<Punkt> punkte;
  final double? namey;
  final double? namex;
  final String? name;
  final String id;
  final bool list;

  Room({
    required this.punkte,
    this.namey,
    this.namex,
    this.name,
    required this.id,
    required this.list,
  });

  factory Room.fromRawJson(String str) => Room.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        punkte: List<Punkt>.from(json["punkte"].map((x) => Punkt.fromJson(x))),
        namey: json["namey"]?.toDouble(),
        namex: json["namex"]?.toDouble(),
        name: json["name"],
        id: json["id"],
        list: json["list"],
      );

  Map<String, dynamic> toJson() => {
        "punkte": List<dynamic>.from(punkte.map((x) => x.toJson())),
        "namey": namey,
        "namex": namex,
        "name": name,
        "id": id,
        "list": list,
      };

  RoomPolygon toPoly() {
    return RoomPolygon(fill: null, points: [
      punkte.expand((e) => [e.x, e.y]).toList()
    ]);
  }

  List<Offset> mappedPoints() {
    return punkte.map((p) => Offset(p.x, p.y)).toList();
  }
}

class Punkt {
  final double x;
  final double y;

  Punkt({
    required this.x,
    required this.y,
  });

  factory Punkt.fromRawJson(String str) => Punkt.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Punkt.fromJson(Map<String, dynamic> json) => Punkt(
        x: json["x"]?.toDouble(),
        y: json["y"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "x": x,
        "y": y,
      };
}
