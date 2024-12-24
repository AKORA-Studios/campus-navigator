import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// TODO: https://pub.dev/packages/flutter_secure_storage#configure-web-version
class Storage {
  static const keyUsername = "Username";
  static const keyPassword = "Password";
  static const keyUniversity = "University";
  static final Storage Shared = Storage();

  Storage();

  int university = 1; //1=TUD, 2=HTW

  final storage = new FlutterSecureStorage();

  Future<String?> getUsername() {
    return storage.read(key: keyUsername);
  }

  Future<void> editUsername(String newValue) async {
    return await storage.write(key: keyUsername, value: newValue);
  }

  Future<String?> getPassword() {
    return storage.read(key: keyPassword);
  }

  Future<void> editpassword(String newValue) async {
    return await storage.write(key: keyPassword, value: newValue);
  }

  Future<String?> getUniversity() {
    return storage.read(key: keyUniversity);
  }

  Future<void> editUniversity(String newValue) async {
    return await storage.write(key: keyUniversity, value: newValue);
  }

  void deleteData() async {
    return await storage.deleteAll();
  }
}
