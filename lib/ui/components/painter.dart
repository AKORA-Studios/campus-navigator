import 'dart:math';

import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:flutter/material.dart';
import 'package:maps_toolkit/maps_toolkit.dart';

import '../../api/api_services.dart';
import '../../api/building/parsing/layer_data.dart';
import '../../api/building/parsing/position.dart';

// https://stackoverflow.com/questions/55147586/flutter-convert-color-to-hex-string
Color fromHex(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class MapPainter extends CustomPainter {
  final BuildContext context;
  final BuildingPageData roomResult;
  String? highlightedRoomIdentifier;

  Offset? mousePos;

  MapPainter({
    required this.context,
    required this.roomResult,
    this.highlightedRoomIdentifier,
  }) : super(repaint: roomResult.backgroundImageData);

  @override
  void paint(Canvas canvas, Size size) {
    // Setup correct scaling and offset so everything will fit into the given size
    Rect drawingArea = calculateDrawingArea();
    double scale = size.width / drawingArea.width;
    scale = min(scale, size.height / drawingArea.height);

    // Translate & Scale coordinate system
    final translateX = -drawingArea.topLeft.dx;
    final translateY = -drawingArea.topLeft.dy;

    final transformationMatrix = Matrix4.identity().scaled(scale);
    transformationMatrix.translate(translateX, translateY);

    // Use local transform matrix because canvas.getTransform()
    // also includes transforms outside of our custom transform
    final inverseTransform = Matrix4.identity();
    inverseTransform.copyInverse(transformationMatrix);
    final inverseMousePos = mousePos != null
        ? MatrixUtils.transformPoint(inverseTransform, mousePos!)
        : null;

    // canvas.scale(scale);
    // canvas.translate(translateX, translateY);
    canvas.transform(transformationMatrix.storage);

    // Adjust paints according to current theme
    final theme = Theme.of(context);
    final darkModeEnabled = theme.brightness == Brightness.dark;

    final currentLevelName =
        roomResult.buildingData.getCurrentLevel()!.name.trim();
    final currentLevel =
        roomResult.jsonEtagen.firstWhere((e) => e.etage == currentLevelName);
    final fillColors = currentLevel.roomFills();

    for (final roomType in currentLevel.typen) {
      // hide/show filtered roomColors
      final canBeFiltered =
          LayerFilterOptions.values.any((opt) => opt.id == roomType.typ);

      final shouldDisplay = APIServices.Shared.storage.filterSet
          .any((element) => element.id == roomType.typ);

      final fillColor = fillColors.containsKey(roomType.typ)
          ? fromHex(fillColors[roomType.typ]!)
          : Colors.transparent;
      Color color =
          (canBeFiltered && !shouldDisplay) ? Colors.transparent : fillColor;

      for (final room in roomType.rooms) {
        final mapped = room.mappedPoints();

        // Make color less aggressive
        color = color.withAlpha(darkModeEnabled ? 50 : 100);

        // Check if this is the highlighted room
        final isHighligthed =
            highlightedRoomIdentifier?.endsWith(room.id.replaceAll("U", "-")) ??
                false;

        final fillPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = isHighligthed ? Colors.green : color;

        final strokePaint = Paint()
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..color = Colors.red;

        final path = Path();
        if (mapped.isNotEmpty) {
          path.moveTo(mapped[0].dx, mapped[0].dy);

          for (final p in mapped.skip(0)) {
            path.lineTo(p.dx, p.dy);
          }
        }

        canvas.drawPath(path, fillPaint);

        // Mouse hover
        if (inverseMousePos != null) {
          if (path.contains(inverseMousePos)) {
            path.close();
            canvas.drawPath(path, strokePaint);
          }
        }

        // Beschriftungen
        if (APIServices.Shared.storage.filterSet
            .contains(LayerFilterOptions.Labeling)) {
          final polygonArea = calculateDrawingArea(points: mapped);

          if (room.name == null) break;

          final txt = room.name!;

          final offset = Offset(room.namex!, room.namey!);

          const width = 1000.0;

          double fontSize =
              min(polygonArea.height, polygonArea.width / txt.length);

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
          textPainter.paint(
              canvas,
              offset.translate(
                  -width / 2, -((fontSize / 2) + fontSize * 0.15)));
        }
      }
    }

    // Draw mouse
    if (inverseMousePos != null) {
      canvas.drawCircle(inverseMousePos, 3.0, Paint()..color = Colors.green);
      canvas.drawCircle(inverseMousePos, 2.0, Paint()..color = Colors.red);
    }

    // Invert symbols (black -> white) when using dark theme
    var symbolPaint = Paint()..invertColors = darkModeEnabled;

    // Symbols
    final xOff = currentLevel.maxX * 0.5;
    final yOff = currentLevel.maxY * 0.5;

    canvas.translate(xOff, yOff);
    for (final LayerData l in roomResult.layers) {
      // hides/shows symbol icons due to filters

      if (!APIServices.Shared.storage.filterSet
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
    canvas.translate(-xOff, -yOff);

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

      double qualiSize =
          roomResult.numberVariables["subpics_size"]! / qualiStep;

      canvas.scale(1 / qualiStepD);

      for (int x = 0; x < imageData.width; x++) {
        for (int y = 0; y < imageData.height; y++) {
          var imageOffset = Offset((x * qualiSize), (y * qualiSize));

          final image = imageData.getBackgroundImage(x, y);
          if (image == null) continue;
          canvas.drawImage(
              image, imageOffset.scale(qualiStepD, qualiStepD), imagePaint);
        }
      }

      canvas.scale(qualiStepD);
    }
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    final newHtmlData = roomResult.htmlData != oldDelegate.roomResult.htmlData;
    final newImages = roomResult.backgroundImageData?.imageMap !=
        roomResult.backgroundImageData?.imageMap;
    return newHtmlData || newImages;
  }

  Rect calculateDrawingArea({List<Offset>? points}) {
    final allPoints = points ??
        roomResult.jsonEtagen
            .expand((e) => e.typen)
            .expand((r) => r.rooms)
            .expand((r) => r.mappedPoints())
            .toList();

    final minX = allPoints.fold(allPoints[0].dx,
        (previousValue, element) => min(previousValue, element.dx));

    final maxX = allPoints.fold(allPoints[0].dx,
        (previousValue, element) => max(previousValue, element.dx));

    final minY = allPoints.fold(allPoints[0].dy,
        (previousValue, element) => min(previousValue, element.dy));

    final maxY = allPoints.fold(allPoints[0].dy,
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

extension ToLatLng on Offset {
  LatLng toCoords() {
    return LatLng(dx, dy);
  }
}
