import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:campus_navigator/api/building/building.dart';

import 'api/building/parsing/layer.dart';

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
    // Setup correct scalign and offset so everything will fit into the given size
    Rect drawingArea = calculateDrawingArea();
    double scale = size.width / drawingArea.width;
    scale = min(scale, size.height / drawingArea.height);

    // Translate & Scale coordinate system
    canvas.scale(scale);
    canvas.translate(-drawingArea.topLeft.dx, -drawingArea.topLeft.dy);

    // Paint background image
    if (roomResult.backgroundImageData != null) {
      final imageData = roomResult.backgroundImageData!;
      int qualiStep = imageData.qualiStep;
      double qualiStepD = qualiStep.toDouble();

      double canvWidth = roomResult.numberVariables["data_canv_width"]!;
      double canvHeight = roomResult.numberVariables["data_canv_height"]!;
      double qualiSize =
          roomResult.numberVariables["subpics_size"]! / qualiStep;

      canvas.scale(1 / qualiStepD);

      for (int x = 0; x < qualiStep; x++) {
        for (int y = 0; y < qualiStep; y++) {
          var imageOffset = Offset((-0.5 * canvWidth) + (x * qualiSize),
              (-0.5 * canvHeight) + (y * qualiSize));

          final image = imageData.getImage(x, y);
          if (image == null) continue;
          canvas.drawImage(
              image, imageOffset.scale(qualiStepD, qualiStepD), Paint());
        }
      }

      canvas.scale(qualiStepD);
    }

    final strokePaint = Paint()
      ..strokeWidth = .4
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withAlpha(120);

    void drawRoom(RoomData roomData, {Color? fillColor}) {
      for (int i = 0; i < roomData.points.length; i++) {
        final pointList = roomData.points[i];
        final fill = roomData.fill;

        Color color;
        if (fillColor != null) {
          // Specially highlighted rooms
          color = fillColor;
        } else {
          // Normal rooms
          // Transparent is for some rea
          if (fill != null) {
            color = fromHex(fill);

            // Make color less aggresive
            // if (color.red == 240) color = Colors.grey;
            color = color.withAlpha(200);
          } else {
            color = Colors.transparent;
          }
        }

        final fillPaint = Paint()
          ..strokeWidth = 0
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

    for (final List<RoomData> roomList in roomResult.rooms) {
      for (final RoomData roomData in roomList) {
        drawRoom(roomData);
      }
    }

    // Highlight room
    for (final roomData in roomResult.hoersaele) {
      // drawRoom(roomData); //, fillColor: Colors.red.withAlpha(200));
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
      final offset = Offset(entry.x, entry.y);

      const width = 100.0;

      //const fontSize = 15.0;
      double fontSize = min(entry.my, entry.mx / entry.qy.length);

      final textPainter = TextPainter(
          text: TextSpan(
            text: txt,
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center);

      textPainter.layout(minWidth: width, maxWidth: width);

      // Aligning the text vertically and horizontally
      // 0.15 is because the text won't be perfectly vertically centere
      textPainter.paint(canvas,
          offset.translate(-width / 2, -((fontSize / 2) + fontSize * 0.15)));
    }
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return roomResult.htmlData != oldDelegate.roomResult.htmlData;
  }

  Rect calculateDrawingArea() {
    var allPoints = roomResult.rooms
        .expand((r) => r.expand((e) => e.points).expand(mapPoints))
        .toList();

    var minX = allPoints.fold(allPoints[0].dx,
        (previousValue, element) => min(previousValue, element.dx));

    var maxX = allPoints.fold(allPoints[0].dx,
        (previousValue, element) => max(previousValue, element.dx));

    var minY = allPoints.fold(allPoints[0].dy,
        (previousValue, element) => min(previousValue, element.dy));

    var maxY = allPoints.fold(allPoints[0].dy,
        (previousValue, element) => max(previousValue, element.dy));

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

List<Offset> mapPoints(List<double> rawPoints) {
  List<Offset> chunks = [];
  int chunkSize = 2;
  for (var i = 0; i < rawPoints.length; i += chunkSize) {
    var point = Offset(rawPoints[i], rawPoints[i + 1]);
    chunks.add(point);
  }
  return chunks;
}

List<Offset> mapPoints2(List<Position> rawPoints) {
  List<Offset> chunks = [];
  for (var i = 0; i < rawPoints.length; i++) {
    var point = Offset(rawPoints[i].x as double, rawPoints[i].y as double);
    chunks.add(point);
  }
  return chunks;
}
