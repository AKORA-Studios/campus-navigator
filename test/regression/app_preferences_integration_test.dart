import 'package:campus_navigator/main.dart';
import 'package:campus_navigator/settings/app_settings_controller.dart';
import 'package:campus_navigator/ui/screens/search_screen.dart';
import 'package:campus_navigator/ui/screens/home_screen.dart';
import 'package:campus_navigator/ui/screens/campus_map_screen.dart';
import 'package:campus_navigator/settings/app_settings_scope.dart';
import 'package:campus_navigator/ui/campus_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'campus_map_widget_test.dart'
    show fixtureCatalog, TestCampusTiles, choose;
import 'campus_identity_layout_test.dart' show layoutApp;
import 'saved_places_test.dart' show MemoryPlaces, room;
import 'package:campus_navigator/ui/search_controller.dart';

class MemoryAppearanceStore implements AppSettingsStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
      'A is default and stored B changes real favorite rows immediately',
      (tester) async {
    final memory = MemoryAppearanceStore();
    final settings = AppSettingsController(store: memory);
    await settings.load();
    final places = MemoryPlaces().create();
    await places.toggle(room('bey', '111103.5220', name: 'BEY/318'));
    final search = RoomSearchController(prefetch: false);
    await tester.pumpWidget(AppSettingsScope(
        controller: settings,
        child: layoutApp(SearchScreen(places: places, search: search))));
    await tester.pumpAndSettle();
    expect(find.byType(BuildingCodeBadge), findsNothing);
    await settings.setCampusIdentityStyle(AppCampusIdentityStyle.wayfinding);
    await tester.pumpAndSettle();
    expect(find.byType(BuildingCodeBadge), findsOneWidget);
    expect(find.text('BEY/318'), findsOneWidget);
    final restart = AppSettingsController(store: memory);
    await restart.load();
    expect(restart.campusIdentityStyle, AppCampusIdentityStyle.wayfinding);
    await settings.restoreAppearanceDefaults();
    await tester.pumpAndSettle();
    expect(find.byType(BuildingCodeBadge), findsNothing);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
    restart.dispose();
    places.dispose();
    search.dispose();
  });

  testWidgets(
      'saved map preference and B reach the real map without losing camera',
      (tester) async {
    final settings = AppSettingsController(store: MemoryAppearanceStore());
    await settings.load();
    final catalog = fixtureCatalog();
    await tester.pumpWidget(AppSettingsScope(
        controller: settings,
        child: layoutApp(
            CampusMapScreen(catalog: catalog, tiles: TestCampusTiles()))));
    await tester.pumpAndSettle();
    await choose(tester, 'APB');
    final screen = tester.element(find.byKey(const ValueKey('campus-search')));
    expect(Theme.of(screen).brightness, Brightness.light);
    await settings.setCampusMapThemeMode(CampusMapThemeMode.dark);
    await settings.setCampusIdentityStyle(AppCampusIdentityStyle.wayfinding);
    await tester.pumpAndSettle();
    expect(Theme.of(screen).brightness, Brightness.dark);
    expect(find.byType(BuildingCodeBadge), findsOneWidget);
    expect(
        find.byKey(const ValueKey('campus-building-details')), findsOneWidget);
    await tester.tap(find.byTooltip(AppLocalizations.of(screen)!.mapStyle));
    await tester.pumpAndSettle();
    expect(settings.campusMapThemeMode, CampusMapThemeMode.light);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
    catalog.dispose();
  });

  testWidgets('wide tablet uses a rail and retains search while rotating',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController(store: MemoryAppearanceStore());
    await settings.load();
    await tester.pumpWidget(MyApp(settings: settings));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    final original = tester.state(find.byType(SearchScreen));
    expect(find.byKey(const ValueKey('hub-favorites')), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-recent')), findsOneWidget);
    tester.view.physicalSize = const Size(393, 852);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.state(find.byType(SearchScreen)), same(original));
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });

  testWidgets(
      'saved app language changes the real search and navigation immediately',
      (tester) async {
    final settings = AppSettingsController(store: MemoryAppearanceStore());
    await settings.load();
    await tester.pumpWidget(MyApp(settings: settings));
    await tester.pumpAndSettle();
    await settings.setLocale(const Locale('fr'));
    await tester.pumpAndSettle();
    expect(
        Localizations.localeOf(tester.element(find.byType(SearchScreen)))
            .languageCode,
        'fr');
    expect(find.text('Recherche de salles'), findsOneWidget);
    expect(find.text('Room search'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });

  testWidgets(
      'app theme preference reaches existing screens and Arabic switches reading direction',
      (tester) async {
    final settings = AppSettingsController(store: MemoryAppearanceStore());
    await settings.load();
    await tester.pumpWidget(MyApp(settings: settings));
    await settings.setThemeMode(ThemeMode.dark);
    await settings.setLocale(const Locale('ar'));
    await tester.pumpAndSettle();
    final screen = tester.element(find.byType(SearchScreen));
    expect(Theme.of(screen).brightness, Brightness.dark);
    expect(Directionality.of(screen), TextDirection.rtl);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });
}
