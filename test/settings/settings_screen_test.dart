import 'package:campus_navigator/api/saved_places.dart';
import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:campus_navigator/settings/app_settings_controller.dart';
import 'package:campus_navigator/settings/app_settings_scope.dart';
import 'package:campus_navigator/settings/cache_maintenance.dart';
import 'package:campus_navigator/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemorySettings implements AppSettingsStore {
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

class _CredentialReadFailureStorage extends Storage {
  _CredentialReadFailureStorage({
    this.failUsername = true,
    this.failPassword = false,
    this.failUniversity = false,
    this.university = UserUniversity.HTW,
  });

  final bool failUsername;
  final bool failPassword;
  final bool failUniversity;
  final UserUniversity university;
  int credentialWrites = 0;

  @override
  Future<String?> getUsername() async {
    if (failUsername) throw StateError('secure read failed');
    return 'saved-user';
  }

  @override
  Future<String?> getPassword() async {
    if (failPassword) throw StateError('secure read failed');
    return 'saved-secret';
  }

  @override
  Future<UserUniversity> getUniversityStrict() async {
    if (failUniversity) throw StateError('secure read failed');
    return university;
  }

  @override
  Future<CacheDuration> getCacheDuration() async => CacheDuration.day;

  @override
  Future<PrefetchingLevel> getPrefetchingLevel() async =>
      PrefetchingLevel.firstResult;

  @override
  Future<int> getQualityLevel() async => 4;

  @override
  Future<void> editUsername(String newValue) async {
    credentialWrites++;
  }

  @override
  Future<void> editpassword(String newValue) async {
    credentialWrites++;
  }

  @override
  Future<void> editUniversity(UserUniversity newValue) async {
    credentialWrites++;
  }
}

