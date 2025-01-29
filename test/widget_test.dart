import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';

import './api_tests/loginresponse_test.dart' as loginresponseTest;
import './ui_tests/searchscreen_test.dart' as searchscreenTest;

@GenerateMocks([http.Client])
void main() {
  loginresponseTest.main();
  searchscreenTest.main();
}
