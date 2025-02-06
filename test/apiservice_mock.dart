import 'package:campus_navigator/api/api_services.dart';

import 'cachemanager_mock.dart';
import 'storage_mock.dart';
import 'widget_test.mocks.dart';

class APIServicesMock extends APIServices {
  APIServicesMock() {
    client = MockClient2();
    cacheManager = DefaultCacheManagerMock();
    storage = StorageMock();
  }
}
