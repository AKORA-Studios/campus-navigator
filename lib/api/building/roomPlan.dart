import 'package:campus_navigator/api/building/parsing/common.dart';
import 'package:campus_navigator/api/building/room_page.dart';
import 'package:http/http.dart' as http;

class RoomPlan {
  final String table;

  const RoomPlan({
    required this.table,
  });

  static String _generateCookieHeader(Map<String, String> cookies) {
    String cookie = "";

    for (var key in cookies.keys) {
      if (cookie.length > 0) cookie += ";";
      cookie += key + "=" + cookies[key]!;
    }

    return cookie;
  }

  static Future<List<List<String>>> getRoomPlan(String roomID,
      {String token = ""}) async {
    final uri = Uri.parse('$baseURL/raum/$roomID');

    Map<String, String> cookies = {
      'loginToken': token,
    };

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept-Charset": "utf-8",
      "Accept": "application/json",
      "cookie": _generateCookieHeader(cookies),
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return getTableContentFromBody(response.body);
    } else {
      throw Exception('Failed to load search results');
    }
  }

  static List<List<String>> getTableContentFromBody(String body) {
    var htmlDocument = HTMLData.fromBody(body).document;

    print("--------------------------");

    var allTables = htmlDocument.querySelectorAll("table");
    allTables.removeAt(0);

    List<List<String>> x = [];

    for (var tableBody in allTables) {
      List<String> entries = [];
      for (var trTag in tableBody.children) {
        for (var y in trTag.children) {
          entries.add(y.text);
        }
        print(entries);
      }
      x.add(entries);
    }
    return x;
  }
}
/*
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
}*/
