import 'dart:convert';
import 'dart:async';
import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/campus/campus_catalog.dart';
import 'package:campus_navigator/api/campus/campus_building.dart';
import 'package:campus_navigator/api/campus/campus_location.dart';
import 'package:campus_navigator/ui/screens/campus_map_screen.dart';
import 'package:campus_navigator/ui/screens/building_screen.dart';
import 'package:campus_navigator/ui/screens/home_screen.dart';
import 'package:campus_navigator/ui/search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import '../support/floor_fixture.dart';
import 'campus_catalog_test.dart' show campusFixture;
import 'search_favorites_widget_test.dart' show app, results;
import 'saved_places_test.dart' show MemoryPlaces, building;

class TestCampusTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

class RecordingCampusTiles extends TileProvider {
  final List<String> loaded = [];
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      RecordingCampusImage(getTileUrl(coordinates, options), loaded);
}

class RecordingCampusImage extends MemoryImage {
  final String url;
  final List<String> loaded;
  RecordingCampusImage(this.url, this.loaded)
      : super(TileProvider.transparentImage);
  @override
  Future<MemoryImage> obtainKey(ImageConfiguration configuration) {
    loaded.add(url);
    return super.obtainKey(configuration);
  }
}

CampusCatalog fixtureCatalog() => CampusCatalog(
    readCache: () async => null,
    fetch: () async => campusFixture(),
    writeCache: (_) async {});

