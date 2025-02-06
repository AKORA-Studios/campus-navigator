import 'package:campus_navigator/api/networking.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

abstract class NavigatorCacheManager extends CacheManager
    with ImageCacheManager {
  NavigatorCacheManager(super.config);
}

class APIServices extends BaseAPIServices {
  static APIServices Shared = APIServices();

  APIServices() : super(cacheManager: DefaultCacheManager());
}

class BaseAPIServices {
  static const String loginURL = '$baseURL/api/login';

  http.Client client = http.Client();
  ImageCacheManager? cacheManager;
  Storage storage = Storage.Shared;

  BaseAPIServices({ImageCacheManager? cacheManager}) {
    cacheManager = cacheManager;
  }
}
