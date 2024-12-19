class BuildingLevel {
  String name;
  List<BuildingRoom> rooms = [];

  BuildingLevel(this.name);

  BuildingLevel.fromRooms(this.name, this.rooms);

  @override
  String toString() {
    return 'BuildingLevel{name: $name, rooms: ${rooms.map((e) => e.name)}';
  }
}

class BuildingRoom {
  String name;

  BuildingRoom(this.name);
}
