import 'package:campus_navigator/api/storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('corrupt existing network settings use safe documented defaults',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      Storage.keyQualityLevel: 'not-a-number',
      Storage.keyPrefetchingLevel: 'unrecognized',
      Storage.keyCacheDuration: '999',
      Storage.keyUniversity: 'unknown',
    });

    final storage = Storage();

    expect(await storage.getQualityLevel(), 4);
    expect(await storage.getPrefetchingLevel(), PrefetchingLevel.firstResult);
    expect(await storage.getCacheDuration(), CacheDuration.day);
    expect(await storage.getUniversity(), UserUniversity.TUD);
  });

  test('strict university lookup falls back for an invalid stored selection',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      Storage.keyUniversity: '99',
    });

    expect(await Storage().getUniversityStrict(), UserUniversity.TUD);
  });
}
