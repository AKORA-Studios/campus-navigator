import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class DefaultCacheManagerMock extends CacheManager with ImageCacheManager {
  DefaultCacheManagerMock() : super(Config("uwu"));
}
