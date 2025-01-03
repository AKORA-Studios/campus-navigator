import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum PrefetchingLevel {
  allResults(value: "allResults"),
  firstResult(value: "firstResult"),
  none(value: "none");

  final String value;

  const PrefetchingLevel({required this.value});

  String serialize() {
    return value;
  }

  static PrefetchingLevel deserialize(String value) {
    return PrefetchingLevel.values
        .firstWhere((element) => element.value == value);
  }
}

enum CacheDuration {
  day(value: Duration(days: 1)),
  week(value: Duration(days: 7)),
  month(value: Duration(days: 30)),
  year(value: Duration(days: 365));

  final Duration value;

  const CacheDuration({required this.value});

  String serialize() {
    return value.inDays.toString();
  }

  static CacheDuration deserialize(String value) {
    final daysInt = int.parse(value);

    return CacheDuration.values
        .firstWhere((element) => element.value.inDays == daysInt);
  }
}

enum UserUniversity {
  TUD(1),
  HTW(2);

  const UserUniversity(this.value);
  final num value;

  factory UserUniversity.fromValue(int val) {
    return values.firstWhere((e) => e.value == val);
  }

  @override
  String toString() => value.toString();
}

enum layerFilterOptions {
  Labeling,
  Seminarrooms,
  Toilets,
  Barrier_free_wc,
  Staircase,
  Elevator,
  otherRooms,
  WLAN_Accesspoints,
  Defirbilator,
  Changing_table;
}

// TODO: https://pub.dev/packages/flutter_secure_storage#configure-web-version
class Storage {
  static const keyUsername = "Username";
  static const keyPassword = "Password";
  static const keyUniversity = "University";

  // Network usage options
  static const keyQualityLevel = "QualityLevel";
  static const keyPrefetchingLevel = "PrefetchingLevel";
  static const keyCacheDuration = "CacheDuration";

  static final Storage Shared = Storage();

  Storage();

  final storage = const FlutterSecureStorage();

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

  Future<UserUniversity> getUniversity() async {
    var value = await storage.read(key: keyUniversity);
    return UserUniversity.fromValue(int.parse(value ?? "1"));
  }

  Future<void> editUniversity(UserUniversity newValue) async {
    return await storage.write(
        key: keyUniversity, value: newValue.value.toString());
  }

  // Network usage options

  // Quality Level
  Future<int> getQualityLevel() async {
    final storedValue = await storage.read(key: keyQualityLevel);

    // Default value
    if (storedValue == null) {
      await setQualityLevel(4);
      return await getQualityLevel();
    }

    return int.parse(storedValue);
  }

  Future<void> setQualityLevel(int newValue) async {
    final isValid = (1 <= newValue) && (newValue <= 4);
    if (!isValid) throw Exception("Quality Level should be in range [1,4]");

    return await storage.write(
        key: keyQualityLevel, value: newValue.toString());
  }

  // Prefetching Level
  Future<PrefetchingLevel> getPrefetchingLevel() async {
    final storedValue = await storage.read(key: keyPrefetchingLevel);

    // Default value
    if (storedValue == null) {
      await setPrefetchingLevel(PrefetchingLevel.firstResult);
      return await getPrefetchingLevel();
    }

    return PrefetchingLevel.deserialize(storedValue);
  }

  Future<void> setPrefetchingLevel(PrefetchingLevel newValue) async {
    return await storage.write(
        key: keyPrefetchingLevel, value: newValue.serialize());
  }

  // Cache duration
  Future<CacheDuration> getCacheDuration() async {
    final storedValue = await storage.read(key: keyCacheDuration);

    // Default value
    if (storedValue == null) {
      await setCacheDuration(CacheDuration.day);
      return await getCacheDuration();
    }

    return CacheDuration.deserialize(storedValue);
  }

  Future<void> setCacheDuration(CacheDuration newValue) async {
    return await storage.write(
        key: keyCacheDuration, value: newValue.serialize());
  }

  void deleteData() async {
    return await storage.deleteAll();
  }
}