Future<void> choose(WidgetTester tester, String code) async {
  await tester.enterText(find.byKey(const ValueKey('campus-search')), code);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('campus-result-$code')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => APIServices.Shared = APIServices.withoutCache());

  testWidgets('search zoom starts loading native detail tiles for high density',
      (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1600, 1600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = fixtureCatalog();
    final tiles = RecordingCampusTiles();
    await tester
        .pumpWidget(app(CampusMapScreen(catalog: catalog, tiles: tiles)));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    final before = tiles.loaded.length;
    await choose(tester, 'APB');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
        tiles.loaded
            .skip(before)
            .any((url) => Uri.parse(url).pathSegments.first == '19'),
        isTrue,
        reason:
            'A zoomed view must load its own native resolution, rather than keep parent tiles. Loaded: ${tiles.loaded.skip(before).toSet()}');
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
  });

  testWidgets('small phone with keyboard keeps building results usable',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final catalog = fixtureCatalog();
    await tester.pumpWidget(
        app(CampusMapScreen(catalog: catalog, tiles: TestCampusTiles())));
    await tester.pumpAndSettle();
    await choose(tester, 'APB');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.enterText(find.byKey(const ValueKey('campus-search')), 'BAR');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('campus-result-BAR')).hitTestable(),
        findsOneWidget);
    final controller =
        tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
    final before = controller.camera.center;
    await tester.tap(find.byKey(const ValueKey('campus-result-BAR')));
    await tester.pumpAndSettle();
    expect(controller.camera.center, before); // Wait for the keyboard to close.
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(controller.camera.center.latitude, inExclusiveRange(51.026, 51.028));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
  });

  testWidgets(
      'floor response after leaving campus does not open an unrelated screen',
      (tester) async {
    final catalog = fixtureCatalog();
    final pending = Completer<BuildingPageData>();
    await tester.pumpWidget(app(CampusMapScreen(
        key: const ValueKey('map'),
        catalog: catalog,
        tiles: TestCampusTiles(),
        loadFloor: (_) => pending.future)));
    await tester.pumpAndSettle();
    await choose(tester, 'APB');
    await tester.tap(find.byKey(const ValueKey('campus-open-floor')));
    await tester.pump();
    await tester.pumpWidget(app(CampusMapScreen(
        key: const ValueKey('map'),
        active: false,
        catalog: catalog,
        tiles: TestCampusTiles(),
        loadFloor: (_) => pending.future)));
    pending.complete(syntheticFloor(id: 'test.318'));
    await tester.pumpAndSettle();
    expect(find.byType(BuildingScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
  });

  testWidgets('navigation keeps favorites, room query and campus camera alive',
      (tester) async {
    final catalog = fixtureCatalog();
    final places = MemoryPlaces().create();
    await places.toggle(building);
    final search =
        RoomSearchController(search: (_) async => results(), prefetch: false);
    await tester.pumpWidget(app(HomeScreen(
        catalog: catalog,
        tiles: TestCampusTiles(),
        places: places,
        search: search)));
    await tester.pumpAndSettle();
    expect(find.text('Beyer-Bau'), findsOneWidget);
    expect(
        find.byType(FlutterMap), findsNothing); // Lazy: no tile calls on home.
    await tester.enterText(find.byType(TextField), 'BEY 318');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    await choose(tester, 'APB');
    final camera = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .camera
        .center;
    await tester.tap(find.byType(NavigationDestination).first);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'BEY 318');
    expect(places.contains(building), isTrue);
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Andreas-Pfitzmann-Bau'), findsOneWidget);
    expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .mapController!
            .camera
            .center,
        camera);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
    places.dispose();
    search.dispose();
  });

  testWidgets(
      'phone and tablet: select real APB/BAR, styles, zoom and attribution fit',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    for (final size in [const Size(320, 640), const Size(1280, 800)]) {
      tester.view.physicalSize = size;
      for (final dark in [false, true]) {
        final catalog = fixtureCatalog();
        await tester.pumpWidget(app(
            CampusMapScreen(catalog: catalog, tiles: TestCampusTiles()),
            dark: dark));
        await tester.pumpAndSettle();
        await choose(tester, 'APB');
        expect(find.text('Andreas-Pfitzmann-Bau'), findsOneWidget);
        expect(find.textContaining('Nöthnitzer Straße 46'), findsOneWidget);
        expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
        final mapBounds = tester.getRect(find.byType(FlutterMap));
        expect(mapBounds.height, greaterThan(180));
        await tester.tap(find.byTooltip('Vergrößern'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Kartenstil wechseln'));
        await tester.pumpAndSettle();
        final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
        expect(Theme.of(tester.element(find.byType(FlutterMap))).brightness,
            dark ? Brightness.light : Brightness.dark);
        expect(map.options.maxZoom, 20);
        await choose(tester, 'BAR');
        expect(find.text('Barkhausen-Bau'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        catalog.dispose();
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
      'polygon touch uses real footprint and empty ground clears selection',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = fixtureCatalog();
    await tester.pumpWidget(
        app(CampusMapScreen(catalog: catalog, tiles: TestCampusTiles())));
    await tester.pumpAndSettle();
    await choose(tester, 'APB');
    await tester.tap(find.byTooltip('Auswahl schließen'));
    await tester.pumpAndSettle();
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final p = map.mapController!.camera
        .latLngToScreenPoint(const LatLng(51.02523, 13.7231));
    await tester
        .tapAt(tester.getTopLeft(find.byType(FlutterMap)) + Offset(p.x, p.y));
    await tester
        .pump(const Duration(milliseconds: 400)); // Single vs double tap.
    await tester.pumpAndSettle();
    expect(find.text('Andreas-Pfitzmann-Bau'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    final empty = map.mapController!.camera
        .latLngToScreenPoint(const LatLng(51.02523, 13.7224));
    await tester.tapAt(
        tester.getTopLeft(find.byType(FlutterMap)) + Offset(empty.x, empty.y));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('campus-building-details')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
  });

  testWidgets(
      'floor uses exact APB code and back retains campus selection and camera',
      (tester) async {
    String? opened;
    final catalog = fixtureCatalog();
    await tester.pumpWidget(app(CampusMapScreen(
        catalog: catalog,
        tiles: TestCampusTiles(),
        loadFloor: (code) async {
          opened = code;
          return syntheticFloor(id: 'test.318');
        })));
    await tester.pumpAndSettle();
    await choose(tester, 'APB');
    final camera = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .camera
        .center;
    await tester.tap(find.byKey(const ValueKey('campus-open-floor')));
    await tester.pumpAndSettle();
    expect(opened, 'apb');
    expect(find.byType(BuildingScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Andreas-Pfitzmann-Bau'), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('campus-search')))
            .focusNode!
            .hasFocus,
        isFalse);
    expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .mapController!
            .camera
            .center,
        camera);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
  });

  testWidgets(
      'missing floor is explained; route handoff uses selected building',
      (tester) async {
    Uri? launched;
    final catalog = fixtureCatalog();
    await tester.pumpWidget(app(CampusMapScreen(
        catalog: catalog,
        tiles: TestCampusTiles(),
        loadFloor: (_) async =>
            throw const FormatException('No floor plan available'),
        launchRoute: (uri) async {
          launched = uri;
          return true;
        })));
    await tester.pumpAndSettle();
    await choose(tester, 'BAR');
    await tester.tap(find.byKey(const ValueKey('campus-open-floor')));
    await tester.pumpAndSettle();
    expect(find.text('Kein Etagenplan'), findsOneWidget);
    expect(find.byType(BuildingScreen), findsNothing);
    await tester.tap(find.byKey(const ValueKey('campus-route')));
    await tester.pumpAndSettle();
    expect(launched,
        catalog.buildings.singleWhere((b) => b.code == 'BAR').routeUri);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
  });

  for (final throws in [false, true]) {
    testWidgets('navigation launch failure is recoverable (throws: $throws)',
        (tester) async {
      var launches = 0;
      var locations = 0;
      final catalog = fixtureCatalog();
      await tester.pumpWidget(app(CampusMapScreen(
          catalog: catalog,
          tiles: TestCampusTiles(),
          locate: () async {
            locations++;
            return const LatLng(51, 13);
          },
          launchRoute: (_) async {
            launches++;
            if (throws) throw StateError('No activity');
            return false;
          })));
      await tester.pumpAndSettle();
      await choose(tester, 'APB');
      expect(find.text('Navigieren'), findsOneWidget);
      final button = find.byKey(const ValueKey('campus-route'));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('Navigation konnte nicht geöffnet werden'),
          findsOneWidget);
      expect(locations, 0);
      expect(launches, 1);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
      // Let the error snackbar leave the compact viewport before tapping again.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(launches, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      catalog.dispose();
    });
  }

  testWidgets('navigation stays disabled for a building without coordinates',
      (tester) async {
    var launches = 0;
    final records = jsonDecode(campusFixture()) as List;
    records.add({'krz': 'NOCO', 'name': 'No coordinates'});
    final catalog = CampusCatalog(
        readCache: () async => null,
        fetch: () async => jsonEncode(records),
        writeCache: (_) async {});
    await tester.pumpWidget(app(CampusMapScreen(
        catalog: catalog,
        tiles: TestCampusTiles(),
        launchRoute: (_) async {
          launches++;
          return true;
        })));
    await tester.pumpAndSettle();
    await choose(tester, 'NOCO');
    expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('campus-route')))
            .onPressed,
        isNull);
    expect(launches, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
  });

  testWidgets(
      'location is requested only on button tap; denial keeps map usable',
      (tester) async {
    var requests = 0;
    final catalog = fixtureCatalog();
    await tester.pumpWidget(app(CampusMapScreen(
        catalog: catalog,
        tiles: TestCampusTiles(),
        locate: () async {
          requests++;
          throw const CampusLocationException(CampusLocationFailure.denied);
        })));
    await tester.pumpAndSettle();
    expect(requests, 0);
    await tester.tap(find.byTooltip('Eigene Position anzeigen'));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.textContaining('Standortfreigabe verweigert'), findsOneWidget);
    await choose(tester, 'BAR');
    expect(find.text('Barkhausen-Bau'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
  });

  testWidgets('explicit location displays a marker and centers the map',
      (tester) async {
    final catalog = fixtureCatalog();
    const point = LatLng(51.026, 13.725);
    await tester.pumpWidget(app(CampusMapScreen(
        catalog: catalog,
        tiles: TestCampusTiles(),
        locate: () async => point)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Eigene Position anzeigen'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<MarkerLayer>(find.byType(MarkerLayer))
            .markers
            .single
            .point,
        point);
    expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .mapController!
            .camera
            .center,
        point);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
  });

  testWidgets('failed TU catalog still renders map with retry, then recovers',
      (tester) async {
    var fail = true;
    final catalog = CampusCatalog(
        readCache: () async => null,
        fetch: () async {
          if (fail) throw StateError('offline');
          return campusFixture();
        },
        writeCache: (_) async {});
    await tester.pumpWidget(
        app(CampusMapScreen(catalog: catalog, tiles: TestCampusTiles())));
    await tester.pumpAndSettle();
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.textContaining('TU-Gebäude nicht erreichbar'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    await choose(tester, 'APB');
    expect(find.text('Andreas-Pfitzmann-Bau'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
  });

  testWidgets('many outlines pan without rebuilding the polygon definitions',
      (tester) async {
    final record = (jsonDecode(campusFixture()) as List).first as Map;
    final body = jsonEncode([
      for (var i = 0; i < 400; i++) {...record, 'krz': 'T$i'}
    ]);
    final catalog = CampusCatalog(
        readCache: () async => null,
        fetch: () async => body,
        writeCache: (_) async {});
    await tester.pumpWidget(
        app(CampusMapScreen(catalog: catalog, tiles: TestCampusTiles())));
    await tester.pumpAndSettle();
    final layer = tester.widget<PolygonLayer<CampusFeature>>(
        find.byType(PolygonLayer<CampusFeature>));
    expect(layer.polygons.length, 400);
    await tester.drag(find.byType(FlutterMap), const Offset(50, 50));
    await tester.pumpAndSettle();
    expect(
        identical(
            layer.polygons,
            tester
                .widget<PolygonLayer<CampusFeature>>(
                    find.byType(PolygonLayer<CampusFeature>))
                .polygons),
        isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    catalog.dispose();
  });
}
