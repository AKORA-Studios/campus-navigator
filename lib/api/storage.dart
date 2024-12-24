import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// TODO: https://pub.dev/packages/flutter_secure_storage#configure-web-version
class Storage {
  static const keyUsername = "Username";
  static const keyPassword = "Password";
  static final Storage Shared = Storage();

  factory Storage() {
    return Shared;
  }
  Storage._();

  int university = 1; //1=TUD, 2=HTW

  final storage = new FlutterSecureStorage();

  Future<String?> getUsername() {
    return storage.read(key: keyUsername);
  }

  void editUsername(String newValue) async {
    return await storage.write(key: keyUsername, value: newValue);
  }

  Future<String?> getPassword() {
    return storage.read(key: keyPassword);
  }

  void editpassword(String newValue) async {
    return await storage.write(key: keyPassword, value: newValue);
  }

  void deleteData() async {
    return await storage.deleteAll();
  }
}
