import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'search.dart';
import 'storage.dart';

enum PlaceKind { room, building }

/// Names are presentation only. Navigation and deduplication use server IDs.
class SavedPlace {
  final PlaceKind kind;
  final String identifier;
  final String name;
  final String? subName;

  SavedPlace(
      {required this.kind,
      required this.identifier,
      required this.name,
      this.subName}) {
    final pattern = kind == PlaceKind.room
        ? r'^[\p{L}\p{N}_-]+/[\p{L}\p{N}_-]+/raum/[\p{L}\p{N}_.-]+$'
        : r'^[\p{L}\p{N}_-]+/geb/[\p{L}\p{N}_-]+$';
    if (!RegExp(pattern, unicode: true).hasMatch(identifier) ||
        name.trim().isEmpty) {
      throw const FormatException('Invalid place');
    }
  }

  factory SavedPlace.fromSearch(SearchResultObject result, PlaceKind kind) =>
      SavedPlace(
          kind: kind,
          identifier: result.identifier,
          name: result.name,
          subName: result.subName);

  static SavedPlace? tryFromSearch(SearchResultObject result, PlaceKind kind) {
    try {
      return SavedPlace.fromSearch(result, kind);
    } on FormatException {
      return null;
    }
  }

  List<String> get parts => identifier.split('/');
  String get buildingCode => kind == PlaceKind.room ? parts.first : parts.last;
  String? get roomId => kind == PlaceKind.room ? parts.last : null;
  String get key => kind == PlaceKind.room
      ? 'room:$buildingCode:$roomId'
      : 'building:${parts.first}:$buildingCode';
  String? get floor => kind == PlaceKind.room ? parts[1] : null;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'identifier': identifier,
        'name': name,
        if (subName != null) 'subName': subName,
      };

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
      kind: PlaceKind.values.byName(json['kind'] as String),
      identifier: json['identifier'] as String,
      name: json['name'] as String,
      subName: json['subName'] as String?);
}

/// One versioned local document; each write commits a complete snapshot.
/// Queued mutations always use the latest committed state, even on rapid taps.
class PlaceStore extends ChangeNotifier {
  static const storageKey = 'SavedPlaces.v1';
  static const historyLimit = 20;
  final Future<String?> Function() _read;
  final Future<void> Function(String) _write;
  List<SavedPlace> _favorites = [];
  List<SavedPlace> _recent = [];
  Future<void>? _loading;
  Future<void> _writes = Future.value();
  int _pending = 0;
  bool _disposed = false;
  bool ready = false;
  bool loadFailed = false;

  PlaceStore(
      {Future<String?> Function()? read, Future<void> Function(String)? write})
      : _read = read ?? (() => Storage.Shared.storage.read(key: storageKey)),
        _write = write ??
            ((value) =>
                Storage.Shared.storage.write(key: storageKey, value: value));

  List<SavedPlace> get favorites => List.unmodifiable(_favorites);
  List<SavedPlace> get recent => List.unmodifiable(_recent);
  bool get loading => _loading != null;
  bool get saving => _pending > 0;
  bool contains(SavedPlace place) => _favorites.any((p) => p.key == place.key);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() {
    if (_loading != null) return _loading!;
    // Schedule the read so loading is observable even for synchronous failures.
    _loading = Future<void>.microtask(() async {
      try {
        final raw = await _read();
        final data = raw == null ? null : jsonDecode(raw);
        if (data != null &&
            (data is! Map ||
                data['version'] != 1 ||
                data['favorites'] is! List ||
                data['recent'] is! List)) {
          throw const FormatException('Unsupported saved places document');
        }
        List<SavedPlace> decode(dynamic values) {
          final unique = <String, SavedPlace>{};
          for (final value in values as List? ?? []) {
            // A malformed individual record must not hide all valid places.
            try {
              final p = SavedPlace.fromJson(Map<String, dynamic>.from(value));
              unique.putIfAbsent(p.key, () => p);
            } catch (_) {/* Retain other independently valid records. */}
          }
          return unique.values.toList();
        }

        _favorites = decode(data?['favorites']);
        _recent = decode(data?['recent'])
            .where((p) => p.kind == PlaceKind.room)
            .take(historyLimit)
            .toList();
        ready = true;
        loadFailed = false;
      } catch (_) {
        // Keep the original document untouched; retry, never silently reset it.
        loadFailed = true;
      } finally {
        _loading = null;
        _notify();
      }
    });
    _notify();
    return _loading!;
  }

  Future<bool> _commit(
      void Function(List<SavedPlace>, List<SavedPlace>) edit) async {
    if (!ready) await load();
    if (!ready || _disposed) return false;
    _pending++;
    _notify();
    var success = false;
    final operation = _writes.then((_) async {
      final favorites = List<SavedPlace>.of(_favorites);
      final recent = List<SavedPlace>.of(_recent);
      edit(favorites, recent);
      try {
        await _write(jsonEncode({
          'version': 1,
          'favorites': favorites.map((p) => p.toJson()).toList(),
          'recent': recent.map((p) => p.toJson()).toList()
        }));
        _favorites = favorites;
        _recent = recent;
        success = true;
      } catch (_) {
        /* Failed writes never claim a favorite was saved. */
      } finally {
        _pending--;
        _notify();
      }
    });
    _writes = operation;
    await operation;
    return success;
  }

  Future<bool> toggle(SavedPlace place) => _commit((favorites, recent) {
        if (favorites.any((p) => p.key == place.key)) {
          favorites.removeWhere((p) => p.key == place.key);
        } else {
          favorites.add(place);
        }
      });

  Future<bool> recordVisit(SavedPlace place) {
    if (place.kind != PlaceKind.room) return Future.value(true);
    return _commit((favorites, recent) {
      recent.removeWhere((p) => p.key == place.key);
      recent.insert(0, place);
      if (recent.length > historyLimit) {
        recent.removeRange(historyLimit, recent.length);
      }
    });
  }

  Future<bool> clearHistory() => _commit((favorites, recent) => recent.clear());

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
