/// Used for labels, the JS object looks like this:
/// ```js
/// raumbezData = {
///   textFill: "#000000",
///   text: [
///     {
///       x: 154.90786633452012,
///       qy: "Boden1",
///       y: 141.62601685519752,
///       mx: 77.1880717424629,
///       my: 66.74358547393312,
///     },
///     {
///       th: 0.0076233079168874646,
///       x: -142.68330625398067,
///       qy: "Geb.Nr.:3251",
///       y: -226.37086864373904,
///       mx: 0,
///       my: 0,
///     },
///   ],
/// };
/// ```
class RaumBezData {
  final String textFill;
  final List<RaumBezDataEntry> text;

  const RaumBezData({
    required this.textFill,
    required this.text,
  });

  factory RaumBezData.fromJson(Map<dynamic, dynamic> json) {
    String textFill = json["textFill"];
    List<RaumBezDataEntry> text = (json["text"] as List<dynamic>)
        .map((e) => RaumBezDataEntry.fromJson(e))
        .toList();

    return RaumBezData(
      textFill: textFill,
      text: text,
    );
  }
}

/// Used for labels, the JS object looks like this:
/// ```js
/// {
///   th: 0.0076233079168874646,
///   x: -142.68330625398067,
///   qy: "Geb.Nr.:3251",
///   y: -226.37086864373904,
///   mx: 0,
///   my: 0,
/// },
/// ```
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
