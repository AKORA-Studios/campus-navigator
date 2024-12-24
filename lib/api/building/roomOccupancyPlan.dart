import 'package:campus_navigator/api/building/parsing/common.dart';
import 'package:campus_navigator/api/building/room_page.dart';
import 'package:http/http.dart' as http;

class RoomOccupancyPlan {
  final String table;
  static List<String> tableNames = [];

  const RoomOccupancyPlan({
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

  static Future<List<List<List<String>>>> getRoomPlan(String roomID,
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

  static List<List<List<String>>> getTableContentFromBody(String body) {
    var htmlDocument = HTMLData.fromBody(body).document;
    RoomOccupancyPlan.tableNames = [];

    final allTables = htmlDocument.querySelectorAll("table");
    allTables.removeAt(0);

    List<List<List<String>>> x = [];

    // Parse Table into array
    for (final tableBody in allTables) {
      if (tableBody.previousElementSibling != null) {
        tableNames.add(tableBody.previousElementSibling!.text);
      } else {
        tableNames.add("No Table Name found");
      }

      // table
      List<List<String>> entries =
          []; // Uhrzeit: Tag1Vorlesung, Tag2Vorlesung,.. Tag7Vorlesung
      for (var trTag in tableBody.children) {
        // tbody
        for (var y in trTag.children) {
          // tr
          List<String> rowEntries = [];
          for (var th in y.children) {
            if (th.children.length > 1) {
              /*
              div: title
              span: Person, Fach
              */
              // print("th: $th, ${th.children[0].text}");
              rowEntries.add(th.children[0].text);
            } else {
              rowEntries.add(th.text);
            }
          }
          if (rowEntries.sublist(1).join("").isNotEmpty) {
            entries.add(rowEntries);
          }
        }
      }
      x.add(entries);
    }
    return x;
  }
}
