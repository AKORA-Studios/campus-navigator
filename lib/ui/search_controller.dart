import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/api_services.dart';
import '../api/building/building_page_data.dart';
import '../api/search.dart';
import '../api/storage.dart';

class RoomSearchController extends ChangeNotifier {
  final Future<SearchResult> Function(String) _search;
  final Future<SearchResult> Function(String) _searchAll;
  final bool prefetch;
  Timer? _debounce;
  int _revision = 0;
  bool _disposed = false;
  String query = '';
  SearchResult? result;
  bool loading = false;
  bool failed = false;
  bool fullSearchFailed = false;

  RoomSearchController(
      {Future<SearchResult> Function(String)? search,
      Future<SearchResult> Function(String)? searchAll,
      this.prefetch = true})
      : _search = search ?? SearchResult.searchRoom,
        _searchAll = searchAll ?? SearchResult.searchAll;

  void change(String value, {bool immediately = false}) {
    _debounce?.cancel();
    final revision = ++_revision;
    query = value.trim();
    result = null;
    failed = false;
    fullSearchFailed = false;
    loading = query.isNotEmpty;
    notifyListeners();
    if (query.isEmpty) return;
    if (immediately) {
      _run(query, revision);
    } else {
      _debounce =
          Timer(const Duration(milliseconds: 400), () => _run(query, revision));
    }
  }

  bool _current(int revision) => !_disposed && revision == _revision;

  Future<void> _run(String value, int revision) async {
    try {
      final results = await _search(value);
      if (!_current(revision)) return;
      result = results;
      loading = false;
      notifyListeners();
      if (results.moreRooms || results.moreBuildings) {
        await loadAllResults();
        if (!_current(revision)) return;
      }
      if (!prefetch) return;
      final setting = await APIServices.Shared.storage.getPrefetchingLevel();
      final count = setting == PrefetchingLevel.allResults
          ? 8
          : setting == PrefetchingLevel.firstResult
              ? 1
              : 0;
      for (final entry in results.resultsRooms.take(count)) {
        if (!_current(revision)) break;
        await BuildingPageData.preFetchQuery(entry.identifier);
      }
    } catch (_) {
      if (!_current(revision) || result != null) return;
      loading = false;
      failed = true;
      notifyListeners();
    }
  }

  void retry() => change(query, immediately: true);

  Future<void> loadAllResults() async {
    final revision = _revision;
    if (query.isEmpty || result == null || loading || _disposed) return;
    loading = true;
    fullSearchFailed = false;
    notifyListeners();
    try {
      final results = await _searchAll(query);
      if (!_current(revision)) return;
      result = results;
      loading = false;
      fullSearchFailed = false;
      notifyListeners();
    } catch (_) {
      if (!_current(revision)) return;
      // Keep the initial suggestions usable and let the user retry the full list.
      loading = false;
      fullSearchFailed = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
