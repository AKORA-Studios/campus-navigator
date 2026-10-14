import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../api/campus/campus_catalog.dart';
import '../api/campus/campus_tiles.dart';

typedef CacheClearAction = Future<void> Function();
typedef CacheDirectoryProvider = Future<Directory> Function();

/// Clears temporary file caches without touching secure settings or places.
class CacheMaintenance {
  CacheMaintenance({
    List<CacheClearAction>? clearers,
    CacheDirectoryProvider? temporaryDirectory,
  })  : _clearers = clearers ?? _productionClearers,
        _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  static const cacheDirectoryNames = [
    DefaultCacheManager.key,
    'campusOsmTilesV1',
    'campusBuildingsV1',
  ];

  final List<CacheClearAction> _clearers;
  final CacheDirectoryProvider _temporaryDirectory;

  static List<CacheClearAction> get _productionClearers => [
        () => DefaultCacheManager().emptyCache(),
        CampusTileProvider.clearDiskCache,
        CampusCatalog.clearDiskCache,
      ];

  /// Returns `null` if the cache directory cannot be inspected.
  Future<int?> estimateBytes() async {
    try {
      final root = await _temporaryDirectory();
      var bytes = 0;
      for (final name in cacheDirectoryNames) {
        final directory =
            Directory('${root.path}${Platform.pathSeparator}$name');
        if (!await directory.exists()) continue;
        await for (final entity
            in directory.list(recursive: true, followLinks: false)) {
          if (entity is File) bytes += await entity.length();
        }
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Attempts every cache even if one is locked or otherwise unavailable.
  /// Any failures are reported after all clearers have been attempted.
  Future<void> clear() async {
    final errors = <Object>[];
    for (final clear in _clearers) {
      try {
        await clear();
      } catch (error) {
        errors.add(error);
      }
    }
    if (errors.isNotEmpty) throw CacheClearException(errors);
  }
}

class CacheClearException implements Exception {
  const CacheClearException(this.errors);

  final List<Object> errors;

  @override
  String toString() => 'Failed to clear ${errors.length} cache store(s).';
}
