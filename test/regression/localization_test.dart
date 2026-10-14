import 'dart:convert';
import 'dart:io';
import 'package:campus_navigator/main.dart';
import 'package:campus_navigator/settings/app_settings_controller.dart';
import 'package:campus_navigator/ui/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'app_preferences_integration_test.dart' show MemoryAppearanceStore;

const languages = [
  'de',
  'en',
  'fr',
  'es',
  'it',
  'pt',
  'pl',
  'ru',
  'tr',
  'ar',
  'hi',
  'zh_Hans',
  'ja',
  'ko'
];
Map<String, dynamic> catalog(String tag) =>
    jsonDecode(File('lib/l10n/app_$tag.arb').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('all 14 catalogs contain the same messages, metadata and placeholders',
      () {
    final template = catalog('en');
    final placeholders = RegExp(r'\{(\w+)\}');
    for (final tag in languages) {
      final translated = catalog(tag);
      expect(translated.keys.toSet(), template.keys.toSet(), reason: tag);
      for (final key in template.keys.where((key) => !key.startsWith('@'))) {
        final value = translated[key] as String;
        expect(value.trim(), isNotEmpty, reason: '$tag/$key');
        expect(
            placeholders.allMatches(value).map((m) => m[1]).toSet(),
            placeholders
                .allMatches(template[key] as String)
                .map((m) => m[1])
                .toSet(),
            reason: '$tag/$key placeholders');
        if (template.containsKey('@$key')) {
          expect(translated['@$key'], template['@$key'],
              reason: '$tag/$key metadata');
        }
      }
    }
    expect(catalog('zh')..remove('@@locale'),
        catalog('zh_Hans')..remove('@@locale'));
  });

  for (final tag in languages) {
    testWidgets('real app renders the saved $tag language and labeled actions',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final settings = AppSettingsController(store: MemoryAppearanceStore());
      await settings.load();
      await settings.setLocale(tag == 'zh_Hans'
          ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')
          : Locale(tag));
      await tester.pumpWidget(MyApp(settings: settings));
      await tester.pumpAndSettle();
      final strings = catalog(tag);
      expect(find.text(strings['navSearch'] as String), findsOneWidget);
      expect(find.byTooltip(strings['settingsScreen_Title'] as String),
          findsOneWidget);
      final screen = tester.element(find.byType(SearchScreen));
      expect(Directionality.of(screen),
          tag == 'ar' ? TextDirection.rtl : TextDirection.ltr);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
    });
  }
}
