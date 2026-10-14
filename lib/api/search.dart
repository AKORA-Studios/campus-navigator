import 'dart:convert';

import 'package:campus_navigator/api/networking.dart';

import 'api_services.dart';

class SearchResult {
  final String assist;
  final String assist2;
  final List<SearchResultObject> resultsBuildings;
  final List<SearchResultObject> resultsRooms;
  // final List<SearchResultObject> resultsGeo;
  final bool moreBuildings;
  final bool moreRooms;
  final int trenn;

  const SearchResult({
    required this.assist,
    required this.assist2,
    required this.resultsBuildings,
    required this.resultsRooms,
    required this.moreBuildings,
    required this.moreRooms,
    required this.trenn,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      assist: json['assist'] is String ? json['assist'] as String : '',
      assist2: json['assist2'] is String ? json['assist2'] as String : '',
      resultsBuildings: SearchResultObject.listFromJson(json['results_geb']),
      resultsRooms: SearchResultObject.listFromJson(json['results_raum']),
      moreBuildings: json['more_geb'] == true,
      moreRooms: json['more_raum'] == true,
      trenn: json['trenn'] is num ? (json['trenn'] as num).toInt() : 0,
    );
  }

  static Future<SearchResult> searchRoom(String query) async {
    final initial =
        await _request({'query': query, 'from': '/', 'geocode': '1'});
    if (initial.resultsBuildings.isNotEmpty ||
        initial.resultsRooms.isNotEmpty ||
        initial.moreBuildings ||
        initial.moreRooms) {
      return initial;
    }

    final alternate = _separateGluedBau(query);
    if (alternate == null) return initial;
    try {
      final result =
          await _request({'query': alternate, 'from': '/', 'geocode': '1'});
      return result.resultsBuildings.isNotEmpty ||
              result.resultsRooms.isNotEmpty
          ? result
          : initial;
    } catch (_) {
      // Keep the successful empty response if an optional spelling retry fails.
      return initial;
    }
  }

  /// Matches the TU Campus Navigator's "Erweiterte Suche" request. The
  /// suggestion endpoint may set more_raum/more_geb and expects a separate
  /// fullresults request to return the complete match list.
  static Future<SearchResult> searchAll(String query) async {
    return _request({
      'query': _separateGluedBau(query) ?? query,
      'fullresults': '1',
      'roomtype': ''
    });
  }

  /// The TU search tokenizes the German compound suffix "Bau", but does not
  /// find a glued form such as "Hülßebau". Retry only that specific empty
  /// search case as "Hülße Bau"; preserve the user's other query text.
  static String? _separateGluedBau(String query) {
    final match = RegExp(r'^(.{2,}?)(bau)$', caseSensitive: false)
        .firstMatch(query.trim());
    if (match == null || RegExp(r'[-\s]$').hasMatch(match.group(1)!)) {
      return null;
    }
    return '${match.group(1)} Bau';
  }

  static Future<SearchResult> _request(Map<String, String> map) async {
    final uri = Uri.parse('$baseURL/search');

    final api = APIServices.Shared;
    final body = await api.cachedStringRequest(uri,
        cacheKey: '${uri.toString()} - ${jsonEncode(map)}',
        fileExtension: 'json',
        requestFunction: (uri) => api.client.post(uri, body: map));
    if (body == null) throw Exception('Failed to load search results');

    // If the server did return a 200 OK response,
    // then parse the JSON.
    return SearchResult.fromJson(jsonDecode(body));
  }
}

/// Used for extracting sub strings in search results
/// `"POT 51 <span class='sml'>(POT/0051/H)</span>"` -> ["POT 51", "POT/0051/H"]
final roomResultExp =
    RegExp(r"([^<]+) ?(<span class='sml'>\(([^\)]+)\)<\/span>)?");

class SearchResultObject {
  final String name;
  final String? subName;
  final String identifier;
  final String? detail;

  const SearchResultObject({
    required this.name,
    required this.subName,
    required this.identifier,
    this.detail,
  });

  factory SearchResultObject.fromJson(List<dynamic> json) {
    if (json.length < 2 || json[0] is! String || json[1] is! String) {
      throw const FormatException('Invalid search result');
    }
    final rawName = json[0] as String;
    final nameMatches = roomResultExp.firstMatch(rawName);
    final name = (nameMatches?[1] ?? rawName).trim();
    final subName = nameMatches?[3];
    final detail = json.length > 2 && json[2] is String
        ? (json[2] as String).trim()
        : null;
    if (name.isEmpty || (json[1] as String).isEmpty) {
      throw const FormatException('Empty search result');
    }

    return SearchResultObject(
      name: name,
      subName: subName,
      identifier: json[1] as String,
      detail: detail == null || detail.isEmpty ? null : detail,
    );
  }

  static List<SearchResultObject> listFromJson(dynamic json) {
    if (json is! List) return const [];
    final results = <SearchResultObject>[];
    for (final entry in json) {
      if (entry is! List) continue;
      try {
        results.add(SearchResultObject.fromJson(entry));
      } on FormatException {
        // Ignore one malformed server record without discarding valid rooms.
      }
    }
    return results;
  }
}
