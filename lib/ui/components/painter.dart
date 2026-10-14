import 'dart:math';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../api/api_services.dart';
import '../../api/building/parsing/position.dart';
import '../../api/building/parsing/room_polygon.dart';

Color fromHex(String value) => Color(int.parse(
    '${value.replaceFirst('#', '').length == 6 ? 'ff' : ''}${value.replaceFirst('#', '')}',
    radix: 16));

class MapPainter extends CustomPainter {
  final BuildingPageData roomResult;
  // Snapshot all visual inputs; the old delegate must not read a mutated context
  // or the same mutable filter set when deciding whether to repaint.
  final Brightness brightness;
  final Set<layerFilterOptions> filters;
  final Color labelColor;
  final Rect drawingArea;
  final ValueListenable<Matrix4>? transformation;

  MapPainter(
      {required this.roomResult,
      required BuildContext context,
      this.transformation})
      : brightness = Theme.of(context).brightness,
        labelColor = Theme.of(context).colorScheme.onSurface,
        filters = Set.of(APIServices.Shared.storage.filterSet),
        drawingArea = planBounds(roomResult),
        super(
            repaint: Listenable.merge(
                [roomResult.backgroundImageData, transformation]));

  static const darkBackground = Color(0xff161c20);
  // Invert luminance, retain chroma: blue/violet technical details must not
  // become yellow. Transparent pixels remain transparent (no alpha offset).
  static const darkTileFilter = ColorFilter.matrix([
    .298108,
    -1.015584,
    -.102524,
    0,
    245,
    -.301892,
    -.415584,
    -.102524,
    0,
    245,
    -.301892,
    -1.015584,
    .497476,
    0,
    245,
    0,
    0,
    0,
    1,
    0,
  ]);

