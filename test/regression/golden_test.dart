import 'dart:ui' as ui;
import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/building/page_image_data.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:campus_navigator/ui/components/painter.dart';
import 'package:campus_navigator/ui/styling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/floor_fixture.dart';

void main() {
  for (final dark in [false, true]) {
    for (final size in [const Size(320, 480), const Size(960, 640)]) {
      testWidgets('synthetic architectural layers ${size.width} / $dark',
          (tester) async {
        APIServices.Shared = APIServices.withoutCache();
        APIServices.Shared.storage.filterSet =
            layerFilterOptions.values.toSet();
        final data = syntheticFloor();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
            const Rect.fromLTWH(100, 80, 35, 35),
            Paint()
              ..color = Colors.black
              ..strokeWidth = 1
              ..style = PaintingStyle.stroke);
        canvas.drawLine(const Offset(100, 80), const Offset(130, 110),
            Paint()..color = Colors.black);
        // A genuinely transparent raster tile with black architectural detail.
        final picture = recorder.endRecording();
        final image = await picture.toImage(200, 160);
        picture.dispose();
        data.backgroundImageData =
            PageImageData(qualiStep: 1, imageMap: {'0_0': image})
              ..width = 1
              ..height = 1;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        final key = GlobalKey();
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.themeData(
                dark ? AppTheme.darkColorScheme : AppTheme.lightColorScheme),
            home: Builder(
                builder: (context) => Center(
                    child: RepaintBoundary(
                        key: key,
                        child: CustomPaint(
                            size: size,
                            painter: MapPainter(
                                roomResult: data, context: context)))))));
        await tester.pumpAndSettle();
        await expectLater(
            find.byKey(key),
            matchesGoldenFile(
                'goldens/floor-${size.width.toInt()}-${dark ? 'dark' : 'light'}.png'));
        await tester.pumpWidget(const SizedBox());
        data.backgroundImageData!.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }
  }
}
