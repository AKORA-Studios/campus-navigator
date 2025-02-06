import 'package:campus_navigator/api/login.dart';
import 'package:campus_navigator/api/networking.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:http/http.dart' as http;

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
}
