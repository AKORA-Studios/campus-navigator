// Frozen original TU plans are local evidence, not distributed app assets.
import 'dart:io';
import 'dart:math';
import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/building/page_image_data.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:campus_navigator/ui/components/painter.dart';
import 'package:campus_navigator/ui/styling.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const root = String.fromEnvironment('REAL_PLAN_DIR');
const fontRoot = String.fromEnvironment('FLUTTER_FONT_DIR');
const samples = [
  ('bey00', '111100.5360', 'E25'),
  ('bey03', '111103.5220', '318'),
  ('apb00', '542100.2860', 'E069'),
];
void main() {
  setUpAll(() async {
    if (root.isEmpty || fontRoot.isEmpty) return;
    for (final name in ['roboto-regular.ttf', 'roboto-medium.ttf']) {
      final font = FontLoader('Roboto')
        ..addFont(Future.value(
            ByteData.sublistView(File('$fontRoot/$name').readAsBytesSync())));
      await font.load();
    }
  });
  for (final sample in samples) {
    for (final size in [const Size(360, 800), const Size(1280, 800)]) {
      for (final dark in [false, true]) {
        for (final zoom in [1.0, 3.0]) {
          final name =
              '${sample.$1}-${size.width.toInt()}-${dark ? 'dark' : 'light'}-${zoom == 1 ? 'fit' : 'target'}';
          testWidgets('original plan $name', (tester) async {
            APIServices.Shared = APIServices.withoutCache();
            APIServices.Shared.storage.filterSet =
                layerFilterOptions.values.toSet();
            APIServices.Shared.client = MockClient((request) async {
              final parts = request.url.pathSegments;
              final file = parts.contains('etplan_cache')
                  ? '${parts[2]}_${parts[3]}'
                  : parts.last;
              return http.Response.bytes(
                  await File('$root/$file').readAsBytes(), 200);
            });
            final floor = BuildingPageData.fromHTMLText(
                File('$root/${sample.$1}.html').readAsStringSync(), [
              sample.$1.substring(0, 3),
              sample.$1.substring(3),
              'raum',
              sample.$2
            ]);
            expect(floor.selectedRoom!.id, sample.$2);
            expect(floor.selectedRoom!.name, sample.$3);
            final label =
                floor.raumBezData.text.firstWhere((l) => l.qy == sample.$3);
            expect(
                polygonPath(floor.selectedRoom!.polygon.points.single)
                    .contains(Offset(label.x, label.y)),
                isTrue);
            final bounds = planBounds(floor);
            final fit =
                min(size.width / bounds.width, size.height / bounds.height);
            final ratio = size.width < 700 ? 3.0 : 1.5;
            final images = (await tester.runAsync(() async {
              final images = PageImageData.fetchLevelImages(
                  floor.pngFileName, floor.layers, floor.subpics,
                  adaptive: true);
              await images.loaded;
              await images.setResolutionForScale(fit * zoom * sqrt(ratio));
              return images;
            }))!;
            expect(images.failedImages, 0);
            floor.backgroundImageData = images;
            tester.view.physicalSize = size * ratio;
            tester.view.devicePixelRatio = ratio;
            final transform = TransformationController();
            final center = zoom == 1
                ? Offset.zero
                : polygonPath(floor.selectedRoom!.polygon.points.single)
                    .getBounds()
                    .center;
            final point = Offset((size.width - bounds.width * fit) / 2,
                    (size.height - bounds.height * fit) / 2) +
                (center - bounds.topLeft) * fit;
            transform.value = Matrix4.identity()
              ..translate(size.width / 2 - point.dx * zoom,
                  size.height / 2 - point.dy * zoom)
              ..scale(zoom);
            final key = GlobalKey();
            await tester.pumpWidget(MaterialApp(
                theme: AppTheme.themeData(dark
                    ? AppTheme.darkColorScheme
                    : AppTheme.lightColorScheme),
                home: Builder(
                    builder: (context) => RepaintBoundary(
                        key: key,
                        child: ClipRect(
                            child: InteractiveViewer(
                                transformationController: transform,
                                maxScale: 16,
                                boundaryMargin: const EdgeInsets.all(300),
                                child: CustomPaint(
                                    size: size,
                                    painter: MapPainter(
                                        roomResult: floor,
                                        context: context,
                                        transformation: transform))))))));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await expectLater(find.byKey(key),
                matchesGoldenFile(Uri.file('$root/goldens/$name.png')));
            await tester.pumpWidget(const SizedBox());
            transform.dispose();
            images.dispose();
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          }, skip: root.isEmpty);
        }
      }
    }
  }
  test('adjacent server room identities resolve distinct original polygons',
      () {
    for (final pair in [
      ('bey00', '111100.5360', 'E25', '111100.5370', 'E26'),
      ('bey03', '111103.5220', '318', '111103.5240', '319A')
    ]) {
      final body = File('$root/${pair.$1}.html').readAsStringSync();
      BuildingPageData parse(String id) => BuildingPageData.fromHTMLText(
          body, [pair.$1.substring(0, 3), pair.$1.substring(3), 'raum', id]);
      final a = parse(pair.$2).selectedRoom!;
      final b = parse(pair.$4).selectedRoom!;
      expect(a.name, pair.$3);
      expect(b.name, pair.$5);
      expect(a.polygon.points.single, isNot(equals(b.polygon.points.single)));
    }
  }, skip: root.isEmpty);
}
