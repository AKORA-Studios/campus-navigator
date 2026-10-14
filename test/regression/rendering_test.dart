import 'dart:ui' as ui;
import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/building/page_image_data.dart';
import 'package:campus_navigator/api/building/parsing/room_polygon.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:campus_navigator/ui/components/painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/floor_fixture.dart';

void main() {
  setUp(() => APIServices.Shared = APIServices.withoutCache());
  test('room identity overrides a conflicting legacy highlight', () {
    final floor = syntheticFloor();
    expect(floor.selectedRoom!.id, 'test.318');
    expect(floor.selectedRoom!.name, '318');
    expect(floor.selectedRoom!.polygon.points.single.first, 0);
    expect(syntheticFloor(id: 'unknown').rooms['highlightedRoom'], isNull);
    expect(syntheticFloor().raumBezData.text.last.th, 0.01);
  });

  testWidgets('theme and filter snapshots repaint, unchanged inputs do not',
      (tester) async {
    final floor = syntheticFloor();
    MapPainter? previous;
    Future<MapPainter> build(Brightness brightness) async {
      late MapPainter painter;
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Builder(builder: (context) {
            painter = MapPainter(roomResult: floor, context: context);
            return CustomPaint(painter: painter);
          })));
      await tester.pumpAndSettle();
      return painter;
    }

    previous = await build(Brightness.light);
    expect((await build(Brightness.light)).shouldRepaint(previous), isFalse);
    final dark = await build(Brightness.dark);
    expect(dark.shouldRepaint(previous), isTrue);
    APIServices.Shared.storage.filterSet.remove(layerFilterOptions.Labeling);
    expect((await build(Brightness.dark)).shouldRepaint(dark), isTrue);
    APIServices.Shared.storage.filterSet = layerFilterOptions.values.toSet();
  });

  test('dark tile transform lifts black strokes and preserves transparency',
      () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 2, 2),
        Paint()
          ..colorFilter = MapPainter.darkTileFilter
          ..color = Colors.black);
    final picture = recorder.endRecording();
    final image = await picture.toImage(4, 4);
    final bytes = (await image.toByteData())!;
    expect(bytes.getUint8(0), greaterThan(220));
    expect(bytes.getUint8(3), 255);
    expect(bytes.getUint8((3 * 4 + 3) * 4 + 3), 0);
    image.dispose();
    picture.dispose();
  });

  test('empty plan bounds and odd point lists are safe', () {
    final floor = syntheticFloor();
    final empty = BuildingPageData(
        htmlData: floor.htmlData,
        raumBezData: floor.raumBezData,
        numberVariables: {},
        pngFileName: '',
        rooms: {},
        layers: [],
        subpics: [],
        buildingData: floor.buildingData,
        queryParts: []);
    expect(planBounds(empty).width, greaterThan(0));
    expect(mapPoints([1, 2, 3]), [const Offset(1, 2)]);
  });

  testWidgets('circulation fills stay inside server polygons and below walls',
      (tester) async {
    APIServices.Shared.storage.filterSet.remove(layerFilterOptions.Labeling);
    final floor = syntheticFloor();
    floor.rooms['korridorData'] = [
      const RoomPolygon(points: [
        [-80, -60, -40, -60, -40, -20, -80, -20]
      ], fill: null)
    ];
    floor.rooms['vestibulesData'] = [
      const RoomPolygon(points: [
        [-40, -60, -20, -60, -20, -20, -40, -20]
      ], fill: null)
    ];
    final rasterRecorder = ui.PictureRecorder();
    Canvas(rasterRecorder).drawRect(
        const Rect.fromLTWH(20, 40, 40, 1), Paint()..color = Colors.black);
    final rasterPicture = rasterRecorder.endRecording();
    final raster = await tester.runAsync(() => rasterPicture.toImage(200, 160));
    rasterPicture.dispose();
    floor.backgroundImageData =
        PageImageData(qualiStep: 1, imageMap: {'0_0': raster!})
          ..width = 1
          ..height = 1;
    for (final dark in [false, true]) {
      late MapPainter painter;
      await tester.pumpWidget(MaterialApp(
          theme:
              ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
          home: Builder(builder: (context) {
            painter = MapPainter(roomResult: floor, context: context);
            return const SizedBox();
          })));
      await tester.pumpAndSettle();
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(200, 160));
      final picture = recorder.endRecording();
      final image = await tester.runAsync(() => picture.toImage(200, 160));
      final bytes = (await tester.runAsync(() =>
          image!.toByteData(format: ui.ImageByteFormat.rawStraightRgba)))!;
      Color pixel(int x, int y) {
        final i = (y * 200 + x) * 4;
        return Color.fromARGB(bytes.getUint8(i + 3), bytes.getUint8(i),
            bytes.getUint8(i + 1), bytes.getUint8(i + 2));
      }

      final background = dark ? MapPainter.darkBackground : Colors.white;
      final corridor = dark ? const Color(0xff303f46) : const Color(0xffdce6e9);
      expect(pixel(40, 35), corridor);
      expect(pixel(70, 35), corridor);
      expect(pixel(10, 10), background);
      expect(pixel(90, 40), background);
      expect(pixel(40, 40), dark ? const Color(0xfff5f5f5) : Colors.black);
      image!.dispose();
      picture.dispose();
    }
    await tester.pumpWidget(const SizedBox());
    floor.backgroundImageData!.dispose();
  });

  test('raster filters retain blue details, transparency and light RGB',
      () async {
    for (final dark in [false, true]) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..colorFilter = MapPainter.tileFilter(dark, .5);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1),
          paint..color = const Color(0xff9c98f5));
      canvas.drawRect(const Rect.fromLTWH(1, 0, 1, 1),
          paint..color = const Color(0x40575757));
      canvas.drawRect(const Rect.fromLTWH(2, 0, 1, 1),
          paint..color = const Color(0x00575757));
      final picture = recorder.endRecording();
      final image = await picture.toImage(3, 1);
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;
      expect(bytes.getUint8(2), greaterThan(bytes.getUint8(0)));
      expect(bytes.getUint8(2), greaterThan(bytes.getUint8(1)));
      if (!dark) {
        expect(bytes.getUint8(0), closeTo(156, 1));
        expect(bytes.getUint8(1), closeTo(152, 1));
        expect(bytes.getUint8(2), closeTo(245, 1));
      }
      expect(bytes.getUint8(7), greaterThan(64));
      expect(bytes.getUint8(11), 0);
      image.dispose();
      picture.dispose();
    }
  });

  testWidgets('target outline stays thin as the InteractiveViewer zooms',
      (tester) async {
    APIServices.Shared.storage.filterSet.remove(layerFilterOptions.Labeling);
    final floor = syntheticFloor();
    for (final zoom in [1.0, 2.0, 3.0]) {
      final transform =
          TransformationController(Matrix4.identity()..scale(zoom));
      late MapPainter painter;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
        painter = MapPainter(
            roomResult: floor, context: context, transformation: transform);
        return const SizedBox();
      })));
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..translate(200.0, 200.0)
        ..scale(zoom)
        ..translate(-235.0, -235.0);
      painter.paint(canvas, const Size(400, 400));
      final picture = recorder.endRecording();
      final image = await tester.runAsync(() => picture.toImage(400, 400));
      final bytes = (await tester.runAsync(() => image!.toByteData()))!;
      var strokePixels = 0;
      final left = (200 - 35 * zoom).round();
      for (var x = left - 4; x <= left + 4; x++) {
        final offset = (200 * 400 + x) * 4;
        if (bytes.getUint8(offset) > 100 && bytes.getUint8(offset + 1) < 100) {
          strokePixels++;
        }
      }
      expect(strokePixels, inInclusiveRange(1, 2), reason: 'zoom $zoom');
      image!.dispose();
      picture.dispose();
      transform.dispose();
    }
  });
}
