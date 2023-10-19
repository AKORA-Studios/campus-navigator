import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_testy/api/plan.dart';

class MapPainter extends CustomPainter {
  final RoomResult roomResult;

  const MapPainter({
    required this.roomResult,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const off = 200;
    const fact = 0.5;

    var paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 3;

    for (final RoomData r in roomResult.rooms) {
      for (int i = 0; i < r.points.length; i++) {
        for (int j = 0; j < r.points[i].length; i++) {
          var pointList = r.points[i][j];
          //var fill = r.fills[i];
          canvas.drawPoints(PointMode.polygon, mapPoints(pointList), paint);
        }
      }
    }

    Offset start = Offset(0, size.height / 2);
    Offset end = Offset(size.width, size.height / 2);

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

List<Offset> mapPoints(List<double> rawPoints) {
  List<Offset> chunks = [];
  int chunkSize = 2;
  for (var i = 0; i < rawPoints.length; i += chunkSize) {
    var off = Offset(rawPoints[i], rawPoints[i + 1]);
    chunks.add(off);
  }
  return chunks;
}
