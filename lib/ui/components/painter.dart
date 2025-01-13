import 'dart:math';

import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:flutter/material.dart';

import '../../api/building/parsing/layer_data.dart';
import '../../api/building/parsing/position.dart';
import '../../api/building/parsing/room_polygon.dart';

// https://stackoverflow.com/questions/55147586/flutter-convert-color-to-hex-string
Color fromHex(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class MapPainter extends CustomPainter {
  final BuildingPageData roomResult;
  final BuildContext context;

  MapPainter({
    required this.roomResult,
    required this.context,
  }) : super(repaint: roomResult.backgroundImageData);

  @override
  void paint(Canvas canvas, Size size) {
    // Setup correct scaling and offset so everything will fit into the given size
    Rect drawingArea = calculateDrawingArea();
    double scale = size.width / drawingArea.width;
    scale = min(scale, size.height / drawingArea.height);

    // Translate & Scale coordinate system
    canvas.scale(scale);
    canvas.translate(-drawingArea.topLeft.dx, -drawingArea.topLeft.dy);

    // Adjust paints according to current theme
    final theme = Theme.of(context);
    final darkModeEnabled = theme.brightness == Brightness.dark;

    void drawRoom(RoomPolygon roomData, {Color? fillColor}) {
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

            // Check if this is the highlighted room
            if (color == fromHex("#ae0000")) {
              // Highlighted color is supposed to be more aggressive
              color = color.withAlpha(darkModeEnabled ? 150 : 200);
            } else {
              // Make color less aggressive
              color = color.withAlpha(darkModeEnabled ? 50 : 100);
            }
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
      }
    }

    for (final entry in roomResult.rooms.entries) {
      // hide/show filtered roomColors
      final canBeFiltered = layerFilterOptions.values
          .any((element) => element.layerName == entry.key);

      final shouldDisplay = Storage.Shared.filterSet
          .any((element) => element.layerName == entry.key);

      Color? color =
          (canBeFiltered && !shouldDisplay) ? Colors.transparent : null;

      for (final roomPolygon in entry.value) {
        drawRoom(roomPolygon, fillColor: color);
      }
    }

    // Invert symbols (black -> white) when using dark theme
    var symbolPaint = Paint()..invertColors = darkModeEnabled;

    // Symbols
    for (final LayerData l in roomResult.layers) {
      // hides/shows symbol icons due to filters

      if (!Storage.Shared.filterSet
          .any((element) => element.layerName == l.name)) {
        continue;
      }

      for (final pos in l.getSymbolOffsets()) {
        final image =
            roomResult.backgroundImageData!.getLayerSymbol(l.symbolPNG);
        if (image == null) continue;

        canvas.scale(l.symbscale);
        canvas.drawImage(image, pos, symbolPaint);
        canvas.scale(1 / l.symbscale);
      }
    }

    // Paint background image
    if (roomResult.backgroundImageData != null) {
      var imagePaint = Paint();

      // Apply color filter in dark mode so that the black lines become white
      // and orange details become blue
      if (darkModeEnabled) {
        imagePaint.colorFilter = const ColorFilter.matrix([
          0.000,
          1.000,
          1.000,
          0.000,
          0.000,
          1.000,
          0.000,
          1.000,
          0.000,
          0.000,
          1.000,
          0.000,
          1.000,
          0.000,
          0.000,
          0.000,
          0.000,
          0.000,
          1.000,
          0.000
        ]);
      }

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

          final image = imageData.getBackgroundImage(x, y);
          if (image == null) continue;
          canvas.drawImage(
              image, imageOffset.scale(qualiStepD, qualiStepD), imagePaint);
        }
      }

      canvas.scale(qualiStepD);
    }

    // Beschriftungen
    if (Storage.Shared.filterSet.contains(layerFilterOptions.Labeling)) {
      for (final entry in roomResult.raumBezData.text) {
        final txt = entry.qy;
        final offset = Offset(entry.x, entry.y);

        const width = 100.0;

        double fontSize = min(entry.my, entry.mx / entry.qy.length);

        // This is done to improve text readability over complex shapes like chairs
        Shadow textShadow;
        if (darkModeEnabled) {
          textShadow = const Shadow(color: Colors.black, blurRadius: 20.0);
        } else {
          textShadow = const Shadow(color: Colors.white, blurRadius: 10.0);
        }

        final textPainter = TextPainter(
            text: TextSpan(
              text: txt,
              style: TextStyle(
                shadows: [textShadow],
                color: darkModeEnabled
                    ? Colors.grey.shade100
                    : theme.colorScheme.onSurface,
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
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    final newHtmlData = roomResult.htmlData != oldDelegate.roomResult.htmlData;
    final newImages = roomResult.backgroundImageData?.imageMap !=
        roomResult.backgroundImageData?.imageMap;
    return newHtmlData || newImages;
  }

  Rect calculateDrawingArea() {
    var allPoints = roomResult
        .getFlatRoomList()
        .expand((r) => r.points)
        .expand(mapPoints)
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

List<Offset> mapPositions(List<Position> rawPoints) {
  return rawPoints.map((p) => p.toOffset()).toList();
}
