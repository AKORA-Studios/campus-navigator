import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';

import './api_tests/loginresponse_test.dart' as loginresponseTest;
import './api_tests/roomoccupancyplanresponse_test.dart'
    as roomoccupancyplanresponseTest;
import './api_tests/searchresponse_test.dart' as searchresponseTest;
import './ui_tests/searchscreen_test.dart' as searchscreenTest;

@GenerateMocks([http.Client])
void main() {
  loginresponseTest.main();
  searchresponseTest.main();
  roomoccupancyplanresponseTest.main();

  searchscreenTest.main();
}
