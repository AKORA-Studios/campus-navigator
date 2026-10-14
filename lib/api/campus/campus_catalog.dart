import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'campus_building.dart';

const campusBuildingsUrl =
    'https://navigator.tu-dresden.de/m/json_gebaeude/all';

class CachedCampusData {
  final String body;
  final DateTime validTill;
  CachedCampusData(this.body, this.validTill);
}

/// Dedicated public-data cache: never shares credentials, floor cache policy,
/// favorites storage or prefetch settings with the existing API layer.
class CampusCatalog extends ChangeNotifier {
  static final _cache = CacheManager(Config('campusBuildingsV1',
      stalePeriod: const Duration(days: 365), maxNrOfCacheObjects: 2));
  static Future<void> clearDiskCache() => _cache.emptyCache();

  final Future<CachedCampusData?> Function() _read;
  final Future<String> Function() _fetch;
  final Future<void> Function(String) _write;
  List<CampusFeature> buildings = const [];
  bool busy = false;
  bool failed = false;
  bool stale = false;
  bool cacheWriteFailed = false;
  bool _disposed = false;

  CampusCatalog({
    Future<CachedCampusData?> Function()? readCache,
    Future<String> Function()? fetch,
    Future<void> Function(String)? writeCache,
  })  : _read = readCache ?? _readDisk,
        _fetch = fetch ?? _download,
        _write = writeCache ?? _writeDisk;

  static Future<CachedCampusData?> _readDisk() async {
    final info = await _cache.getFileFromCache(campusBuildingsUrl);
    return info == null
        ? null
        : CachedCampusData(await info.file.readAsString(), info.validTill);
  }

  static Future<String> _download() async {
    final client = http.Client();
    try {
      final response =
          await client.get(Uri.parse(campusBuildingsUrl), headers: {
        'Accept': 'application/json',
        'User-Agent':
            'CampusNavigator/1.2 (+https://github.com/Infinizius/campus-navigator)',
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 ||
          response.bodyBytes.length > 8 * 1024 * 1024) {
        throw const FormatException('Building catalog unavailable');
      }
      // http honors the TU's declared ISO-8859-1 charset, including umlauts.
      return response.body;
    } finally {
      client.close();
    }
  }

  static Future<void> _writeDisk(String body) async {
    await _cache.putFile(campusBuildingsUrl, utf8.encode(body),
        maxAge: const Duration(days: 1), fileExtension: 'json');
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({bool refresh = false}) async {
    if (busy || _disposed) return;
    busy = true;
    failed = false;
    _notify();
    try {
      if (buildings.isEmpty) {
        try {
          final cached = await _read();
          if (_disposed) return;
          if (cached != null) {
            buildings = parseCampusBuildings(cached.body);
            stale = !cached.validTill.isAfter(DateTime.now());
            _notify();
            if (!stale && !refresh) return;
          }
        } catch (_) {/* Corrupt/missing cache must not stop the basemap. */}
      }
      final body = await _fetch();
      if (_disposed) return;
      final parsed = parseCampusBuildings(body);
      buildings = parsed;
      stale = false;
      cacheWriteFailed = false;
      _notify();
      try {
        await _write(body);
      } catch (_) {
        cacheWriteFailed = true;
      }
    } catch (_) {
      failed = true;
      stale = buildings.isNotEmpty;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
