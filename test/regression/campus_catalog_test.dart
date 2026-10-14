import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:campus_navigator/api/campus/campus_building.dart';
import 'package:campus_navigator/api/campus/campus_catalog.dart';
import 'package:campus_navigator/api/place_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

String campusFixture() =>
    File('test/fixtures/campus_buildings.json').readAsStringSync();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = campusFixture();

  test('real TU coordinates retain longitude/latitude and multiple outlines',
      () {
    final buildings = parseCampusBuildings(fixture);
    final apb = buildings.singleWhere((b) => b.code == 'APB');
    expect(apb.name, 'Andreas-Pfitzmann-Bau');
    expect(apb.outlines.single.first.latitude, 51.0255663);
    expect(apb.outlines.single.first.longitude, 13.7234797);
    expect(apb.address, 'Nöthnitzer Straße 46, 01187 Dresden');
    expect(apb.partIds, ['5421']);
    expect(apb.mapPoint!.latitude, closeTo(51.02546, .00002));
    expect(buildings.singleWhere((b) => b.code == 'ASB').outlines.length, 4);
    final bar = buildings.singleWhere((b) => b.code == 'BAR');
    expect(bar.partIds.length, 9);
    expect(bar.mapPoint!.latitude, inExclusiveRange(51.026, 51.028));
  });

  test('ISO-8859-1 response is decoded before parsing; no UTF8 replacement',
      () {
    final response = http.Response.bytes(latin1.encode(fixture), 200,
        headers: {'content-type': 'application/json; charset=ISO-8859-1'});
    final apb =
        parseCampusBuildings(response.body).singleWhere((b) => b.code == 'APB');
    expect(apb.address, contains('Nöthnitzer Straße'));
    expect(apb.address, isNot(contains('�')));
  });

  test('one malformed vertex discards that outline, preserving valid siblings',
      () {
    final record = (jsonDecode(fixture) as List).first as Map<String, dynamic>;
    final good = (record['punkte'] as List).first;
    for (final bad in [
      [
        {'x': 13, 'y': 51},
        {'x': 'bad', 'y': 51},
        {'x': 13.1, 'y': 51.1}
      ],
      [
        {'x': 400000, 'y': 5600000},
        {'x': 400001, 'y': 5600000},
        {'x': 400001, 'y': 5600001}
      ],
      [
        {'x': 13, 'y': 51},
        {'x': 13, 'y': 51},
        {'x': 13, 'y': 51}
      ],
      [
        {'x': double.nan, 'y': 51},
        {'x': 13, 'y': 51},
        {'x': 13.1, 'y': 51.1}
      ],
      [null, null, null],
      [],
    ]) {
      expect(
          CampusFeature.fromJson({
            ...record,
            'punkte': [bad, good]
          })!
              .outlines
              .length,
          1);
    }
  });

  test('incomplete building remains searchable; unusable catalog rejected', () {
    final record = {'krz': 'TEST', 'name': 'Ohne Geometrie'};
    final building = CampusFeature.fromJson(record)!;
    expect(building.mapPoint, isNull);
    expect(building.address, isNull);
    expect(() => parseCampusBuildings(jsonEncode([record])),
        throwsFormatException);
    expect(() => parseCampusBuildings('{}'), throwsFormatException);
    expect(CampusFeature.fromJson({'krz': '../apb', 'name': 'Unsafe'}), isNull);
    expect(CampusFeature.fromJson(null), isNull);
  });

  test('external walking route includes building coordinates, no user location',
      () {
    final apb =
        parseCampusBuildings(fixture).singleWhere((b) => b.code == 'APB');
    expect(apb.floorCode, 'apb');
    expect(apb.routeUri!.queryParameters['destination'],
        '${apb.mapPoint!.latitude},${apb.mapPoint!.longitude}');
    expect(apb.routeUri!.queryParameters['travelmode'], 'walking');
    expect(apb.routeUri!.queryParameters.containsKey('origin'), isFalse);
  });

  test('missing or projected coordinates cannot produce a navigation URL', () {
    for (final points in [
      null,
      [],
      [
        [
          {'x': 462000, 'y': 5650000},
          {'x': 462010, 'y': 5650000},
          {'x': 462010, 'y': 5650010}
        ]
      ]
    ]) {
      final building = CampusFeature.fromJson(
          {'krz': 'TEST', 'name': 'No valid coordinates', 'punkte': points})!;
      expect(building.routeUri, isNull);
    }
  });

  test('APB and BAR URLs use the independently inspected WGS84 targets', () {
    final buildings = parseCampusBuildings(fixture);
    const expected = {
      'APB': [51.02546115, 13.72293115],
      'BAR': [51.02680695, 13.72351765],
    };
    for (final entry in expected.entries) {
      final uri = buildings.singleWhere((b) => b.code == entry.key).routeUri!;
      final destination = uri.queryParameters['destination']!
          .split(',')
          .map(double.parse)
          .toList();
      expect(destination[0], closeTo(entry.value[0], 1e-8));
      expect(destination[1], closeTo(entry.value[1], 1e-8));
    }
  });

  test('unverified entrance fields never override the geographic fallback', () {
    final records = jsonDecode(fixture) as List;
    for (final code in ['APB', 'BAR']) {
      final record = records.singleWhere((b) => b['krz'] == code) as Map;
      final original = CampusFeature.fromJson(record)!;
      for (final entrances in [
        null,
        [],
        [
          {'x': 100, 'y': 200, 'name': 'Haupteingang'}
        ],
        [
          {'x': 13.0, 'y': 51.0, 'name': 'Unverified'}
        ]
      ]) {
        final building =
            CampusFeature.fromJson({...record, 'eingänge': entrances})!;
        expect(building.routeUri, original.routeUri);
        final uri = building.routeUri!;
        expect(uri.scheme, 'https');
        expect(uri.host, 'www.google.com');
        expect(uri.path, '/maps/dir/');
        expect(uri.queryParameters['api'], '1');
        expect(uri.queryParameters['travelmode'], 'walking');
        expect(uri.queryParameters.containsKey('origin'), isFalse);
        expect(Uri.parse(uri.toString()), uri);
      }
    }
  });

  test('German building codes are retained exactly, never transliterated', () {
    final record = (jsonDecode(fixture) as List).first as Map;
    for (final code in ['GÖR', 'MÜL', 'HÜL', 'DÜR', 'WÜR']) {
      final feature = CampusFeature.fromJson({...record, 'krz': code})!;
      expect(feature.code, code);
      expect(feature.floorCode, code.toLowerCase());
      final floorCode = feature.floorCode;
      expect(
          buildingFloorQuery(
              '<a href="/etplan/${Uri.encodeComponent(floorCode)}/00">Plan</a>',
              floorCode),
          '$floorCode/00');
    }
  });

  CampusCatalog catalog(
          {Future<CachedCampusData?> Function()? read,
          Future<String> Function()? fetch,
          Future<void> Function(String)? write}) =>
      CampusCatalog(
          readCache: read ?? () async => null,
          fetch: fetch ?? () async => fixture,
          writeCache: write ?? (_) async {});

  test('fresh persistent cache avoids a network request', () async {
    var requests = 0;
    final c = catalog(
        read: () async => CachedCampusData(
            fixture, DateTime.now().add(const Duration(hours: 2))),
        fetch: () async {
          requests++;
          return fixture;
        });
    await c.load();
    expect(c.buildings.length, 3);
    expect(requests, 0);
    expect(c.stale, isFalse);
    c.dispose();
  });

  test('expired cache appears while network pending; failure retains it',
      () async {
    final response = Completer<String>();
    final c = catalog(
        read: () async => CachedCampusData(fixture, DateTime(2020)),
        fetch: () => response.future);
    final load = c.load();
    await Future<void>.delayed(Duration.zero);
    expect(c.buildings.length, 3);
    expect(c.busy, isTrue);
    expect(c.stale, isTrue);
    response.completeError(const SocketException('offline'));
    await load;
    expect(c.buildings.length, 3);
    expect(c.failed, isTrue);
    expect(c.busy, isFalse);
    c.dispose();
  });

  test('invalid network payload does not overwrite usable disk cache',
      () async {
    var writes = 0;
    final c = catalog(
        read: () async => CachedCampusData(fixture, DateTime(2020)),
        fetch: () async => '<html>unavailable</html>',
        write: (_) async {
          writes++;
        });
    await c.load();
    expect(writes, 0);
    expect(c.buildings.length, 3);
    expect(c.failed, isTrue);
    c.dispose();
  });

  test('corrupt cache recovers from network; disk write failure is observable',
      () async {
    final c = catalog(
        read: () async => CachedCampusData('{', DateTime(2020)),
        write: (_) async => throw const FileSystemException('full'));
    await c.load();
    expect(c.buildings.length, 3);
    expect(c.failed, isFalse);
    expect(c.cacheWriteFailed, isTrue);
    c.dispose();
  });

  test('parallel refresh is coalesced; empty offline start exposes failure',
      () async {
    var requests = 0;
    final response = Completer<String>();
    final c = catalog(fetch: () {
      requests++;
      return response.future;
    });
    final first = c.load();
    await c.load(refresh: true);
    response.completeError(const SocketException('offline'));
    await first;
    expect(requests, 1);
    expect(c.failed, isTrue);
    expect(c.buildings, isEmpty);
    c.dispose();
  });

  test('disposing during disk read does not start new network work', () async {
    final disk = Completer<CachedCampusData?>();
    var requests = 0;
    final c = catalog(
        read: () => disk.future,
        fetch: () async {
          requests++;
          return fixture;
        });
    final load = c.load();
    c.dispose();
    disk.complete(null);
    await load;
    expect(requests, 0);
  });
}
