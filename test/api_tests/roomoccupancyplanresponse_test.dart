import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/building/roomOccupancyPlan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../apiservice_mock.dart';

void main() {
  group("[API] LoginTests", () {
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept-Charset": "utf-8",
      "Accept": "application/json",
      "cookie": "loginToken="
    };
    final sut = APIServicesMock();

    test('successfullRequest', () async {
      when(sut.client.get(Uri.parse('${BaseAPIServices.occupancyPlanURL}/0'),
              headers: headers))
          .thenAnswer((_) async => http.Response('{"loginToken": "123"}', 200));

      expect(await sut.getRoomPlan("0"), isA<List>());
    });

    test('serverException', () async {
      when(sut.client.get(Uri.parse('${BaseAPIServices.occupancyPlanURL}/0'),
              headers: headers))
          .thenAnswer((_) async => http.Response('Not Found', 500));
      expect(sut.getRoomPlan("0"), throwsException);
    });
  });
}
