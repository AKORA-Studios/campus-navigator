import 'dart:convert';

class FreeroomSearchResult {
  final List<String> rooms;
  final Map<String, HtwRoominfo> htwRoominfo;
  final List<List<int>> htwTaken;
  final List<String> htwRooms;
  final List<List<int>> taken;
  final Map<String, Roominfo> roominfo;

  FreeroomSearchResult({
    required this.rooms,
    required this.htwRoominfo,
    required this.htwTaken,
    required this.htwRooms,
    required this.taken,
    required this.roominfo,
  });

  /// Returns a row list representation of the free rooms
  /// Each row is a day from monday to friday
  /// Each column is a DS
  /// Each entry in a cell is a free room
  ///
  /// Based on `Huefm.foundFreeRooms` on
  /// https://navigator.tu-dresden.de/huefm/findfreerooms
  List<List<List<String>>> toTable() {
    var curday = -1;

    List<List<List<String>>> rows = [];

    for (var i = 0; i < 45; i++) {
      //9 slots * 5 Tage
      var mod = i % 9;

      if (mod == 0) {
        curday++;

        rows.add([]);
      }

      if (rooms.isNotEmpty && mod <= 6) {
        var takenRooms = taken[i];

        List<String> cellData = [];

        for (var j = 0; j < rooms.length; j++) {
          if (!takenRooms.contains(j)) {
            cellData.add(rooms[j]);
          }
        }

        rows[curday].add(cellData);
      }
    }

    return rows;
  }

  factory FreeroomSearchResult.fromRawJson(String str) =>
      FreeroomSearchResult.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FreeroomSearchResult.fromJson(Map<String, dynamic> json) =>
      FreeroomSearchResult(
        rooms: List<String>.from(json["rooms"].map((x) => x)),
        htwRoominfo: Map.from(json["htw_roominfo"]).map((k, v) =>
            MapEntry<String, HtwRoominfo>(k, HtwRoominfo.fromJson(v))),
        htwTaken: List<List<int>>.from(
            json["htw_taken"].map((x) => List<int>.from(x.map((x) => x)))),
        htwRooms: List<String>.from(json["htw_rooms"].map((x) => x)),
        taken: List<List<int>>.from(
            json["taken"].map((x) => List<int>.from(x.map((x) => x)))),
        roominfo: Map.from(json["roominfo"])
            .map((k, v) => MapEntry<String, Roominfo>(k, Roominfo.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "rooms": List<dynamic>.from(rooms.map((x) => x)),
        "htw_roominfo": Map.from(htwRoominfo)
            .map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "htw_taken": List<dynamic>.from(
            htwTaken.map((x) => List<dynamic>.from(x.map((x) => x)))),
        "htw_rooms": List<dynamic>.from(htwRooms.map((x) => x)),
        "taken": List<dynamic>.from(
            taken.map((x) => List<dynamic>.from(x.map((x) => x)))),
        "roominfo": Map.from(roominfo)
            .map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class HtwRoominfo {
  final bool pdffile;
  final String description;
  final String equipment;
  final int capacity;

  HtwRoominfo({
    required this.pdffile,
    required this.description,
    required this.equipment,
    required this.capacity,
  });

  factory HtwRoominfo.fromRawJson(String str) =>
      HtwRoominfo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory HtwRoominfo.fromJson(Map<String, dynamic> json) => HtwRoominfo(
        pdffile: json["pdffile"],
        description: json["description"],
        equipment: json["equipment"],
        capacity: json["capacity"],
      );

  Map<String, dynamic> toJson() => {
        "pdffile": pdffile,
        "description": description,
        "equipment": equipment,
        "capacity": capacity,
      };
}

class Roominfo {
  final String equipment;
  final int capacity;

  Roominfo({
    required this.equipment,
    required this.capacity,
  });

  factory Roominfo.fromRawJson(String str) =>
      Roominfo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Roominfo.fromJson(Map<String, dynamic> json) => Roominfo(
        equipment: json["equipment"],
        capacity: json["capacity"],
      );

  Map<String, dynamic> toJson() => {
        "equipment": equipment,
        "capacity": capacity,
      };
}
