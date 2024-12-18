import 'BuildingLevels.dart';
import 'RoomInfo.dart';

class BuildingData {
  List<BuildingLevel> levels = [];
  List<RoomInfo> rooms = [];

  BuildingData(this.levels, this.rooms);

  BuildingLevel? getCurrentLevel() {
    return levels.where((element) => element.rooms.isNotEmpty).first;
  }
}