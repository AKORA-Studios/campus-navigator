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

enum LayerFilterOptions {
  /*
  case stairwell = 11
  case elevator = 12
  case restroom = 13
  case accessibleRestroom = 14
  case babyChangingRoom = 15
  case library = 21
  case lecturehall = 22
  case seminarroom = 23
  case drawingroom = 24
  case restingroom = 26
  case coatroom = 27
  case room = 29
  case other = -1
  */

  Labeling(layerName: "", icon: Icons.text_fields),
  Seminarrooms(
      layerName: "seminarraeumeData", icon: Icons.school_outlined, id: 23),
  Toilets(layerName: "wcData", icon: Icons.wc, id: 13),
  Barrier_free_wc(layerName: "bwcData", icon: Icons.accessible_forward, id: 14),
  Staircase(layerName: "treppenData", icon: Icons.stairs_outlined, id: 11),
  Elevator(layerName: "aufzuegeData", icon: Icons.elevator_outlined, id: 12),
  Other_rooms(layerName: "raeumeData", icon: Icons.roofing, id: 29),
  WLAN_Accesspoints(layerName: "WLAN AccessPoints", icon: Icons.wifi),
  Defirbilator(layerName: "Defibrillatoren", icon: Icons.electric_bolt),
  Changing_table(layerName: "Wickeltische", icon: Icons.baby_changing_station);

  final String layerName;
  final IconData icon;
  final int? id;

  const LayerFilterOptions(
      {required this.layerName, required this.icon, this.id});

  @override
  String toString() {
    switch (this) {
      case LayerFilterOptions.Labeling:
        return "Room Labels";
      case LayerFilterOptions.Seminarrooms:
        return "Seminar Rooms";
      case LayerFilterOptions.Toilets:
        return "Toilets";
      case LayerFilterOptions.Barrier_free_wc:
        return "Barrier Free WC";
      case LayerFilterOptions.Staircase:
        return "Staircase";
      case LayerFilterOptions.Elevator:
        return "Elevator";
      case LayerFilterOptions.Other_rooms:
        return "Other Rooms";
      case LayerFilterOptions.WLAN_Accesspoints:
        return "WLAN Accesspoints";
      case LayerFilterOptions.Defirbilator:
        return "Defibrillator";
      case LayerFilterOptions.Changing_table:
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
  var filterSet = LayerFilterOptions.values.toSet();

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
