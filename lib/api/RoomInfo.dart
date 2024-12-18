import 'building/building.dart';

class RoomInfo {
  String fullTitle = "";
  String adress = "";
  String buildingNumber = "";
  String buildingYear = "";

  RoomInfo(this.fullTitle, this.adress, this.buildingNumber, this.buildingYear);

  @override
  String toString() {
    return 'RoomAdress{fullTitle: $fullTitle, adress: $adress, buildingNumber: $buildingNumber, buildingYear: $buildingYear}';
  }
}
