import 'building.dart';

class RoomAdress {
  String fullTitle = "";
   String adress = "";
   String buildingNumber = "";
   String buildingYear = "";

  RoomAdress(this.fullTitle, this.adress, this.buildingNumber, this.buildingYear);

  @override
  String toString() {
    return 'RoomAdress{fullTitle: $fullTitle, adress: $adress, buildingNumber: $buildingNumber, buildingYear: $buildingYear}';
  }
}
