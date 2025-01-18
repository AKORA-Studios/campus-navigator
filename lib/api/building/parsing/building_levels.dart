class BuildingLevel {
  String name;
  List<BuildingRoom> rooms = [];

  BuildingLevel(String name2) : name = name2.replaceAll("Etage", "");

  BuildingLevel.init(String name, List<BuildingRoom> rooms2)
      : name = name.replaceAll("Etage", "") {
    rooms = rooms2;
  }

  @override
  String toString() {
    return 'BuildingLevel{name: $name, rooms: ${rooms.map((e) => e.name)}';
  }
}

class BuildingRoom {
  String name;

  BuildingRoom(this.name);
}
