import 'dart:convert';

import 'package:campus_navigator/api/building/parsing/common.dart';
import 'package:http/http.dart' as http;

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
    final response = await http.post(uri, body: map);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return SearchResult.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load search results');
    }
  }
}

class SearchResultObject {
  final String name;
  final String identifier;

  const SearchResultObject({
    required this.name,
    required this.identifier,
  });

  factory SearchResultObject.fromJson(List<dynamic> json) {
    String name = json[0];
    name = name
        .replaceAll(" <span class='sml'>(", " | ")
        .replaceAll(")</span>", "");

    return SearchResultObject(
      name: name,
      identifier: json[1],
    );
  }

  static listFromJson(List<dynamic> json) {
    return json
        .map((jsonEntry) => SearchResultObject.fromJson(jsonEntry))
        .toList();
  }
}
