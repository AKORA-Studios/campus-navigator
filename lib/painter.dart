import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:campus_navigator/api/building.dart';

// https://stackoverflow.com/questions/55147586/flutter-convert-color-to-hex-string
Color fromHex(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

const offX = 200.0;
const offY = 200.0;
const fac = 1;

class MapPainter extends CustomPainter {
  final RoomResult roomResult;

  const MapPainter({
    required this.roomResult,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..color = Colors.white;

    for (final RoomData r in roomResult.rooms) {
      for (int i = 0; i < r.points.length; i++) {
        for (int j = 0; j < r.points[i].length; j++) {
          final pointList = r.points[i][j];
          final fill = r.fills[i];

          var color = fill != null ? fromHex(fill) : Colors.transparent;
          if (color.red == 240) {
            color = Colors.transparent;
          }
          color = color.withAlpha(50);

          final fillPaint = Paint()
            ..strokeWidth = 2
            ..style = PaintingStyle.fill
            ..color = color;

          var path = Path();
          final mapped = mapPoints(pointList);

          if (mapped.isNotEmpty) {
            path.moveTo(mapped[0].dx, mapped[0].dy);

            for (final p in mapped.skip(0)) {
              path.lineTo(p.dx, p.dy);
            }
          }
          path.close();

          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, strokePaint);
        }
      }
    }

    var symbolPaint = Paint()
      ..strokeWidth = 4
      ..color = Colors.teal;

    for (final LayerData l in roomResult.layers) {
      canvas.drawPoints(PointMode.points, mapPoints2(l.symbol), symbolPaint);
    }

    // Beschriftungen
    for (final entry in roomResult.raumBezData.fills) {
      final txt = entry.qy;
      final offset = Offset((entry.x + offX) * fac, (entry.y + offY) * fac);
      final paragraphStyle = ParagraphStyle(
          fontSize: 13, textAlign: TextAlign.center, maxLines: 10);
      final paragraphBuilder = ParagraphBuilder(paragraphStyle);
      paragraphBuilder.addText(txt);
      // paragraphBuilder.pushStyle();

      final paragraph = paragraphBuilder.build();
      const width = 100.0;
      paragraph.layout(const ParagraphConstraints(width: width));

      canvas.drawParagraph(paragraph, offset.translate(-(width / 2), 0));
    }
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return roomResult.htmlData != oldDelegate.roomResult.htmlData;
  }
}

List<Offset> mapPoints(List<double> rawPoints) {
  List<Offset> chunks = [];
  int chunkSize = 2;
  for (var i = 0; i < rawPoints.length; i += chunkSize) {
    var point =
        Offset((rawPoints[i] + offX) * fac, (rawPoints[i + 1] + offY) * fac);
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
