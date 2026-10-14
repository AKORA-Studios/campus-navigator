import 'dart:async';
import 'dart:convert';
import 'package:campus_navigator/api/place_navigation.dart';
import 'package:campus_navigator/api/saved_places.dart';
import 'package:campus_navigator/api/search.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

SavedPlace room(String code, String id, {String name = '318'}) => SavedPlace(
    kind: PlaceKind.room, identifier: '$code/03/raum/$id', name: name);
final building = SavedPlace(
    kind: PlaceKind.building, identifier: 'dresden/geb/bey', name: 'Beyer-Bau');

class MemoryPlaces {
  String? data;
  bool failRead = false;
  bool failWrite = false;
  PlaceStore create() => PlaceStore(read: () async {
        if (failRead) throw StateError('read failed');
        return data;
      }, write: (value) async {
        if (failWrite) throw StateError('write failed');
        data = value;
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('same room name in different buildings retains both server identities',
      () async {
    final memory = MemoryPlaces();
    final store = memory.create();
    final bey = room('bey', '111103.5220');
    final apb = room('apb', '542103.5220');
    await store.toggle(bey);
    await store.toggle(apb);
    await store.toggle(building);
    expect(store.favorites.map((p) => p.key).toSet().length, 3);
    final restored = memory.create();
    await restored.load();
    expect(restored.favorites.map((p) => p.identifier),
        [bey.identifier, apb.identifier, building.identifier]);
    await restored.toggle(bey);
    final restarted = memory.create();
    await restarted.load();
    expect(restarted.contains(bey), isFalse);
    expect(restarted.contains(apb), isTrue);
    expect(restarted.contains(building), isTrue);
    store.dispose();
    restored.dispose();
    restarted.dispose();
  });

  test('history is most recent first, unique by ID and bounded to 20 rooms',
      () async {
    final memory = MemoryPlaces();
    final store = memory.create();
    for (var i = 0; i < 25; i++) {
      await store.recordVisit(room('bey', 'id.$i'));
    }
    await store.recordVisit(room('bey', 'id.10'));
    await store.recordVisit(building);
    expect(store.recent.length, PlaceStore.historyLimit);
    expect(store.recent.first.roomId, 'id.10');
    expect(store.recent.map((p) => p.key).toSet().length, 20);
    final restored = memory.create();
    await restored.load();
    expect(restored.recent.map((p) => p.identifier),
        store.recent.map((p) => p.identifier));
    store.dispose();
    restored.dispose();
  });

  test('rapid queued writes preserve favorites and visits without lost updates',
      () async {
    final firstWrite = Completer<void>();
    String? raw;
    var writes = 0;
    final store = PlaceStore(
        read: () async => raw,
        write: (value) async {
          if (++writes == 1) await firstWrite.future;
          raw = value;
        });
    await store.load();
    final a = room('bey', 'a');
    final b = room('apb', 'b');
    final operations = [store.toggle(a), store.toggle(b), store.recordVisit(a)];
    expect(store.saving, isTrue);
    expect(store.favorites, isEmpty); // Not yet durably written.
    firstWrite.complete();
    expect(await Future.wait(operations), everyElement(isTrue));
    expect(store.favorites.map((p) => p.key), [a.key, b.key]);
    expect(store.recent.single.key, a.key);
    expect(store.saving, isFalse);
    store.dispose();
  });

  test('failed write leaves committed state intact and later retry works',
      () async {
    final memory = MemoryPlaces();
    final store = memory.create();
    await store.toggle(building);
    final old = memory.data;
    memory.failWrite = true;
    expect(await store.toggle(building), isFalse);
    expect(store.contains(building), isTrue);
    expect(memory.data, old);
    memory.failWrite = false;
    expect(await store.toggle(building), isTrue);
    expect(store.contains(building), isFalse);
    store.dispose();
  });

  test('read failures retry without overwriting saved favorites', () async {
    final memory = MemoryPlaces();
    final original = memory.create();
    await original.toggle(building);
    final old = memory.data;
    memory.failRead = true;
    final store = memory.create();
    await store.load();
    expect(store.loadFailed, isTrue);
    expect(await store.toggle(room('bey', 'new')), isFalse);
    expect(memory.data, old);
    memory.failRead = false;
    await store.load();
    expect(store.loadFailed, isFalse);
    expect(store.contains(building), isTrue);
    original.dispose();
    store.dispose();
  });

  test('unsupported/corrupt documents are not silently erased', () async {
    for (final raw in [
      'not JSON',
      '{"version":99,"favorites":[],"recent":[]}'
    ]) {
      final memory = MemoryPlaces()..data = raw;
      final store = memory.create();
      await store.load();
      expect(store.ready, isFalse);
      expect(await store.clearHistory(), isFalse);
      expect(memory.data, raw);
      store.dispose();
    }
  });

  test('invalid individual records are skipped and duplicate IDs deduplicated',
      () async {
    final memory = MemoryPlaces()
      ..data = jsonEncode({
        'version': 1,
        'favorites': [
          building.toJson(),
          {'kind': 'unknown'},
          building.toJson(),
          {
            'kind': 'room',
            'name': 'bad',
            'identifier': 'https://other.example/room'
          }
        ],
        'recent': [building.toJson(), room('bey', 'valid').toJson()]
      });
    final store = memory.create();
    await store.load();
    expect(store.favorites.single.key, building.key);
    expect(store.recent.single.roomId, 'valid');
    store.dispose();
  });

  test('clear history preserves favorites on restart', () async {
    final memory = MemoryPlaces();
    final store = memory.create();
    await store.toggle(building);
    await store.recordVisit(room('bey', 'one'));
    await store.clearHistory();
    final restored = memory.create();
    await restored.load();
    expect(restored.recent, isEmpty);
    expect(restored.contains(building), isTrue);
    store.dispose();
    restored.dispose();
  });

  test('existing secure-storage adapter persists between fresh store instances',
      () async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = PlaceStore();
    await store.toggle(building);
    final restored = PlaceStore();
    await restored.load();
    expect(restored.contains(building), isTrue);
    store.dispose();
    restored.dispose();
  });

  test('building resolution uses advertised levels, never a guessed floor', () {
    expect(
        buildingFloorQuery(
            '<a href="etplan/bey/03">3</a><a href="/etplan/bey/00">0</a>',
            'bey'),
        'bey/00');
    expect(
        buildingFloorQuery('<a href="etplan/bey/-1">UG</a>', 'bey'), 'bey/-1');
    expect(() => buildingFloorQuery('<a href="etplan/apb/00">other</a>', 'bey'),
        throwsFormatException);
    expect(
        () => buildingFloorQuery(
            '<a href="https://other.example/etplan/bey/00">other</a>', 'bey'),
        throwsFormatException);
  });

  test('unsafe and malformed server destinations cannot become saved places',
      () {
    for (final id in [
      '../03/raum/a',
      'bey/03/raum/a?x=1',
      'https://other.example/bey/03/raum/a'
    ]) {
      expect(
          SavedPlace.tryFromSearch(
              SearchResultObject(name: '318', subName: null, identifier: id),
              PlaceKind.room),
          isNull);
    }
    final relocated = room('bey', 'same');
    final same = SavedPlace(
        kind: PlaceKind.room, identifier: 'bey/02/raum/same', name: 'new name');
    expect(relocated.key, same.key);
  });
}
