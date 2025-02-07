import 'package:campus_navigator/api/api_services.dart';

import 'storage_mock.dart';
import 'widget_test.mocks.dart';

class APIServicesMock extends BaseAPIServices {
  APIServicesMock() {
    client = MockClient2();
    storage = StorageMock();
  }
}
