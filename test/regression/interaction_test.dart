import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:campus_navigator/ui/screens/building_screen.dart';
import 'package:campus_navigator/ui/components/bottom_sheet_view.dart';
import 'package:campus_navigator/ui/components/floor_view.dart';
import 'package:campus_navigator/ui/styling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../support/floor_fixture.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'networking_test.dart' show TestCache, NetworkStorage;

class InteractionStorage extends NetworkStorage {
  @override
  Future<int> getQualityLevel() async => 1;
}

void main() {
  for (final size in [const Size(320, 720), const Size(1280, 800)]) {
    testWidgets('map, filters and information at ${size.width}',
        (tester) async {
      APIServices.Shared = APIServices.withoutCache();
      APIServices.Shared.storage.filterSet = layerFilterOptions.values.toSet();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final data = syntheticFloor();
      APIServices.Shared.cacheManager = TestCache();
      APIServices.Shared.storage = InteractionStorage();
      final paths = <String>[];
      APIServices.Shared.client = MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path.startsWith('/etplan/')) {
          return http.Response(data.htmlData.document.outerHtml, 200);
        }
        return http.Response('', 404);
      });

      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.themeData(AppTheme.lightColorScheme),
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BuildingScreen(room: Future.value(data), name: 'TEST 318')));
      await tester.pumpAndSettle();
      final viewer =
          tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      await tester.tap(find.byTooltip('Gesamte Etage'));
      await tester.pumpAndSettle();
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
      await tester.drag(find.byType(FloorView), const Offset(-50, 20));
      await tester.pumpAndSettle();
      expect(
          viewer.transformationController!.value.getTranslation().x, isNot(0));
      await tester.tap(find.byTooltip('Gesamte Etage'));
      await tester.pumpAndSettle();
      expect(viewer.transformationController!.value.getTranslation().x, 0);
      final center = tester.getCenter(find.byType(InteractiveViewer));
      final left =
          await tester.startGesture(center - const Offset(20, 0), pointer: 1);
      final right =
          await tester.startGesture(center + const Offset(20, 0), pointer: 2);
      await left.moveTo(center - const Offset(60, 0));
      await right.moveTo(center + const Offset(60, 0));
      await tester.pump();
      await left.up();
      await right.up();
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(),
          greaterThan(1));
      await tester.tap(find.text('Filter (10)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(APIServices.Shared.storage.filterSet.length, 9);
      Navigator.of(tester.element(find.byType(Checkbox).first)).pop();
      await tester.pumpAndSettle();
      if (size.width < 840) {
        expect(find.byType(DraggableBottomSheet), findsOneWidget);
        final sheet = tester.widget<DraggableScrollableSheet>(
            find.byType(DraggableScrollableSheet));
        expect(sheet.controller!.size, lessThan(0.2));
        await tester.tap(find.byType(Grabber));
        await tester.pumpAndSettle();
        expect(sheet.controller!.size, closeTo(0.55, 0.01));
        await tester.drag(find.byType(Grabber), const Offset(0, 350));
        await tester.pumpAndSettle();
        expect(sheet.controller!.size, lessThan(0.2));
      } else {
        expect(find.byType(DraggableBottomSheet), findsNothing);
      }
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Etage 01').last);
      await tester.pumpAndSettle();
      expect(paths, contains('/etplan/test/01'));
      expect(find.text('Raumbelegungsplan laden'), findsNothing);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Etage 00').last);
      await tester.pumpAndSettle();
      expect(paths, contains('/etplan/test/00/raum/test.318'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
