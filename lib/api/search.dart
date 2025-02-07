import 'dart:convert';

import 'package:campus_navigator/api/networking.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

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
      assist: json['assist'],
      assist2: json['assist2'],
      resultsBuildings: SearchResultObject.listFromJson(json['results_geb']),
      resultsRooms: SearchResultObject.listFromJson(json['results_raum']),
      moreBuildings: json['more_geb'],
      moreRooms: json['more_raum'],
      trenn: json['trenn'],
    );
  }

  static Future<SearchResult> searchRoom(String query) async {
    final uri = Uri.parse('$baseURL/search');
    var map = {'query': query, 'from': "/", 'geocode': '1'};

    // Search result caching
    String body;
    final cacheKey = "${uri.toString()} - ${jsonEncode(map)}";
    final cachedData = await DefaultCacheManager().getFileFromCache(cacheKey);
    if (cachedData != null) {
      body = await cachedData.file.readAsString();
    } else {
      final response = await http.post(uri, body: map);

      if (response.statusCode != 200) {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        throw Exception('Failed to load search results');
      }

      body = response.body;
      await DefaultCacheManager().putFile(cacheKey, utf8.encode(body),
          fileExtension: 'json',
          maxAge: (await APIServices.Shared.storage.getCacheDuration()).value);
    }

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

  const SearchResultObject({
    required this.name,
    required this.subName,
    required this.identifier,
  });

  factory SearchResultObject.fromJson(List<dynamic> json) {
    final nameMatches = roomResultExp.firstMatch(json[0] as String)!;
    final name = nameMatches[1]!;
    final subName = nameMatches[3];

    return SearchResultObject(
      name: name,
      subName: subName,
      identifier: json[1],
    );
  }

  static listFromJson(List<dynamic> json) {
    return json
        .map((jsonEntry) => SearchResultObject.fromJson(jsonEntry))
        .toList();
  }
}
