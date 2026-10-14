// Optional private integration test. TU bodies/tiles are supplied externally and
// never committed. See docs/ui-polish.md for the invocation.
import 'dart:io';
import 'package:campus_navigator/api/api_services.dart';
import 'dart:ui' as ui;
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/building/page_image_data.dart';
import 'package:campus_navigator/ui/screens/building_screen.dart';
import 'package:campus_navigator/ui/components/painter.dart';
import 'package:campus_navigator/ui/styling.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

const fixtureRoot = String.fromEnvironment('PRIVATE_PLAN_DIR');
const outputRoot = String.fromEnvironment('SCREENSHOT_DIR');

void main() {
  testWidgets('real APB E069 and BEY 318 plans, phone/tablet, light/dark',
      (tester) async {
    APIServices.Shared = APIServices.withoutCache();
    const fontRoot = String.fromEnvironment('FLUTTER_FONT_DIR');
    if (fontRoot.isNotEmpty) {
      for (final entry in [
        ('MaterialIcons', 'MaterialIcons-Regular.otf'),
        ('Roboto', 'Roboto-Regular.ttf')
      ]) {
        final font = FontLoader(entry.$1)
          ..addFont(Future.value(ByteData.sublistView(
              File('$fontRoot/${entry.$2}').readAsBytesSync())));
        await font.load();
      }
    }
    for (final sample in [
      ('APB E069', 'evidence/floorpage.body', 'apb', '00', 'E069'),
      ('BEY 318', 'bey-floor.html', 'bey', '03', '318')
    ]) {
      final body = File('$fixtureRoot/${sample.$2}').readAsStringSync();
      final identity =
          RegExp('"([0-9.]+)","${sample.$5}"').firstMatch(body)![1]!;
      for (final size in [const Size(360, 800), const Size(1280, 800)]) {
        for (final dark in [false, true]) {
          final floor = BuildingPageData.fromHTMLText(
              body, [sample.$3, sample.$4, 'raum', identity]);
          expect(floor.selectedRoom!.id, identity);
          expect(floor.selectedRoom!.name, sample.$5);
          final selectedLabel =
              floor.raumBezData.text.firstWhere((l) => l.qy == sample.$5);
          expect(
              polygonPath(floor.selectedRoom!.polygon.points.single)
                  .contains(Offset(selectedLabel.x, selectedLabel.y)),
              isTrue);
          final images = PageImageData(qualiStep: 1, imageMap: {});
          images.width = floor.subpics[0].h;
          images.height = floor.subpics[0].v;
          await tester.runAsync(() async {
            for (var x = 0; x < images.width; x++) {
              for (var y = 0; y < images.height; y++) {
                final bytes =
                    File('$fixtureRoot/${floor.pngFileName}_1_${x}_$y.png')
                        .readAsBytesSync();
                final codec = await ui.instantiateImageCodec(bytes);
                images.imageMap['${x}_$y'] = (await codec.getNextFrame()).image;
                codec.dispose();
              }
            }
          });
          floor.backgroundImageData = images;
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          final key = GlobalKey();
          await tester.pumpWidget(MaterialApp(
            theme: AppTheme.themeData(
                dark ? AppTheme.darkColorScheme : AppTheme.lightColorScheme),
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: '/plan',
            routes: {
              '/': (_) => const SizedBox.shrink(),
              '/plan': (_) => RepaintBoundary(
                  key: key,
                  child: BuildingScreen(
                      room: Future.value(floor), name: sample.$1)),
            },
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (outputRoot.isNotEmpty) {
            await tester.runAsync(() async {
              final image = await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              Directory(outputRoot).createSync(recursive: true);
              File('$outputRoot/${sample.$3}-${size.width.toInt()}-${dark ? 'dark' : 'light'}.png')
                  .writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, skip: fixtureRoot.isEmpty);
}
