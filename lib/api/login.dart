import 'dart:convert';

import 'package:campus_navigator/api/storage.dart';
import 'package:http/http.dart' as http;

import 'networking.dart';

class LoginResponse {
  final String loginToken;
  //final String JSESSIONID;

  const LoginResponse({required this.loginToken});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      loginToken: json['loginToken'],
    );
  }

  static Future<LoginResponse> postLogin() async {
    String? user = await Storage.Shared.getUsername();
    String? passwd = await Storage.Shared.getPassword();
    var x = await Storage.Shared.getUniversity();
    int university = int.parse(x.value.toString());

    if (user == null) {
      throw Exception('Failed to login: No Username set');
    }

    if (passwd == null) {
      throw Exception('Failed to login: No Password set');
    }

    //application/x-www-form-urlencoded;charset=UTF-8
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept-Charset": "utf-8",
      "Accept": "application/json"
    };

    Codec<String, String> stringToBase64 = utf8.fuse(base64);

    var jsonBody = {
      'username': stringToBase64.encode(user.trim()),
      'password': stringToBase64.encode(passwd.trim()),
      'university': university,
      'from': "/"
    };
    final uri = Uri.parse('$baseURL/api/login');

    final response =
        await http.post(uri, headers: headers, body: jsonEncode(jsonBody));

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else {
      print(response.body);
      String? msg = json.decode(response.body)["message"];
      throw Exception('Failed to login: $msg');
    }
  }
}
