import 'dart:convert';

import 'package:campus_navigator/api/networking.dart';

import '../../../api_services.dart';

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
    final uri = Uri.parse("$baseURL/m/json_etagen/$buildingName");
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
}

class Typen {
  final List<Rooms> rooms;
  final int typ;

  Typen({
    required this.rooms,
    required this.typ,
  });

  factory Typen.fromRawJson(String str) => Typen.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Typen.fromJson(Map<String, dynamic> json) => Typen(
        rooms: List<Rooms>.from(json["räume"].map((x) => Rooms.fromJson(x))),
        typ: json["typ"],
      );

  Map<String, dynamic> toJson() => {
        "räume": List<dynamic>.from(rooms.map((x) => x.toJson())),
        "typ": typ,
      };
}

class Rooms {
  final List<Punkt> punkte;
  final double? namey;
  final double? namex;
  final String? name;
  final String id;
  final bool list;

  Rooms({
    required this.punkte,
    this.namey,
    this.namex,
    this.name,
    required this.id,
    required this.list,
  });

  factory Rooms.fromRawJson(String str) => Rooms.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Rooms.fromJson(Map<String, dynamic> json) => Rooms(
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
