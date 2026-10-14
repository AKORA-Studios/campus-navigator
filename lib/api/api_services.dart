import 'dart:async';
import 'dart:collection';

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

  APIServices.withoutCache() : super();
}

class BaseAPIServices {
  static const String loginURL = '$baseURL/api/login';
  static const String occupancyPlanURL = '$baseURL/raum';

  http.Client client = http.Client();
  ImageCacheManager? cacheManager;
  Storage storage = Storage.Shared;

  BaseAPIServices({this.cacheManager});

  // Share response bytes, never decoded images: each floor owns its images.
  final Map<String, Future<List<int>?>> pendingImages = {};
  final Map<String, Future<String?>> pendingStrings = {};
  final tileRequests = RequestLimiter(4);

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

/// Bound HTTP work across the original floor and a newly opened floor.
class RequestLimiter {
  final int limit;
  int _active = 0;
  final Queue<Completer<void>> _waiting = Queue();
  RequestLimiter(this.limit);
  Future<T> run<T>(Future<T> Function() task) async {
    if (_active >= limit) {
      final turn = Completer<void>();
      _waiting.add(turn);
      await turn.future;
    } else {
      _active++;
    }
    try {
      return await task();
    } finally {
      if (_waiting.isNotEmpty) {
        _waiting.removeFirst().complete();
      } else {
        _active--;
      }
    }
  }
}
