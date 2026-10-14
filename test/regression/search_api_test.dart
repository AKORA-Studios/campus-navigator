import 'dart:convert';

import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/search.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('full search matches the TU extended-search form and preserves details',
      () async {
    final api = APIServices.withoutCache();
    var requestCount = 0;
    api.client = MockClient((request) async {
      requestCount++;
      expect(request.method, 'POST');
      expect(request.url.path, '/search');
      expect(request.bodyFields,
          {'query': 'APB E069', 'fullresults': '1', 'roomtype': ''});
      return http.Response(
          jsonEncode({
            'assist': '',
            'assist2': '',
            'results_geb': [],
            'results_raum': [
              [
                'APB E069 <span class=\'sml\'>(APB/E069/P)</span>',
                'apb/00/raum/542100.2860',
                'Andreas-Pfitzmann-Bau (Etage 0)'
              ],
              ['malformed'],
              ['APB E068', 'apb/00/raum/542100.2850']
            ],
            'more_geb': false,
            'more_raum': false,
            'trenn': 0
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    APIServices.Shared = api;

    final result = await SearchResult.searchAll('APB E069');

    expect(requestCount, 1);
    expect(result.resultsRooms, hasLength(2));
    expect(result.resultsRooms.first.name, 'APB E069');
    expect(result.resultsRooms.first.subName, 'APB/E069/P');
    expect(result.resultsRooms.first.detail, 'Andreas-Pfitzmann-Bau (Etage 0)');
    expect(result.resultsRooms.last.name, 'APB E068');
  });

  test('glued German Bau compound retries with a searchable word boundary',
      () async {
    final api = APIServices.withoutCache();
    final queries = <String>[];
    api.client = MockClient((request) async {
      final query = request.bodyFields['query']!;
      queries.add(query);
      if (query == 'Hülße Bau') {
        return http.Response(
            jsonEncode({
              'results_geb': [
                ['Hülße-Bau', 'dresden/geb/hül']
              ],
              'results_raum': [],
              'more_geb': false,
              'more_raum': false
            }),
            200);
      }
      return http.Response(
          jsonEncode({
            'results_geb': [],
            'results_raum': [],
            'more_geb': false,
            'more_raum': false
          }),
          200);
    });
    APIServices.Shared = api;

    final result = await SearchResult.searchRoom('Hülßebau');

    expect(queries, ['Hülßebau', 'Hülße Bau']);
    expect(result.resultsBuildings.single.identifier, 'dresden/geb/hül');
  });

  test('server more flags and malformed rows are decoded independently', () {
    final result = SearchResult.fromJson({
      'assist': null,
      'assist2': 'BEY',
      'results_geb': [
        ['Beyer-Bau', 'dresden/geb/bey'],
        ['missing identifier'],
      ],
      'results_raum': [
        ['BEY 318', 'bey/03/raum/111103.5220'],
        7,
        [' ', ''],
      ],
      'more_geb': true,
      'more_raum': true,
      'trenn': 2.0,
    });

    expect(result.assist, isEmpty);
    expect(result.resultsBuildings, hasLength(1));
    expect(result.resultsRooms, hasLength(1));
    expect(result.moreBuildings, isTrue);
    expect(result.moreRooms, isTrue);
    expect(result.trenn, 2);
  });
}
