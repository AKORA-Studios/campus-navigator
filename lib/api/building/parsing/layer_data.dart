/*
{symbol: [{"x":-92.48137627634475,"y":129.45925411059233}], symbolPNG: "icon_wifi.png", symbscale: 0.3, name: "WLAN AccessPoints"};
*/

import 'dart:ui';

import 'package:campus_navigator/api/networking.dart';

import 'position.dart';

/// These will be definied in the JS script as following:
///
/// ```js
/// slayer80 = new Kinetic.Layer({
///   x: canvas_width * 0.5,
///   y: canvas_height * 0.5,
///   listening: false,
///   visible: false,
///   name: "slayer80",
/// });
/// var slayer80Data = {
///   symbol: [
///     { x: -181.03355276266677, y: 197.55803541534254 },
///     { x: -31.910623240094196, y: 203.15782430784014 },
///     { x: 85.98422898465407, y: 201.55113382391676 },
///     { x: 24.355047432202014, y: 147.20719098533277 },
///     { x: 33.55413804603768, y: -86.55052255802542 },
///     { x: -20.38025623782073, y: -30.21396848202673 },
///     { x: 86.29139040069828, y: -29.00895061908423 },
///     { x: -94.71331892050989, y: -90.14982427936351 },
///     { x: -139.07057777078597, y: -32.6082523404223 },
///     { x: -57.554663512910025, y: -32.61612827416704 },
///   ],
///   symbolPNG: "icon_wifi.png",
///   symbscale: 0.3,
///   name: "WLAN AccessPoints",
/// };
/// var imgObj = new Image();
/// imgObj.onload = function () {
///   for (var i = 0; i < slayer80Data.symbol.length; i++) {
///     slayer80.add(
///       new Kinetic.Image({
///         image: this,
///         x: slayer80Data.symbol[i].x,
///         y: slayer80Data.symbol[i].y,
///         offset: { x: 32, y: 32 },
///         scale: { x: slayer80Data.symbscale, y: slayer80Data.symbscale },
///         listening: false,
///       })
///     );
///   }
///   slayer80.symbscale = slayer80Data.symbscale;
///   slayer80.draw();
///   ETplan.initSymbolMouseover(slayer80);
/// };
/// imgObj.src = "images/symbols/" + slayer80Data.symbolPNG;
/// canvas.add(slayer80);
/// symbolLayers.push(slayer80);
/// symbolLayersData.push(slayer80Data);
/// ```
///
class LayerData {
  /// List of points where the layer symbol should be painted
  final List<Position> symbol;

  /// Name of the PNG file for this symbol
  final String symbolPNG;

  /// Scaling applied when drawing
  final double symbscale;

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
    return Uri.parse("$baseURL/images/symbols/$symbolPNG");
  }

  static const symbolOffset = Offset(30, 30);

  /// Calculates the offset meant for drawing
  List<Offset> getSymbolOffsets() {
    return symbol
        .map((pos) => (pos.toOffset() * (1 / symbscale)) - symbolOffset)
        .toList();
  }
}
