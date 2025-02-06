import 'package:flutter/material.dart';
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
  Labeling(layerName: "", icon: Icons.text_fields),
  Seminarrooms(layerName: "seminarraeumeData", icon: Icons.school_outlined),
  Toilets(layerName: "wcData", icon: Icons.wc),
  Barrier_free_wc(layerName: "bwcData", icon: Icons.accessible_forward),
  Staircase(layerName: "treppenData", icon: Icons.stairs_outlined),
  Elevator(layerName: "aufzuegeData", icon: Icons.elevator_outlined),
  Other_rooms(layerName: "raeumeData", icon: Icons.roofing),
  WLAN_Accesspoints(layerName: "WLAN AccessPoints", icon: Icons.wifi),
  Defirbilator(layerName: "Defibrillatoren", icon: Icons.electric_bolt),
  Changing_table(layerName: "Wickeltische", icon: Icons.baby_changing_station);

  final String layerName;
  final IconData icon;
  const layerFilterOptions({required this.layerName, required this.icon});

  @override
  String toString() {
    switch (this) {
      case layerFilterOptions.Labeling:
        return "Room Labels";
      case layerFilterOptions.Seminarrooms:
        return "Seminar Rooms";
      case layerFilterOptions.Toilets:
        return "Toilets";
      case layerFilterOptions.Barrier_free_wc:
        return "Barrier Free WC";
      case layerFilterOptions.Staircase:
        return "Staircase";
      case layerFilterOptions.Elevator:
        return "Elevator";
      case layerFilterOptions.Other_rooms:
        return "Other Rooms";
      case layerFilterOptions.WLAN_Accesspoints:
        return "WLAN Accesspoints";
      case layerFilterOptions.Defirbilator:
        return "Defibrillator";
      case layerFilterOptions.Changing_table:
        return "Changing table";
      default:
        return "-";
    }
  }
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

  // Map filters
  var filterSet = layerFilterOptions.values.toSet();

  static Storage Shared = Storage();

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
