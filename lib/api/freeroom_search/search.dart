import 'dart:convert';

import 'package:campus_navigator/api/freeroom_search/room_links.dart';
import 'package:campus_navigator/api/freeroom_search/search_options.dart';
import 'package:campus_navigator/api/freeroom_search/search_result.dart';
import 'package:campus_navigator/api/networking.dart';
import 'package:http/http.dart' as http;

import '../storage.dart';

extension FreeroomSearchResult_APIExtension on FreeroomSearchResult {
  static Future<FreeroomSearchResult> searchFreeRooms(
      {required int startWeek,
      required int endWeek,
      required Set<UserUniversity> universities,
      required int minCapacity,
      required int maxCapacity,
      required Repetition repetition,
      required http.Client httpClient}) async {
    final uri = Uri.parse("$baseURL/huefm/ajax_findfreerooms");

    String type;
    if (universities.length == 2) {
      type = "0";
    } else {
      type = universities.first.toString();
    }

    final response = await httpClient.post(uri, body: {
      "startwoche": startWeek.toString(),
      "endwoche": endWeek.toString(),
      "type": repetition.serialize(),
      "mincapacity": minCapacity.toString(),
      "maxcapacity": maxCapacity.toString(),
      "hochschule": type,
    });

    if (response.statusCode != 200) {
      throw Exception("bruh");
    }

    return FreeroomSearchResult.fromJson(jsonDecode(response.body));
  }

  static Future<RoomLinks> listBuildingRoomLinks(
      String building, http.Client httpClient) async {
    final uri = Uri.parse("$baseURL/export/search/$building");

    final responseText = await cachedStringRequest(uri,
        requestFunction: (uri) => httpClient.post(uri), fileExtension: 'json');

    if (responseText == null) {
      throw Exception("brug");
    }

    return RoomLinks.fromJson(jsonDecode(responseText));
  }

  /// Returns the links to all lecture rooms?
  /// Example: roomLink("MER", "MER/0003/U") = ["https://navigator.tu-dresden.de/etplan/mer/00/raum/143100.0280"]
  static Future<List<String>> fetchRoomLink(
      String building, String formalRoomName, http.Client httpClient) async {
    final uri =
        Uri.parse("$baseURL/export/findroomurl/$building/$formalRoomName");

    final responseText = await cachedStringRequest(uri,
        requestFunction: (uri) => httpClient.post(uri), fileExtension: 'json');

    if (responseText == null) {
      throw Exception("brug");
    }

    final decoded = jsonDecode(responseText) as Map<String, dynamic>;
    final foundRoom = decoded["foundRoom"] as List<dynamic>;

    return foundRoom.map((e) => e as String).toList();
  }
}
