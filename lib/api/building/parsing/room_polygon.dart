class RoomPolygon {
  final List<List<double>> points;
  final String? fill;

  const RoomPolygon({
    required this.points,
    required this.fill,
  });

  static List<RoomPolygon> fromJsonList(Map<dynamic, dynamic> json) {
    List<dynamic> points = json["points"];

    List<List<List<double>>> points3 = points
        .map((e) => (e as List<dynamic>)
            .map((e) => (e as List<dynamic>).map((e) => e as double).toList())
            .toList())
        .toList();
    List<String?> fills =
        (json["fills"] as List<dynamic>).map((e) => e as String?).toList();

    List<RoomPolygon> rooms = [];
    for (int i = 0; i < points3.length; i++) {
      rooms.add(RoomPolygon(points: points3[i], fill: fills[i]));
    }

    return rooms;
  }
}
