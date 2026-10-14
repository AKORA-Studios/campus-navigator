import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/networking.dart';
import 'package:campus_navigator/api/building/page_image_data.dart';
import '../storage_mock.dart';
import 'package:campus_navigator/api/storage.dart';

class NetworkStorage extends StorageMock {
  @override
  Future<CacheDuration> getCacheDuration() async => CacheDuration.day;
}

class TestCache extends Fake implements ImageCacheManager {
  final fs = MemoryFileSystem();
  final files = <String, FileInfo>{};
  int writes = 0;
  @override
  Future<FileInfo?> getFileFromCache(String key,
          {bool ignoreMemCache = false}) async =>
      files[key];
  @override
  Future<File> putFile(String url, Uint8List bytes,
      {String? key,
      String? eTag,
      Duration maxAge = const Duration(days: 30),
      String fileExtension = 'file'}) async {
    final file = fs.file('/${writes++}')..writeAsBytesSync(bytes);
    files[key ?? url] =
        FileInfo(file, FileSource.Cache, DateTime.now().add(maxAge), url);
    return file;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => APIServices.Shared = APIServices.withoutCache());
  test('cache is initialized, reused, and expired entries are refreshed',
      () async {
    final cache = TestCache();
    final api = BaseAPIServices(cacheManager: cache)
      ..storage = NetworkStorage();
    var requests = 0;
    api.client = MockClient((_) async {
      requests++;
      return http.Response('new', 200);
    });
    final uri = Uri.parse('https://example.test/plan');
    expect(api.cacheManager, same(cache));
    expect(await api.fetchHMTL(uri), 'new');
    expect(await api.fetchHMTL(uri), 'new');
    expect(requests, 1);
    final old = cache.files[uri.toString()]!;
    cache.files[uri.toString()] = FileInfo(old.file, old.source,
        DateTime.now().subtract(const Duration(seconds: 1)), uri.toString());
    expect(await api.fetchHMTL(uri), 'new');
    expect(requests, 2);
  });
  test('duplicate requests share one response; failed requests can retry',
      () async {
    final api = BaseAPIServices();
    var requests = 0;
    final response = Completer<http.Response>();
    api.client = MockClient((_) {
      requests++;
      return response.future;
    });
    final uri = Uri.parse('https://example.test/plan');
    final first = api.fetchHMTL(uri);
    final second = api.fetchHMTL(uri);
    await Future<void>.delayed(Duration.zero);
    response.complete(http.Response('unavailable', 503));
    expect(await first, isNull);
    expect(await second, isNull);
    expect(requests, 1);
    api.client = MockClient((_) async => http.Response('ok', 200));
    expect(await api.fetchHMTL(uri), 'ok');
    expect(api.pendingStrings, isEmpty);
  });
  test('server Latin-1 is decoded before UTF-8 caching', () async {
    final api = BaseAPIServices();
    api.client = MockClient((_) async => http.Response.bytes(
        latin1.encode('Bär'), 200,
        headers: {'content-type': 'text/html; charset=iso-8859-1'}));
    expect(await api.fetchHMTL(Uri.parse('https://example.test/')), 'Bär');
  });
  test('floor loader bounds work to four requests and stops on disposal',
      () async {
    final api = APIServices.Shared;
    final oldClient = api.client;
    final oldCache = api.cacheManager;
    api.cacheManager = null;
    final pending = <Completer<http.Response>>[];
    api.client = MockClient((_) {
      final c = Completer<http.Response>();
      pending.add(c);
      return c.future;
    });
    final images = PageImageData.fetchLevelImages('TEST', [], [(h: 12, v: 1)],
        qualiIndex: 0);
    await Future<void>.delayed(Duration.zero);
    expect(pending.length, 4);
    images.dispose();
    for (final request in pending) {
      request.complete(http.Response('', 404));
    }
    await images.loaded;
    expect(pending.length, 4);
    expect(images.imageMap, isEmpty);
    api.client = oldClient;
    api.cacheManager = oldCache;
  });

  test('blank HTTP-200 tiles are valid, HTTP failures and corrupt PNGs are not',
      () async {
    APIServices.Shared.client = MockClient((request) async {
      final path = request.url.path;
      if (path.contains('/0_0.png')) return http.Response('', 200);
      if (path.contains('/1_0.png')) return http.Response('', 503);
      return http.Response('not a PNG', 200);
    });
    final images = PageImageData.fetchLevelImages('TEST', [], [(h: 3, v: 1)],
        qualiIndex: 0);
    await images.loaded;
    expect(images.failedImages, 2);
    expect(images.imageMap, isEmpty);
    images.dispose();
  });
}
