import 'package:html/parser.dart';

import '../api_services.dart';

class RoomOccupancyPlan {
  final String table;
  static List<String> tableNames = [];

  const RoomOccupancyPlan({
    required this.table,
  });

  static List<List<List<String>>> getTableContentFromBody(String body) {
    var htmlDocument = parse(body);
    RoomOccupancyPlan.tableNames = [];

    final allTables = htmlDocument.querySelectorAll("table");
    if (allTables.length < 1) {
      print("Warning: No Tables in Room OccupancyTable");
      return [];
    }
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
      if (entries.isNotEmpty) {
        x.add(entries);
      }
    }
    return x;
  }
}

extension RoomOccupancyPlanresponseAPIExtension on BaseAPIServices {
  /// Fetches the rooms, by [id], occupancy Plan to parse
  Future<List<List<List<String>>>> getRoomPlan(String roomID,
      [String token = "", String locale = "de"]) async {
    final uri = Uri.parse(
        '${BaseAPIServices.occupancyPlanURL}/$roomID${locale == "en" ? "?language=en" : ""}');

    Map<String, String> headers = generatePostHeader(token);

    final response = await client.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return RoomOccupancyPlan.getTableContentFromBody(response.body);
    } else {
      throw Exception('Failed to load search results');
    }
  }
}
