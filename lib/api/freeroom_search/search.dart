import 'dart:convert';

import 'package:campus_navigator/api/freeroom_search/search_options.dart';
import 'package:campus_navigator/api/freeroom_search/search_result.dart';
import 'package:http/http.dart';

import '../storage.dart';

Future<FreeroomSearchResult> searchFreeRooms(
    {required int startWeek,
    required int endWeek,
    required Set<UserUniversity> universities,
    int minCapacity = -1,
    int maxCapacity = -1,
    Repetition repetition = Repetition.once}) async {
  final uri =
      Uri.parse("https://navigator.tu-dresden.de/huefm/ajax_findfreerooms");

  String type;
  if (universities.length == 2) {
    type = "0";
  } else {
    type = universities.first.toString();
  }

  final response = await post(uri, body: {
    "startwoche": startWeek.toString(),
    "endwoche": endWeek.toString(),
    "type": repetition.serialize(),
    "mincapacity": minCapacity.toString(),
    "maxcapacity": maxCapacity.toString(),
    "hochschule": type,
  });

  if (response.statusCode != 200) {
    throw Exception("brug");
  }

  return FreeroomSearchResult.fromJson(jsonDecode(response.body));
}
