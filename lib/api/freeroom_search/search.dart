import 'dart:convert';

import 'package:campus_navigator/api/freeroom_search/room_links.dart';
import 'package:campus_navigator/api/freeroom_search/search_options.dart';
import 'package:campus_navigator/api/freeroom_search/search_result.dart';
import 'package:campus_navigator/api/networking.dart';
import 'package:http/http.dart' as http;

import '../storage.dart';

Future<FreeroomSearchResult> searchFreeRooms(
    {required int startWeek,
    required int endWeek,
    required Set<UserUniversity> universities,
    int minCapacity = -1,
    int maxCapacity = -1,
    Repetition repetition = Repetition.once,
    http.Client? httpClient}) async {
  final client = httpClient ?? http.Client();
  final uri =
      Uri.parse("https://navigator.tu-dresden.de/huefm/ajax_findfreerooms");

  String type;
  if (universities.length == 2) {
    type = "0";
  } else {
    type = universities.first.toString();
  }

  final response = await client.post(uri, body: {
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

Future<RoomLinks> listBuildingRoomLinks(String building,
    {http.Client? httpClient}) async {
  final client = httpClient ?? http.Client();
  final uri =
      Uri.parse("https://navigator.tu-dresden.de/export/search/$building");

  final responseText = await cachedStringRequest(uri,
      requestFunction: (uri) => client.post(uri), fileExtension: 'json');

  if (responseText == null) {
    throw Exception("brug");
  }

  return RoomLinks.fromJson(jsonDecode(responseText));
}

/// Returns the links to all lecture rooms?
/// Example: roomLink("MER", "MER/0003/U") = ["https://navigator.tu-dresden.de/etplan/mer/00/raum/143100.0280"]
Future<List<String>> fetchRoomLink(String building, String formalRoomName,
    {http.Client? httpClient}) async {
  final client = httpClient ?? http.Client();
  final uri = Uri.parse(
      "https://navigator.tu-dresden.de/export/findroomurl/$building/$formalRoomName");

  final responseText = await cachedStringRequest(uri,
      requestFunction: (uri) => client.post(uri), fileExtension: 'json');

  if (responseText == null) {
    throw Exception("brug");
  }

  final decoded = jsonDecode(responseText) as Map<String, dynamic>;
  final foundRoom = decoded["foundRoom"] as List<dynamic>;

  return foundRoom.map((e) => e as String).toList();
}
