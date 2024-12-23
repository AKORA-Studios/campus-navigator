import 'package:campus_navigator/api/building/parsing/common.dart';
import 'package:http/http.dart' as http;

class RoomPlan {
  final String table;

  const RoomPlan({
    required this.table,
  });

  static Future<String> getRoomPlan(String roomID, {String token = ""}) async {
    final uri = Uri.parse('$baseURL/raum/$roomID');

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept-Charset": "utf-8",
      "Accept": "application/json",
      "cookie": token
    };

    final response = await http.post(uri, headers: headers);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return "Aloha!"; //SearchResult.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load search results');
    }
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
