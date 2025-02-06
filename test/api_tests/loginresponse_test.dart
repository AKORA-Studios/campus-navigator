import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/login.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../widget_test.mocks.dart';

void main() {
  group("[API] LoginTests", () {
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept-Charset": "utf-8",
      "Accept": "application/json"
    };

    final client = MockClient2();
    final sut = APIServices.fromMock(client: client);

    test('successfullRequest', () async {
      when(client.post(Uri.parse(APIServices.loginURL),
              headers: headers, body: {}, encoding: null))
          .thenAnswer((_) async => http.Response('{"loginToken": "123"}', 200));

      expect(await sut.postLogin(), isA<LoginResponse>());
    });

    test('siteAvailability', () async {
      when(client.post(Uri.parse(APIServices.loginURL),
              headers: headers, body: {}, encoding: null))
          .thenAnswer((_) async => http.Response('Not Found', 404));
      expect(sut.postLogin(), throwsException);
    });

    test('serverException', () async {
      when(client.post(Uri.parse(APIServices.loginURL),
              headers: headers, body: {}, encoding: null))
          .thenAnswer((_) async => http.Response('Not Found', 500));
      expect(sut.postLogin(), throwsException);
    });
  });
}
