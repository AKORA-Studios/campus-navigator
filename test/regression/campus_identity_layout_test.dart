import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/ui/components/floor_view.dart';
import 'package:campus_navigator/ui/screens/building_screen.dart';
import 'package:campus_navigator/ui/styling.dart';
import 'package:campus_navigator/api/saved_places.dart';
import 'package:campus_navigator/ui/campus_identity.dart';
import 'package:campus_navigator/ui/screens/search_screen.dart';
import 'package:campus_navigator/ui/search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'saved_places_test.dart' show MemoryPlaces, room;
import '../support/floor_fixture.dart';
import 'package:campus_navigator/ui/components/occupancyTableView.dart';
import 'package:campus_navigator/api/building/roomOccupancyPlan.dart';
import 'package:campus_navigator/ui/components/bottom_sheet_view.dart';
import 'campus_map_widget_test.dart'
    show fixtureCatalog, TestCampusTiles, choose;
import 'package:campus_navigator/ui/screens/home_screen.dart';
import 'package:flutter_map/flutter_map.dart';

Widget layoutApp(Widget home, {double scale = 1}) => MaterialApp(
    locale: const Locale('de'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: CampusIdentity.themeData(Brightness.light),
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!),
    home: home);

void main() {
  testWidgets('compact hub does not reserve button space in a passive heading',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final places = MemoryPlaces().create();
    await places.toggle(room('bey', '111103.5220', name: 'BEY 318'));
    final search = RoomSearchController(prefetch: false);
    await tester
        .pumpWidget(layoutApp(SearchScreen(places: places, search: search)));
    await tester.pumpAndSettle();
    final heading = tester.getRect(find.text('Favoriten'));
    final row = tester.getRect(
        find.byKey(const ValueKey('place-favorite-room:bey:111103.5220')));
    expect(row.top - heading.top, lessThanOrEqualTo(28));
    await tester.pumpWidget(const SizedBox());
    places.dispose();
    search.dispose();
  });
  testWidgets('selected building keeps all map tools inside a rotated phone',
      (tester) async {
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = fixtureCatalog();
    final places = MemoryPlaces().create();
    final search = RoomSearchController(prefetch: false);
    await tester.pumpWidget(layoutApp(HomeScreen(
        catalog: catalog,
        tiles: TestCampusTiles(),
        places: places,
        search: search)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campuskarte'));
    await tester.pumpAndSettle();
    await choose(tester, 'APB');
    final map = tester.getRect(find.byType(FlutterMap));
    final l = AppLocalizations.of(
        tester.element(find.byKey(const ValueKey('campus-search'))))!;
    for (final label in [
      l.mapShowCampus,
      l.mapLocate,
      l.mapZoomIn,
      l.mapZoomOut
    ]) {
      final button = find.byTooltip(label);
      expect(button, findsOneWidget);
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(map.bottom));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
    places.dispose();
    search.dispose();
  });
  testWidgets('rotated building details can scroll to floor and route actions',
      (tester) async {
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = fixtureCatalog();
    final places = MemoryPlaces().create();
    final search = RoomSearchController(prefetch: false);
    await tester.pumpWidget(layoutApp(HomeScreen(
        catalog: catalog,
        tiles: TestCampusTiles(),
        places: places,
        search: search)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campuskarte'));
    await tester.pumpAndSettle();
    await choose(tester, 'APB');
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -140));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('campus-open-floor')).hitTestable(),
        findsOneWidget);
    expect(find.byKey(const ValueKey('campus-route')).hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
    places.dispose();
    search.dispose();
  });
  testWidgets('portrait tablet collapsed sheet reserves exactly its header',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(layoutApp(BuildingScreen(
        room: Future.value(syntheticFloor()), name: 'TEST 318')));
    await tester.pumpAndSettle();
    final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet));
    final region = tester.getSize(find.byType(DraggableBottomSheet)).height;
    expect(sheet.controller!.size * region, closeTo(64, 1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('occupancy preserves server headings and accepts four tables',
      (tester) async {
    final original = List<String>.of(RoomOccupancyPlan.tableNames);
    addTearDown(() => RoomOccupancyPlan.tableNames = original);
    RoomOccupancyPlan.tableNames = ['KW 43', 'KW 44', 'KW 45', 'KW 46'];
    final tables = List.generate(
        4,
        (_) => [
              ['Time', 'Mo'],
              ['09:00', 'Lecture']
            ]);
    await tester.pumpWidget(layoutApp(Builder(
        builder: (context) =>
            occupancyTableView(tables, true, context: context))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('KW 46'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'redundant server room path stays available without repeating in the row',
      (tester) async {
    final places = MemoryPlaces().create();
    await places.toggle(SavedPlace(
        kind: PlaceKind.room,
        identifier: 'apb/00/raum/542100.2860',
        name: 'APB E069',
        subName: 'APB/E069/P'));
    final search = RoomSearchController(prefetch: false);
    await tester
        .pumpWidget(layoutApp(SearchScreen(places: places, search: search)));
    await tester.pumpAndSettle();
    expect(find.text('APB · Etage 00'), findsOneWidget);
    expect(find.byTooltip('APB/E069/P'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    places.dispose();
    search.dispose();
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('floor keeps its drawing palette and fits at text scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(layoutApp(
          BuildingScreen(room: Future.value(syntheticFloor()), name: 'BEY/318'),
          scale: scale));
      await tester.pumpAndSettle();
      final floor = tester.element(find.byType(FloorView));
      expect(Theme.of(floor).colorScheme.primary,
          AppTheme.lightColorScheme.primary,
          reason:
              'The Campus UI palette must not alter architectural drawings.');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('search action status stays inside a compact phone viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final places = MemoryPlaces().create();
    final search = RoomSearchController(prefetch: false);
    await tester
        .pumpWidget(layoutApp(SearchScreen(places: places, search: search)));
    await tester.pumpAndSettle();
    for (final badge in find.byType(Badge).evaluate()) {
      final labels = find.descendant(
          of: find.byWidget(badge.widget), matching: find.byType(Text));
      for (final label in labels.evaluate()) {
        expect(tester.getRect(find.byWidget(label.widget)).right,
            lessThanOrEqualTo(320),
            reason: 'Development status must be readable inside the screen.');
      }
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    places.dispose();
    search.dispose();
  });

  testWidgets(
      'many favorites remain scrollable and the final room opens at large text size',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final places = MemoryPlaces().create();
    await places.load();
    for (var index = 0; index < 25; index++) {
      await places.toggle(room('bey', 'room.$index'));
    }
    final search = RoomSearchController(prefetch: false);
    String? opened;
    await tester.pumpWidget(layoutApp(
        SearchScreen(
          places: places,
          search: search,
          loadPlace: (place) {
            opened = place.identifier;
            return Future<BuildingPageData>.error(
                const FormatException('Test transport unavailable'));
          },
        ),
        scale: 2));
    await tester.pumpAndSettle();
    final finalRoom =
        find.byKey(const ValueKey('place-favorite-room:bey:room.24'));
    await tester.scrollUntilVisible(finalRoom, 400,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.tap(finalRoom);
    await tester.pumpAndSettle();
    expect(opened, 'bey/03/raum/room.24');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    places.dispose();
    search.dispose();
  });
}
