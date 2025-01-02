import 'dart:convert';

import 'package:campus_navigator/api/freiraumsuche/search_result.dart';
import 'package:http/http.dart';

Future<FreiraumsucheResult> searchFreeRooms() async {
  final uri =
      Uri.parse("https://navigator.tu-dresden.de/huefm/ajax_findfreerooms");
  final response = await post(uri, body: {
    "startwoche": "1",
    "endwoche": "1",
    "type": "1",
    "mincapacity": "1",
    "maxcapacity": "20",
    "hochschule": "0",
  });

  if (response.statusCode != 200) {
    throw Exception("brug");
  }

  return FreiraumsucheResult.fromJson(jsonDecode(response.body));
}
