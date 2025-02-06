import 'package:campus_navigator/api/login.dart';
import 'package:campus_navigator/api/networking.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:http/http.dart' as http;

import 'freeroom_search/room_links.dart';
import 'freeroom_search/search.dart';
import 'freeroom_search/search_options.dart';
import 'freeroom_search/search_result.dart';

class APIServices {
  static const String loginURL = '$baseURL/api/login';

  http.Client client = http.Client();
  Storage storage = Storage.Shared;

  static APIServices Shared = APIServices();

  APIServices();

  APIServices.fromMock({required this.client});

  Future<LoginResponse> postLogin() async {
    return await LoginResponse.postLogin(client);
  }

  Future<FreeroomSearchResult> searchFreeRooms(
      {required int startWeek,
      required int endWeek,
      required Set<UserUniversity> universities,
      int minCapacity = -1,
      int maxCapacity = -1,
      Repetition repetition = Repetition.once}) {
    return FreeroomSearchResult_APIExtension.searchFreeRooms(
        endWeek: endWeek,
        startWeek: startWeek,
        universities: universities,
        minCapacity: minCapacity,
        maxCapacity: maxCapacity,
        repetition: repetition,
        httpClient: client);
  }

  Future<RoomLinks> listBuildingRoomLinks(String building) async {
    return FreeroomSearchResult_APIExtension.listBuildingRoomLinks(
        building, client);
  }

  Future<List<String>> fetchRoomLink(
      String building, String formalRoomName) async {
    return FreeroomSearchResult_APIExtension.fetchRoomLink(
        building, formalRoomName, client);
  }
}