  static ColorFilter tileFilter(bool dark, double screenScale) {
    // Strengthen partial coverage when the original fine lines are reduced.
    // This is a GPU matrix, not per-frame CPU pixel processing/dilation.
    final alpha = 1 + (dark ? 1.2 : .8) / (1 + screenScale);
    return ColorFilter.matrix([
      if (dark) ...[
        .298108,
        -1.015584,
        -.102524,
        0,
        245,
        -.301892,
        -.415584,
        -.102524,
        0,
        245,
        -.301892,
        -1.015584,
        .497476,
        0,
        245,
      ] else ...[
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
      ],
      0,
      0,
      0,
      alpha,
      0,
    ]);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dark = brightness == Brightness.dark;
    canvas.drawColor(dark ? darkBackground : Colors.white, BlendMode.srcOver);
    final scale =
        min(size.width / drawingArea.width, size.height / drawingArea.height);
    if (!scale.isFinite || scale <= 0) return;
    final screenScale =
        scale * (transformation?.value.getMaxScaleOnAxis() ?? 1);
    canvas.save();
    canvas.translate((size.width - drawingArea.width * scale) / 2,
        (size.height - drawingArea.height * scale) / 2);
    canvas.scale(scale);
    canvas.translate(-drawingArea.left, -drawingArea.top);

    // The server supplies exact circulation polygons with a null fill. Paint
    // them beneath every room and the original raster, without inferring an
    // interior from the building's bounding box (which would fill courtyards).
    for (final layer in ['korridorData', 'vestibulesData']) {
      for (final room in roomResult.rooms[layer] ?? <RoomPolygon>[]) {
        _drawRoom(canvas, room,
            dark ? const Color(0xff303f46) : const Color(0xffdce6e9));
      }
    }
    for (final entry in roomResult.rooms.entries) {
      if (entry.key == 'highlightedRoom' ||
          entry.key == 'hightlightedRoom' ||
          entry.key == 'korridorData' ||
          entry.key == 'vestibulesData') {
        continue;
      }
      final filter = layerFilterOptions.values
          .where((f) => f.layerName == entry.key)
          .firstOrNull;
      if (filter != null && !filters.contains(filter)) continue;
      for (final room in entry.value) {
        if (room.fill == null) continue;
        final color = fromHex(room.fill!);
        _drawRoom(canvas, room,
            color.withOpacity(color.opacity * (dark ? .12 : .18)));
      }
    }
    final selected = roomResult.rooms['highlightedRoom'] ??
        roomResult.rooms['hightlightedRoom'] ??
        [];
    for (final room in selected) {
      _drawRoom(canvas, room,
          dark ? const Color(0x30ff8b6d) : const Color(0x40ed7659));
    }

    final images = roomResult.backgroundImageData;
    if (images != null) {
      final step = images.qualiStep.toDouble();
      final tileSize = roomResult.numberVariables['subpics_size']! / step;
      final origin = Offset(-roomResult.numberVariables['data_canv_width']! / 2,
          -roomResult.numberVariables['data_canv_height']! / 2);
      final paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = tileFilter(dark, screenScale);
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
              ..strokeWidth = 1.4 / screenScale
              ..color =
                  dark ? const Color(0xffffb4a0) : const Color(0xff922c18));
      }
    }
    if (filters.contains(layerFilterOptions.Labeling)) {
      _drawLabels(canvas, dark, screenScale);
    }
    canvas.restore();
  }

  void _drawRoom(Canvas canvas, RoomPolygon room, Color color) {
    for (final points in room.points) {
      canvas.drawPath(polygonPath(points), Paint()..color = color);
    }
  }

  void _drawLabels(Canvas canvas, bool dark, double screenScale) {
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
    TextPainter layout(String text, double fontSize, Color color,
        {bool halo = false}) {
      final painter = TextPainter(
          text: TextSpan(
              text: text,
              style: TextStyle(
                  fontSize: fontSize,
                  height: 1.1,
                  color: halo ? null : color,
                  foreground: halo
                      ? (Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1.2 / screenScale
                        ..color = dark ? darkBackground : Colors.white)
                      : null,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500)),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          textAlign: TextAlign.center);
      painter.layout();
      return painter;
    }

    final occupied = <Rect>[];
    final ordered = [
      if (selectedLabel != null) selectedLabel,
      ...labels.where((l) => !identical(l, selectedLabel))
    ];
    for (final label in ordered) {
      final text = label.qy.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty) continue;
      final selected = identical(label, selectedLabel);
      // Larger screen typography grows gently with zoom, bounded like the
      // website's 24px ceiling. Server extents still constrain small rooms.
      final zoom = transformation?.value.getMaxScaleOnAxis() ?? 1;
      final screenFont =
          (selected ? 18.0 : 14.0) + 2 * (zoom.clamp(1.0, 4.0) - 1);
      var font = screenFont / screenScale;
      if (label.th != null && label.th! > 0) {
        font = min(font,
            label.th! * roomResult.numberVariables['data_canv_height']! * 1.1);
      }
      final probe = layout(text, font, labelColor);
      if (label.mx > 0 && label.my > 0) {
        font *= min(1.0,
            min(label.mx * .85 / probe.width, label.my * .7 / probe.height));
      }
      probe.dispose();
      if (font <= 0 || !font.isFinite) continue;
      if (!selected && font * screenScale < 6) continue;
      final color = selected
          ? (dark ? const Color(0xffffe3da) : const Color(0xff651b0d))
          : (dark ? const Color(0xffedf1f3) : labelColor);
      final painter = layout(text, font, color);
      final origin = Offset(label.x, label.y);
      final maxShift = label.mx > 0 && label.my > 0
          ? min(12 / screenScale, min(label.mx, label.my) * .2)
          : 0.0;
      final offsets = [
        Offset.zero,
        if (!selected && maxShift > 0)
          for (final direction in [
            const Offset(0, 1),
            const Offset(0, -1),
            const Offset(1, 0),
            const Offset(-1, 0)
          ])
            direction * maxShift
      ];
      Rect? placed;
      for (final offset in offsets) {
        final rect = Rect.fromCenter(
            center: origin + offset,
            width: painter.width,
            height: painter.height);
        if (occupied.every((r) => !r.overlaps(rect.inflate(1 / screenScale)))) {
          placed = rect;
          break;
        }
      }
      if (placed != null) {
        occupied.add(placed);
        // A narrow glyph halo, never an opaque label rectangle over doors.
        final halo = layout(text, font, color, halo: true);
        halo.paint(canvas, placed.topLeft);
        halo.dispose();
        painter.paint(canvas, placed.topLeft);
      }
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) =>
      !identical(roomResult, oldDelegate.roomResult) ||
      brightness != oldDelegate.brightness ||
      labelColor != oldDelegate.labelColor ||
      transformation != oldDelegate.transformation ||
      !setEquals(filters, oldDelegate.filters);

  Rect calculateDrawingArea() => drawingArea;
}

Rect planBounds(BuildingPageData data) {
  // Include the complete tile canvas, including lines outside room polygons.
  final w = data.numberVariables['data_canv_width'] ?? 0;
  final h = data.numberVariables['data_canv_height'] ?? 0;
  if (w > 0 && h > 0) {
    return Rect.fromCenter(center: Offset.zero, width: w, height: h);
  }
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
