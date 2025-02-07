import 'dart:convert';

import 'package:campus_navigator/api/api_services.dart';

class LoginResponse {
  final String loginToken;
  //final String JSESSIONID;

  const LoginResponse({required this.loginToken});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      loginToken: json['loginToken'],
    );
  }
}

extension LoginresponseAPIExtension on BaseAPIServices {
  Future<LoginResponse> postLogin() async {
    String? user = await storage.getUsername();
    String? passwd = await storage.getPassword();
    var x = await storage.getUniversity();
    int university = int.parse(x.value.toString());

    if (user == null) {
      throw Exception('Failed to login: No Username set');
    }

    if (passwd == null) {
      throw Exception('Failed to login: No Password set');
    }

    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    var jsonBody = {
      'username': stringToBase64.encode(user.trim()),
      'password': stringToBase64.encode(passwd.trim()),
      'university': university,
      'from': "/"
    };

    //application/x-www-form-urlencoded;charset=UTF-8
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept-Charset": "utf-8",
      "Accept": "application/json"
    };

    final uri = Uri.parse(BaseAPIServices.loginURL);

    final response =
        await client.post(uri, headers: headers, body: jsonEncode(jsonBody));

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 500) {
      throw Exception(
          "Server exception, try again later. Also check if you have selected the correct university");
    } else {
      String? msg = json.decode(response.body)["message"];
      throw Exception('Failed to login: $msg');
    }
  }
}
