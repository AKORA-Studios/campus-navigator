/*
{symbol: [{"x":-92.48137627634475,"y":129.45925411059233}], symbolPNG: "icon_wifi.png", symbscale: 0.3, name: "WLAN AccessPoints"};
*/

import 'points.dart';

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
