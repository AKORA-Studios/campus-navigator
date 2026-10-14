import 'package:campus_navigator/settings/app_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemorySettingsStore implements AppSettingsStore {
  final Map<String, String> values = {};
  final Set<String> failedReads = {};
  final Set<String> failedWrites = {};
  final Set<String> failedRemoves = {};

  @override
  Future<String?> read(String key) async {
    if (failedReads.contains(key)) throw StateError('read failed');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failedWrites.contains(key)) throw StateError('write failed');
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    if (failedRemoves.contains(key)) throw StateError('remove failed');
    values.remove(key);
  }
}

void main() {
  group('AppSettingsController', () {
    test(
        'uses system appearance, automatic map style and device language by default',
        () async {
      final controller = AppSettingsController(store: MemorySettingsStore());
      await controller.load();

      expect(controller.themeMode, ThemeMode.system);
      expect(controller.campusMapThemeMode, CampusMapThemeMode.automatic);
      expect(controller.locale, isNull);
    });

    test('uses Campus Identity option A by default', () async {
      final controller = AppSettingsController(store: MemorySettingsStore());
      await controller.load();

      expect(controller.campusIdentityStyle, AppCampusIdentityStyle.academic);
      controller.dispose();
    });

    test('persists the Campus Identity style across controller recreation',
        () async {
      final store = MemorySettingsStore();
      final first = AppSettingsController(store: store);
      await first.load();
      await first.setCampusIdentityStyle(AppCampusIdentityStyle.wayfinding);

      final restarted = AppSettingsController(store: store);
      await restarted.load();

      expect(restarted.campusIdentityStyle, AppCampusIdentityStyle.wayfinding);
      expect(store.values[AppSettingsController.campusIdentityStyleKey],
          'wayfinding');
      first.dispose();
      restarted.dispose();
    });

    test('does not change Campus Identity when its write fails', () async {
      final store = MemorySettingsStore()
        ..failedWrites.add(AppSettingsController.campusIdentityStyleKey);
      final controller = AppSettingsController(store: store);
      await controller.load();

      await expectLater(
        controller.setCampusIdentityStyle(AppCampusIdentityStyle.wayfinding),
        throwsA(isA<StateError>()),
      );

      expect(controller.campusIdentityStyle, AppCampusIdentityStyle.academic);
      controller.dispose();
    });

    test('invalid Campus Identity values fall back to option A', () async {
      final store = MemorySettingsStore()
        ..values[AppSettingsController.campusIdentityStyleKey] = 'unknown';
      final controller = AppSettingsController(store: store);

      await controller.load();

      expect(controller.campusIdentityStyle, AppCampusIdentityStyle.academic);
      controller.dispose();
    });

    test('persists theme, map style and language across controller recreation',
        () async {
      final store = MemorySettingsStore();
      final first = AppSettingsController(store: store);
      await first.load();
      await first.setThemeMode(ThemeMode.dark);
      await first.setCampusMapThemeMode(CampusMapThemeMode.light);
      await first.setLocale(const Locale('ja'));

      final restarted = AppSettingsController(store: store);
      await restarted.load();

      expect(restarted.themeMode, ThemeMode.dark);
      expect(restarted.campusMapThemeMode, CampusMapThemeMode.light);
      expect(restarted.locale, const Locale('ja'));
    });

    test('notifies listeners after a setting is successfully persisted',
        () async {
      final controller = AppSettingsController(store: MemorySettingsStore());
      await controller.load();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setThemeMode(ThemeMode.dark);

      expect(controller.themeMode, ThemeMode.dark);
      expect(notifications, 1);
      controller.dispose();
    });

    test('does not apply a preference when its persistent write fails',
        () async {
      final store = MemorySettingsStore()
        ..failedWrites.add(AppSettingsController.themeModeKey);
      final controller = AppSettingsController(store: store);
      await controller.load();

      await expectLater(
          controller.setThemeMode(ThemeMode.dark), throwsA(isA<StateError>()));

      expect(controller.themeMode, ThemeMode.system);
      expect(store.values, isEmpty);
      controller.dispose();
    });

    test('restores defaults and persists device-language selection', () async {
      final store = MemorySettingsStore();
      final controller = AppSettingsController(store: store);
      await controller.load();
      await controller.setThemeMode(ThemeMode.dark);
      await controller.setCampusMapThemeMode(CampusMapThemeMode.dark);
      await controller.setLocale(const Locale('ar'));
      await controller
          .setCampusIdentityStyle(AppCampusIdentityStyle.wayfinding);

      await controller.restoreAppearanceDefaults();
      final restarted = AppSettingsController(store: store);
      await restarted.load();

      expect(restarted.themeMode, ThemeMode.system);
      expect(restarted.campusMapThemeMode, CampusMapThemeMode.automatic);
      expect(restarted.campusIdentityStyle, AppCampusIdentityStyle.academic);
      expect(restarted.locale, isNull);
    });

    test(
        'reconciles state with storage when restoring defaults partially fails',
        () async {
      final store = MemorySettingsStore()
        ..values[AppSettingsController.themeModeKey] = 'dark'
        ..values[AppSettingsController.mapThemeModeKey] = 'dark'
        ..values[AppSettingsController.localeKey] = 'ja'
        ..failedRemoves.add(AppSettingsController.mapThemeModeKey);
      final controller = AppSettingsController(store: store);
      await controller.load();

      await expectLater(
        controller.restoreAppearanceDefaults(),
        throwsA(isA<StateError>()),
      );

      expect(controller.themeMode.name,
          store.values[AppSettingsController.themeModeKey] ?? 'system');
      expect(controller.campusMapThemeMode.name,
          store.values[AppSettingsController.mapThemeModeKey] ?? 'automatic');
      expect(
          AppLanguage.fromLocale(controller.locale ?? const Locale('en'))
              ?.storageTag,
          store.values[AppSettingsController.localeKey]);
      controller.dispose();
    });

    test('invalid persisted values safely fall back to defaults', () async {
      final store = MemorySettingsStore()
        ..values[AppSettingsController.themeModeKey] = 'ultraviolet'
        ..values[AppSettingsController.mapThemeModeKey] = 'satellite'
        ..values[AppSettingsController.campusIdentityStyleKey] = 'experimental'
        ..values[AppSettingsController.localeKey] = 'xx-ZZ';
      final controller = AppSettingsController(store: store);

      await controller.load();

      expect(controller.themeMode, ThemeMode.system);
      expect(controller.campusMapThemeMode, CampusMapThemeMode.automatic);
      expect(controller.campusIdentityStyle, AppCampusIdentityStyle.academic);
      expect(controller.locale, isNull);
    });

    test('a storage failure for one preference does not hide other settings',
        () async {
      final store = MemorySettingsStore()
        ..values[AppSettingsController.themeModeKey] = 'dark'
        ..values[AppSettingsController.localeKey] = 'fr'
        ..failedReads.add(AppSettingsController.mapThemeModeKey);
      final controller = AppSettingsController(store: store);

      await controller.load();

      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.campusMapThemeMode, CampusMapThemeMode.automatic);
      expect(controller.locale, const Locale('fr'));
    });

    test('rejects an unsupported manually selected locale', () async {
      final controller = AppSettingsController(store: MemorySettingsStore());
      await controller.load();

      await expectLater(controller.setLocale(const Locale('sv')),
          throwsA(isA<ArgumentError>()));
      expect(controller.locale, isNull);
      controller.dispose();
    });

    test(
        'exposes fourteen locally supported languages including Chinese script',
        () {
      expect(AppLanguage.values, hasLength(14));
      expect(AppLanguage.simplifiedChinese.locale,
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
      expect(AppSettingsController.resolveLocale(const Locale('zh')),
          AppLanguage.simplifiedChinese.locale);
      expect(AppSettingsController.resolveLocale(const Locale('sv')),
          AppSettingsController.fallbackLocale);
      expect(AppLanguage.all.map((language) => language.nativeName).toSet(),
          hasLength(14));
    });

    test('resolves supported languages with explicit default scripts', () {
      expect(
        AppSettingsController.resolveLocale(const Locale.fromSubtags(
          languageCode: 'de',
          scriptCode: 'Latn',
          countryCode: 'DE',
        )),
        const Locale('de'),
      );
      expect(
        AppSettingsController.resolveLocale(const Locale.fromSubtags(
          languageCode: 'ar',
          scriptCode: 'Arab',
          countryCode: 'SA',
        )),
        const Locale('ar'),
      );
      expect(
        AppSettingsController.resolveLocale(const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        )),
        AppSettingsController.fallbackLocale,
      );
    });
  });
}
