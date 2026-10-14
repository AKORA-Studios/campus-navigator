import 'dart:convert';
import 'dart:io';

import 'package:campus_navigator/api/saved_places.dart';
import 'package:campus_navigator/settings/cache_maintenance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clears all cache stores even if one cache clear fails', () async {
    final attempted = <String>[];
    final maintenance = CacheMaintenance(
      clearers: [
        () async {
          attempted.add('responses');
          throw StateError('first cache is locked');
        },
        () async => attempted.add('tiles'),
        () async => attempted.add('campus data'),
      ],
    );

    await expectLater(maintenance.clear(), throwsA(isA<CacheClearException>()));
    expect(attempted, ['responses', 'tiles', 'campus data']);
  });

  test(
      'estimates cache bytes and reports unavailable when storage cannot be read',
      () async {
    final root = await Directory.systemTemp.createTemp('campus-cache-test-');
    addTearDown(() => root.delete(recursive: true));
    final cache =
        Directory('${root.path}${Platform.pathSeparator}libCachedImageData');
    await cache.create(recursive: true);
    await File('${cache.path}${Platform.pathSeparator}tile.bin')
        .writeAsBytes([1, 2, 3, 4, 5]);

    final readable = CacheMaintenance(
      clearers: const [],
      temporaryDirectory: () async => root,
    );
    final unavailable = CacheMaintenance(
      clearers: const [],
      temporaryDirectory: () async => throw StateError('storage unavailable'),
    );

    expect(await readable.estimateBytes(), 5);
    expect(await unavailable.estimateBytes(), isNull);
  });

  test('clearing temporary cache keeps favorites and history intact', () async {
    final persisted = <String, String?>{};
    final places = PlaceStore(
      read: () async => persisted[PlaceStore.storageKey],
      write: (value) async => persisted[PlaceStore.storageKey] = value,
    );
    final favorite = SavedPlace(
      kind: PlaceKind.building,
      identifier: 'dresden/geb/bey',
      name: 'Beyer-Bau',
    );
    final recent = SavedPlace(
      kind: PlaceKind.room,
      identifier: 'bey/03/raum/318',
      name: '318',
    );
    await places.toggle(favorite);
    await places.recordVisit(recent);
    final before = persisted[PlaceStore.storageKey];
    final maintenance = CacheMaintenance(clearers: [() async {}]);

    await maintenance.clear();
    final restored = PlaceStore(
      read: () async => persisted[PlaceStore.storageKey],
      write: (value) async => persisted[PlaceStore.storageKey] = value,
    );
    await restored.load();

    expect(persisted[PlaceStore.storageKey], before);
    expect(restored.favorites.single.key, favorite.key);
    expect(restored.recent.single.key, recent.key);
    expect(jsonDecode(before!)['favorites'], hasLength(1));
    places.dispose();
    restored.dispose();
  });
}
