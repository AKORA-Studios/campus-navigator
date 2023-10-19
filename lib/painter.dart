import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_testy/api/plan.dart';

// https://stackoverflow.com/questions/55147586/flutter-convert-color-to-hex-string
Color fromHex(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class MapPainter extends CustomPainter {
  final RoomResult roomResult;

  const MapPainter({
    required this.roomResult,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final RoomData r in roomResult.rooms) {
      for (int i = 0; i < r.points.length; i++) {
        for (int j = 0; j < r.points[i].length; j++) {
          var pointList = r.points[i][j];

          var fill = r.fills[i];

          var paint = Paint()
            ..strokeWidth = 2
            ..color = fill != null ? fromHex(fill) : Colors.black;

          canvas.drawPoints(PointMode.polygon, mapPoints(pointList), paint);
        }
      }
    }

    var paint = Paint()
      ..strokeWidth = 4
      ..color = Colors.teal;

    for (final LayerData l in roomResult.layers) {
      canvas.drawPoints(PointMode.points, mapPoints2(l.symbol), paint);
    }
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return roomResult.htmlData != oldDelegate.roomResult.htmlData;
  }
}

List<Offset> mapPoints(List<double> rawPoints) {
  const off = 200.0;
  const fac = 1;

  List<Offset> chunks = [];
  int chunkSize = 2;
  for (var i = 0; i < rawPoints.length; i += chunkSize) {
    var point =
        Offset((rawPoints[i] + off) * fac, (rawPoints[i + 1] + off) * fac);
    chunks.add(point);
  }
  return chunks;
}

List<Offset> mapPoints2(List<Position> rawPoints) {
  const off = 200.0;
  const fac = 1;

  List<Offset> chunks = [];
  for (var i = 0; i < rawPoints.length; i++) {
    var point =
        Offset((rawPoints[i].x + off) * fac, (rawPoints[i].y + off) * fac);
    chunks.add(point);
  }
  return chunks;
}
