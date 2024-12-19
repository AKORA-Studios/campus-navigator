import 'package:html/dom.dart';

import 'building_levels.dart';
import 'room_info.dart';

/// Information about the current building
/// This includes the available levels in the current building
class BuildingData {
  /// Levels in this building
  final List<BuildingLevel> levels;

  final List<RoomInfo> rooms;

  BuildingData(this.levels, this.rooms);

  BuildingLevel? getCurrentLevel() {
    return levels.where((element) => element.rooms.isNotEmpty).first;
  }

  static BuildingData fromHTMLDocument(Document document) {
    // Gebäude/Etagenpläne/Lehrräume
    List<BuildingLevel> buildingLevelInfo = [];
    var leftMenuParent = document
        .querySelector("#menu_cont")
        ?.children
        .where((element) => element.localName == "ul")
        .first;
    if (leftMenuParent != null) {
      // Children: li: closed or open
      // Element building = leftMenuParent.children[0];
      // Element studyRooms = leftMenuParent.children[2];

      var levelPlan = leftMenuParent.children[1].children
          .where((element) => element.localName == "ul")
          .firstOrNull;

      if (levelPlan != null && levelPlan.children.isNotEmpty) {
        for (Element level in levelPlan.children) {
          List<BuildingRoom> roomInfos = [];

          if (level.children.length > 1) {
            // display rooms in selected level
            for (Element room in level.children) {
              if (room.children.isNotEmpty) {
                for (Element singleRoom in room.children) {
                  roomInfos.add(BuildingRoom(singleRoom.children[0].text));
                }
              }
            }
            buildingLevelInfo.add(BuildingLevel.fromRooms(
                level.children[0].innerHtml, roomInfos));
          } else {
            // No Rooms loaded for this level
            buildingLevelInfo.add(BuildingLevel(level.children[0].innerHtml));
          }
        }
      }
    }

    // Building Info
    var rightNavBarContent = document.querySelector("#menu_cont_right");
    List<RoomInfo> adressInfo = [];
    if (rightNavBarContent != null) {
      var buildingInfos =
          rightNavBarContent.children[rightNavBarContent.children.length - 2];

      List<Element> childrenGiver = buildingInfos.children;
      List<List<Element>> buildingList = [];
      while (childrenGiver.length > 8) {
        buildingList.add(childrenGiver
            .take(8)
            .where((element) => element.localName != "p")
            .toList());
        childrenGiver.removeRange(0, 8);
      }
      for (List<Element> buildingInfo in buildingList) {
        var fullTitle = buildingInfo[0].innerHtml;
        var adressInfoRoom = RoomInfo(fullTitle, buildingInfo[3].innerHtml,
            buildingInfo[1].innerHtml, buildingInfo[2].innerHtml);
        adressInfo.add(adressInfoRoom);
      }
    }

    return BuildingData(buildingLevelInfo, adressInfo);
  }
}