Widget _settingsApp({
  required AppSettingsController controller,
  required PlaceStore places,
  CacheMaintenance? cacheMaintenance,
  ThemeMode themeMode = ThemeMode.light,
}) =>
    MaterialApp(
      theme: ThemeData.light(useMaterial3: true)
          .copyWith(splashFactory: NoSplash.splashFactory),
      darkTheme: ThemeData.dark(useMaterial3: true)
          .copyWith(splashFactory: NoSplash.splashFactory),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppSettingsScope(
        controller: controller,
        child: SettingsScreen(
          places: places,
          cacheMaintenance: cacheMaintenance,
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('theme choice applies immediately and persists', (tester) async {
    final values = _MemorySettings();
    final controller = AppSettingsController(store: values);
    await controller.load();
    final places = PlaceStore(read: () async => null, write: (_) async {});
    await tester
        .pumpWidget(_settingsApp(controller: controller, places: places));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(controller.themeMode, ThemeMode.dark);
    expect(values.values[AppSettingsController.themeModeKey], 'dark');
    places.dispose();
    controller.dispose();
  });

  testWidgets('language choice applies a supported locale immediately',
      (tester) async {
    final controller = AppSettingsController(store: _MemorySettings());
    await controller.load();
    final places = PlaceStore(read: () async => null, write: (_) async {});
    await tester
        .pumpWidget(_settingsApp(controller: controller, places: places));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('日本語'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('日本語').last);
    await tester.pumpAndSettle();

    expect(controller.locale, const Locale('ja'));
    places.dispose();
    controller.dispose();
  });

  testWidgets('Campus Identity can switch to option B and persists immediately',
      (tester) async {
    final values = _MemorySettings();
    final controller = AppSettingsController(store: values);
    await controller.load();
    final places = PlaceStore(read: () async => null, write: (_) async {});
    await tester
        .pumpWidget(_settingsApp(controller: controller, places: places));
    await tester.pumpAndSettle();

    expect(controller.campusIdentityStyle, AppCampusIdentityStyle.academic);
    await tester
        .tap(find.byType(DropdownButtonFormField<AppCampusIdentityStyle>));
    await tester.pumpAndSettle();
    final optionB = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownMenuItem<AppCampusIdentityStyle> &&
          widget.value == AppCampusIdentityStyle.wayfinding,
    );
    await tester.tap(optionB.last);
    await tester.pumpAndSettle();

    expect(controller.campusIdentityStyle, AppCampusIdentityStyle.wayfinding);
    expect(values.values[AppSettingsController.campusIdentityStyleKey],
        'wayfinding');
    places.dispose();
    controller.dispose();
  });

  testWidgets('protects credentials when secure storage cannot load them',
      (tester) async {
    final originalStorage = APIServices.Shared.storage;
    final storage = _CredentialReadFailureStorage();
    APIServices.Shared.storage = storage;
    addTearDown(() => APIServices.Shared.storage = originalStorage);
    final controller = AppSettingsController(store: _MemorySettings());
    await controller.load();
    final places = PlaceStore(read: () async => null, write: (_) async {});

    await tester
        .pumpWidget(_settingsApp(controller: controller, places: places));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Saved login settings could not be loaded. Editing is paused.'),
        findsOneWidget);
    expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((field) => field.enabled == false),
        isTrue);
    await tester.scrollUntilVisible(
      find.byIcon(Icons.save_outlined),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    expect(storage.credentialWrites, 0);

    places.dispose();
    controller.dispose();
  });

  testWidgets(
      'protects the saved university when secure storage cannot load it',
      (tester) async {
    final originalStorage = APIServices.Shared.storage;
    final storage = _CredentialReadFailureStorage(
      failUsername: false,
      failUniversity: true,
    );
    APIServices.Shared.storage = storage;
    addTearDown(() => APIServices.Shared.storage = originalStorage);
    final controller = AppSettingsController(store: _MemorySettings());
    await controller.load();
    final places = PlaceStore(read: () async => null, write: (_) async {});

    await tester
        .pumpWidget(_settingsApp(controller: controller, places: places));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Saved login settings could not be loaded. Editing is paused.'),
        findsOneWidget);
    await tester.scrollUntilVisible(
      find.byIcon(Icons.save_outlined),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    expect(storage.credentialWrites, 0);

    places.dispose();
    controller.dispose();
  });

  testWidgets('invalid university fallback still allows credential correction',
      (tester) async {
    final originalStorage = APIServices.Shared.storage;
    final storage = _CredentialReadFailureStorage(
      failUsername: false,
      university: UserUniversity.TUD,
    );
    APIServices.Shared.storage = storage;
    addTearDown(() => APIServices.Shared.storage = originalStorage);
    final controller = AppSettingsController(store: _MemorySettings());
    await controller.load();
    final places = PlaceStore(read: () async => null, write: (_) async {});

    await tester
        .pumpWidget(_settingsApp(controller: controller, places: places));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Saved login settings could not be loaded. Editing is paused.'),
        findsNothing);
    await tester.scrollUntilVisible(
      find.byIcon(Icons.save_outlined),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    expect(storage.credentialWrites, 3);

    places.dispose();
    controller.dispose();
  });

  testWidgets('protects the saved password when secure storage cannot load it',
      (tester) async {
    final originalStorage = APIServices.Shared.storage;
    final storage = _CredentialReadFailureStorage(
      failUsername: false,
      failPassword: true,
    );
    APIServices.Shared.storage = storage;
    addTearDown(() => APIServices.Shared.storage = originalStorage);
    final controller = AppSettingsController(store: _MemorySettings());
    await controller.load();
    final places = PlaceStore(read: () async => null, write: (_) async {});

    await tester
        .pumpWidget(_settingsApp(controller: controller, places: places));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Saved login settings could not be loaded. Editing is paused.'),
        findsOneWidget);
    await tester.scrollUntilVisible(
      find.byIcon(Icons.save_outlined),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    expect(storage.credentialWrites, 0);

    places.dispose();
    controller.dispose();
  });

  testWidgets('settings remain visible in both light and dark themes',
      (tester) async {
    final controller = AppSettingsController(store: _MemorySettings());
    await controller.load();
    final places = PlaceStore(read: () async => null, write: (_) async {});

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(_settingsApp(
        controller: controller,
        places: places,
        themeMode: mode,
      ));
      await tester.pumpAndSettle();
      final settingsContext = tester.element(find.byType(SettingsScreen));
      expect(Theme.of(settingsContext).brightness,
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
      expect(find.text('App theme'), findsOneWidget);
    }

    places.dispose();
    controller.dispose();
  });

  testWidgets('cache confirmation clears temp data and preserves places',
      (tester) async {
    final controller = AppSettingsController(store: _MemorySettings());
    await controller.load();
    final values = <String?>{};
    final places = PlaceStore(
      read: () async => values.isEmpty ? null : values.first,
      write: (value) async {
        values
          ..clear()
          ..add(value);
      },
    );
    final favorite = SavedPlace(
      kind: PlaceKind.building,
      identifier: 'dresden/geb/bey',
      name: 'Beyer-Bau',
    );
    await places.toggle(favorite);
    await places.recordVisit(SavedPlace(
      kind: PlaceKind.room,
      identifier: 'bey/03/raum/318',
      name: '318',
    ));
    var clearCalls = 0;
    final maintenance = CacheMaintenance(
      clearers: [
        () async {
          clearCalls++;
        }
      ],
      temporaryDirectory: () async => throw StateError('not available'),
    );

    await tester.pumpWidget(_settingsApp(
      controller: controller,
      places: places,
      cacheMaintenance: maintenance,
    ));
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(find.text('Clear cache'), 250,
        scrollable: scrollable.first);
    await tester.ensureVisible(find.text('Clear cache').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear cache'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(clearCalls, 1);
    expect(places.contains(favorite), isTrue);
    expect(places.recent, hasLength(1));

    await tester.scrollUntilVisible(find.text('Clear search history'), 240,
        scrollable: scrollable.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear search history').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(places.recent, isEmpty);
    expect(places.contains(favorite), isTrue);
    places.dispose();
    controller.dispose();
  });
}
