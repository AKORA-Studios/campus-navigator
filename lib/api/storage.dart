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
    return PrefetchingLevel.values.firstWhere(
        (element) => element.value == value,
        orElse: () => PrefetchingLevel.firstResult);
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
    final daysInt = int.tryParse(value);
    if (daysInt == null) return CacheDuration.day;

    return CacheDuration.values.firstWhere(
        (element) => element.value.inDays == daysInt,
        orElse: () => CacheDuration.day);
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
    try {
      return await getUniversityStrict();
    } catch (_) {
      return UserUniversity.TUD;
    }
  }

  /// Reads the saved university and propagates storage read failures.
  /// Invalid stored values use the documented TUD default, while Settings can
  /// distinguish a real storage failure from a corrupt preference.
  Future<UserUniversity> getUniversityStrict() async {
    final storedValue = await storage.read(key: keyUniversity);
    final value = int.tryParse(storedValue ?? '1');
    if (value == null) return UserUniversity.TUD;
    return UserUniversity.values.firstWhere(
      (university) => university.value == value,
      orElse: () => UserUniversity.TUD,
    );
  }

  Future<void> editUniversity(UserUniversity newValue) async {
    return await storage.write(
        key: keyUniversity, value: newValue.value.toString());
  }

  // Network usage options

  // Quality Level
  Future<int> getQualityLevel() async {
    try {
      final storedValue = await storage.read(key: keyQualityLevel);
      final value = int.tryParse(storedValue ?? "");
      if (value != null && value >= 1 && value <= 4) return value;
    } catch (_) {/* Use the documented default when secure storage fails. */}
    return 4;
  }

  Future<void> setQualityLevel(int newValue) async {
    final isValid = (1 <= newValue) && (newValue <= 4);
    if (!isValid) throw Exception("Quality Level should be in range [1,4]");

    return await storage.write(
        key: keyQualityLevel, value: newValue.toString());
  }

  // Prefetching Level
  Future<PrefetchingLevel> getPrefetchingLevel() async {
    try {
      final storedValue = await storage.read(key: keyPrefetchingLevel);
      if (storedValue != null) return PrefetchingLevel.deserialize(storedValue);
    } catch (_) {
      // A bad preference must not break room search prefetching.
    }
    return PrefetchingLevel.firstResult;
  }

  Future<void> setPrefetchingLevel(PrefetchingLevel newValue) async {
    return await storage.write(
        key: keyPrefetchingLevel, value: newValue.serialize());
  }

  // Cache duration
  Future<CacheDuration> getCacheDuration() async {
    try {
      final storedValue = await storage.read(key: keyCacheDuration);
      if (storedValue != null) return CacheDuration.deserialize(storedValue);
    } catch (_) {
      // A bad preference must not stop cached networking from working.
    }
    return CacheDuration.day;
  }

  Future<void> setCacheDuration(CacheDuration newValue) async {
    return await storage.write(
        key: keyCacheDuration, value: newValue.serialize());
  }

  void deleteData() async {
    return await storage.deleteAll();
  }
}
