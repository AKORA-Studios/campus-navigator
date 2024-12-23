import 'dart:convert';

import 'package:http/http.dart' as http;

import 'building/parsing/common.dart';

class LoginResponse {
  final String loginToken;

  const LoginResponse({required this.loginToken});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      loginToken: json['loginToken'],
    );
  }

  static Future<LoginResponse> postLogin(
      String username, String password) async {
    String user = "";
    String passwd = "";
    int university = 1; //1=TUD, 2=HTW

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
      // TODO: create cookie, save cookie
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else {
      print(response.body);
      throw Exception('Failed to login');
    }
  }
}
