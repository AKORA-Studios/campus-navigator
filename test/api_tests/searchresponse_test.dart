import 'package:campus_navigator/api/api_services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../widget_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group("[API] SearchTest", () {
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept-Charset": "utf-8",
      "Accept": "application/json"
    };

    final client = MockClient2();
    final sut = APIServices.fromMock(client: client);

    test('successfullRequest - fetchRoomLink', () async {
      when(client.post(
              Uri.parse(
                  "https://navigator.tu-dresden.de/export/findroomurl/f/f"),
              headers: headers,
              body: {},
              encoding: null))
          .thenAnswer((_) async => http.Response('{"foundRoom": ["f"]}', 200));

      expect(await sut.fetchRoomLink("f", "f"), isA<List<String>>());
    });
/*
    test('siteAvailability', () async {
      final client = MockClient2();

      when(client.post(Uri.parse(APIServices.loginURL),
              headers: headers, body: {}, encoding: null))
          .thenAnswer((_) async => http.Response('Not Found', 404));
      expect(LoginResponse.postLogin(httpClient: client), throwsException);
    });

    test('serverException', () async {
      final client = MockClient2();

      when(client.post(Uri.parse(APIServices.loginURL),
              headers: headers, body: {}, encoding: null))
          .thenAnswer((_) async => http.Response('Not Found', 500));
      expect(LoginResponse.postLogin(httpClient: client), throwsException);
    });*/
  });
}
