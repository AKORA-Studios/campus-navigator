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
