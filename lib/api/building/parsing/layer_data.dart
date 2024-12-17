/*
{symbol: [{"x":-92.48137627634475,"y":129.45925411059233}], symbolPNG: "icon_wifi.png", symbscale: 0.3, name: "WLAN AccessPoints"};
*/

import 'dart:ui';

import 'position.dart';

/// These will be definied in the JS script as something like `slayer82Data`:
///
/// ```js
/// slayer82 = new Kinetic.Layer({
///   x: canvas_width * 0.5,
///   y: canvas_height * 0.5,
///   listening: false,
///   visible: true,
///   name: "slayer82",
/// });
/// var slayer82Data = {
///   symbol: [],
///   symbolPNG: "icon_defi.png",
///   symbscale: 0.5,
///   name: "Defibrillatoren",
/// };
/// var imgObj = new Image();
/// imgObj.onload = function () {
///   for (var i = 0; i < slayer82Data.symbol.length; i++) {
///     slayer82.add(
///       new Kinetic.Image({
///         image: this,
///         x: slayer82Data.symbol[i].x,
///         y: slayer82Data.symbol[i].y,
///         offset: { x: 32, y: 32 },
///         scale: { x: slayer82Data.symbscale, y: slayer82Data.symbscale },
///         listening: false,
///       })
///     );
///   }
///   slayer82.symbscale = slayer82Data.symbscale;
///   slayer82.draw();
///   ETplan.initSymbolMouseover(slayer82);
/// };
/// imgObj.src = "images/symbols/" + slayer82Data.symbolPNG;
/// canvas.add(slayer82);
/// symbolLayers.push(slayer82);
/// symbolLayersData.push(slayer82Data);
/// ```
///
class LayerData {
  /// List of points where the layer symbol should be painted
  final List<Position> symbol;

  /// Name of the PNG file for this symbol
  final String symbolPNG;

  /// Scaling applied when drawing
  final num symbscale;

  /// Name of this layer
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
      symbscale: symbscale.toDouble(),
      name: name,
    );
  }

  static listFromJson(List<dynamic> json) {
    return json.map((jsonEntry) => LayerData.fromJson(jsonEntry)).toList();
  }

  Uri getSymbolUri() {
    return Uri.parse(
        "https://navigator.tu-dresden.de/images/symbols/$symbolPNG");
  }

  Offset getOffset() {
    return const Offset(30, 30);
  }
}
