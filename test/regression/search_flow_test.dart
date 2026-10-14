import 'dart:async';
import 'dart:convert';
import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:campus_navigator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'networking_test.dart' show TestCache, NetworkStorage;

class SearchStorage extends NetworkStorage {
  @override
  Future<PrefetchingLevel> getPrefetchingLevel() async => PrefetchingLevel.none;
}

String response(String title, String id) => jsonEncode({
      'assist': '',
      'assist2': '',
      'results_geb': [],
      'results_raum': [
        [title, 'test/00/raum/$id']
      ],
      'more_geb': false,
      'more_raum': false,
      'trenn': 0,
    });

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('typing is debounced and stale search results cannot be selected',
      (tester) async {
    final first = Completer<http.Response>();
    var requests = 0;
    APIServices.Shared = APIServices.withoutCache()
      ..cacheManager = TestCache()
      ..storage = SearchStorage()
      ..client = MockClient((request) {
        requests++;
        if (requests == 1) return first.future;
        return Future.value(http.Response(response('BEY 318', 'test.318'), 200,
            headers: {'content-type': 'text/html; charset=utf-8'}));
      });
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextField), 'APB');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'APB E069');
    await tester.pump(const Duration(milliseconds: 300));
    expect(requests, 0);
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pump();
    expect(requests, 1);
    await tester.enterText(find.byType(TextField), 'BEY 318');
    first.complete(http.Response(response('APB E069', 'test.old'), 200));
    await tester.pump();
    await tester.pump();
    expect(find.text('APB E069'), findsNothing);
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(
        find.descendant(
            of: find.byType(ListTile), matching: find.text('BEY 318')),
        findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);
    expect(requests, 2);
    await tester.pumpWidget(const SizedBox());
  });
}
