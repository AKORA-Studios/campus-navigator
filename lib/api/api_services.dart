import 'package:campus_navigator/api/login.dart';
import 'package:campus_navigator/api/networking.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

abstract class NavigatorCacheManager extends CacheManager
    with ImageCacheManager {
  NavigatorCacheManager(super.config);
}

class APIServices {
  static const String loginURL = '$baseURL/api/login';

  http.Client client = http.Client();
  ImageCacheManager cacheManager = DefaultCacheManager();
  Storage storage = Storage.Shared;

  static APIServices Shared = APIServices();

  APIServices();

  APIServices.fromMock({required this.client});

  Future<LoginResponse> postLogin() async {
    return await LoginResponse.postLogin(client);
  }
}
