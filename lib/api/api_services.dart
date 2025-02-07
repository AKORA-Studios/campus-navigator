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
  static const String occupancyPlanURL = '$baseURL/raum';

  http.Client client = http.Client();
  ImageCacheManager? cacheManager;
  Storage storage = Storage.Shared;

  BaseAPIServices({ImageCacheManager? cacheManager}) {
    cacheManager = cacheManager;
  }

  String generateCookieHeader(Map<String, String> cookies) {
    String cookie = "";

    for (var key in cookies.keys) {
      if (cookie.isNotEmpty) cookie += ";";
      cookie += key + "=" + cookies[key]!;
    }

    return cookie;
  }

  Map<String, String> generatePostHeader(String token) {
    Map<String, String> cookies = {
      'loginToken': token,
    };

    return {
      "Content-Type": "application/json",
      "Accept-Charset": "utf-8",
      "Accept": "application/json",
      "cookie": generateCookieHeader(cookies),
    };
  }
}
