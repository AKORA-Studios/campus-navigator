import 'package:campus_navigator/api/storage.dart';

class MockStorage extends Storage {
  @override
  Future<String?> getPassword() {
    return Future(() => "pwd");
  }

  @override
  Future<String?> getUsername() {
    return Future(() => "usr");
  }

  @override
  Future<UserUniversity> getUniversity() {
    // TODO: implement getUniversity
    return Future(() => UserUniversity.TUD);
  }
}
