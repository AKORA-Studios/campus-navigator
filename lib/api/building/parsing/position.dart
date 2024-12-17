import 'dart:ui';

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

  Offset toOffset() {
    return Offset(x.toDouble(), y.toDouble());
  }
}
