// Frozen 37d4d68 drawing logic for QA; only class/import paths were adapted.
// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:math';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/building/parsing/position.dart';
import 'package:campus_navigator/api/building/parsing/room_polygon.dart';

Color fromHex(String value) => Color(int.parse(
    '${value.replaceFirst('#', '').length == 6 ? 'ff' : ''}${value.replaceFirst('#', '')}',
    radix: 16));

class BaselineMapPainter extends CustomPainter {
  final BuildingPageData roomResult;
  // Snapshot all visual inputs; the old delegate must not read a mutated context
  // or the same mutable filter set when deciding whether to repaint.
  final Brightness brightness;
  final Set<layerFilterOptions> filters;
  final Color labelColor;
  final Rect drawingArea;

  BaselineMapPainter({required this.roomResult, required BuildContext context})
      : brightness = Theme.of(context).brightness,
        labelColor = Theme.of(context).colorScheme.onSurface,
        filters = Set.of(APIServices.Shared.storage.filterSet),
        drawingArea = planBounds(roomResult),
        super(repaint: roomResult.backgroundImageData);

  static const darkBackground = Color(0xff161c20);
  // Invert RGB with a restrained luminance range. Preserve alpha: the plans
  // contain transparent space which must stay transparent over room fills.
  static const darkTileFilter = ColorFilter.matrix([
    -0.82,
    0,
    0,
    0,
    235,
    0,
    -0.82,
    0,
    0,
    239,
    0,
    0,
    -0.82,
    0,
    242,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    final dark = brightness == Brightness.dark;
    canvas.drawColor(dark ? darkBackground : Colors.white, BlendMode.srcOver);
    final scale =
        min(size.width / drawingArea.width, size.height / drawingArea.height);
    if (!scale.isFinite || scale <= 0) return;
    canvas.save();
    canvas.translate((size.width - drawingArea.width * scale) / 2,
        (size.height - drawingArea.height * scale) / 2);
    canvas.scale(scale);
    canvas.translate(-drawingArea.left, -drawingArea.top);

    for (final entry in roomResult.rooms.entries) {
      if (entry.key == 'highlightedRoom' || entry.key == 'hightlightedRoom')
        continue;
      final filter = layerFilterOptions.values
          .where((f) => f.layerName == entry.key)
          .firstOrNull;
      if (filter != null && !filters.contains(filter)) continue;
      for (final room in entry.value) {
        if (room.fill == null) continue;
        final color = fromHex(room.fill!);
        _drawRoom(canvas, room, color.withAlpha(dark ? 55 : 100));
      }
    }
    final selected = roomResult.rooms['highlightedRoom'] ??
        roomResult.rooms['hightlightedRoom'] ??
        [];
    for (final room in selected) {
      _drawRoom(canvas, room,
          dark ? const Color(0xff823e33) : const Color(0xfff5c7ba));
    }

    final images = roomResult.backgroundImageData;
    if (images != null) {
      final step = images.qualiStep.toDouble();
      final tileSize = roomResult.numberVariables['subpics_size']! / step;
      final origin = Offset(-roomResult.numberVariables['data_canv_width']! / 2,
          -roomResult.numberVariables['data_canv_height']! / 2);
      final paint = Paint()..filterQuality = FilterQuality.medium;
      if (dark) paint.colorFilter = darkTileFilter;
      for (var x = 0; x < images.width; x++) {
        for (var y = 0; y < images.height; y++) {
          final image = images.getBackgroundImage(x, y);
          if (image == null) continue;
          final offset = origin + Offset(x * tileSize, y * tileSize);
          canvas.drawImageRect(
              image,
              Rect.fromLTWH(
                  0, 0, image.width.toDouble(), image.height.toDouble()),
              Rect.fromLTWH(offset.dx, offset.dy, image.width / step,
                  image.height / step),
              paint);
        }
      }
    }
    // Symbols stay above architectural detail. Their positions are in plan
    // coordinates; scale the image only, never the coordinate origin.
    for (final layer in roomResult.layers) {
      if (!filters.any((f) => f.layerName == layer.name)) continue;
      final image = images?.getLayerSymbol(layer.symbolPNG);
      if (image == null) continue;
      final paint = Paint()..filterQuality = FilterQuality.medium;
      if (dark) paint.colorFilter = darkTileFilter;
      for (final pos in layer.symbol) {
        final point = pos.toOffset();
        canvas.drawImageRect(
            image,
            Rect.fromLTWH(
                0, 0, image.width.toDouble(), image.height.toDouble()),
            Rect.fromLTWH(
                point.dx - 32 * layer.symbscale,
                point.dy - 32 * layer.symbscale,
                image.width * layer.symbscale,
                image.height * layer.symbscale),
            paint);
      }
    }
    // A thin outline identifies the target without covering its technical lines.
    for (final room in selected) {
      for (final points in room.points) {
        canvas.drawPath(
            polygonPath(points),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5 / scale
              ..color =
                  dark ? const Color(0xffffb4a0) : const Color(0xff922c18));
      }
    }
    if (filters.contains(layerFilterOptions.Labeling))
      _drawLabels(canvas, dark);
    canvas.restore();
  }

  void _drawRoom(Canvas canvas, RoomPolygon room, Color color) {
    for (final points in room.points) {
      canvas.drawPath(polygonPath(points), Paint()..color = color);
    }
  }

  void _drawLabels(Canvas canvas, bool dark) {
    final target = roomResult.selectedRoom;
    final labels = roomResult.raumBezData.text;
    final selectedLabel = target == null
        ? null
        : labels
            .where((l) =>
                l.qy == target.name &&
                target.polygon.points
                    .any((p) => polygonPath(p).contains(Offset(l.x, l.y))))
            .firstOrNull;
    TextPainter layout(String text, double fontSize, Color color) {
      final painter = TextPainter(
          text: TextSpan(
              text: text,
              style: TextStyle(
                  fontSize: fontSize,
                  height: 1.1,
                  color: color,
                  fontFamily: 'Roboto',
                  shadows: [
                    Shadow(
                        color: dark ? darkBackground : Colors.white,
                        blurRadius: 2)
                  ])),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center);
      painter.layout();
      return painter;
    }

    Rect? targetLabelRect;
    TextPainter? targetPainter;
    if (selectedLabel != null) {
      targetPainter = layout(selectedLabel.qy, 20,
          dark ? const Color(0xffffe3da) : const Color(0xff651b0d));
      targetLabelRect = Rect.fromCenter(
          center: Offset(selectedLabel.x, selectedLabel.y),
          width: targetPainter.width + 6,
          height: targetPainter.height + 4);
    }
    for (final label in labels) {
      if (identical(label, selectedLabel) || label.qy.isEmpty) continue;
      final font = label.th != null && label.th! > 0
          ? (label.th! * roomResult.numberVariables['data_canv_height']! * 1.1)
              .clamp(1.0, 16.0)
          : min(16.0,
              min(label.my * 0.65, label.mx / max(1, label.qy.length) * 1.4));
      if (font <= 0 || !font.isFinite) continue;
      final painter =
          layout(label.qy, font, dark ? const Color(0xffedf1f3) : labelColor);
      final rect = Rect.fromCenter(
          center: Offset(label.x, label.y),
          width: painter.width,
          height: painter.height);
      // Suppress only labels that would actually overwrite the selected label.
      if (targetLabelRect != null && rect.overlaps(targetLabelRect)) continue;
      painter.paint(canvas, rect.topLeft);
      painter.dispose();
    }
    if (targetPainter != null && targetLabelRect != null) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(targetLabelRect, const Radius.circular(2)),
          Paint()
            ..color = dark ? const Color(0xff47251d) : const Color(0xffffe8e0));
      targetPainter.paint(canvas, targetLabelRect.topLeft + const Offset(3, 2));
      targetPainter.dispose();
    }
  }

  @override
  bool shouldRepaint(BaselineMapPainter old) =>
      !identical(roomResult, old.roomResult) ||
      brightness != old.brightness ||
      labelColor != old.labelColor ||
      !setEquals(filters, old.filters);

  Rect calculateDrawingArea() => drawingArea;
}

Rect planBounds(BuildingPageData data) {
  // Include the complete tile canvas, including lines outside room polygons.
  final w = data.numberVariables['data_canv_width'] ?? 0;
  final h = data.numberVariables['data_canv_height'] ?? 0;
  if (w > 0 && h > 0)
    return Rect.fromCenter(center: Offset.zero, width: w, height: h);
  final points =
      data.getFlatRoomList().expand((r) => r.points).expand(mapPoints).toList();
  if (points.isEmpty) return const Rect.fromLTWH(0, 0, 1, 1);
  return Rect.fromLTRB(
          points.map((p) => p.dx).reduce(min),
          points.map((p) => p.dy).reduce(min),
          points.map((p) => p.dx).reduce(max),
          points.map((p) => p.dy).reduce(max))
      .inflate(1);
}

Path polygonPath(List<double> points) =>
    Path()..addPolygon(mapPoints(points), true);
List<Offset> mapPoints(List<double> points) => [
      for (var i = 0; i + 1 < points.length; i += 2)
        Offset(points[i], points[i + 1])
    ];
List<Offset> mapPositions(List<Position> points) =>
    points.map((p) => p.toOffset()).toList();
