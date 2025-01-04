import 'package:campus_navigator/Styling.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/building/parsing/building_levels.dart';
import 'package:campus_navigator/api/building/parsing/room_info.dart';
import 'package:campus_navigator/api/building/roomOccupancyPlan.dart';
import 'package:campus_navigator/api/networking.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/login.dart';
import '../api/storage.dart';
import 'BottomSheetView.dart';
import 'building_view.dart';
import 'occupancyTableView.dart';

class RoomView extends StatefulWidget {
  RoomView({super.key, required this.room, required this.name});

  Future<BuildingPageData> room;
  final String name;

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  String? selectedLevel;
  bool isRoomSelected = true;
  String? roomURL;
  List<List<List<String>>>? roomPlan;
  bool showOccupancyTable = false;
  String? errorMessageOccupancyTable;
  bool updateView = false;
  Set<layerFilterOptions> selectedFilters = {};

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    selectedFilters = Storage.Shared.filterSet;
    widget.room.then((room) {
      setState(() {
        selectedLevel = room.buildingData.getCurrentLevel()?.name;
        roomURL = room.queryParts.last;
      });
    });
  }

  // TODO: use correct Room ID
  void loadOccupancyTable() {
    setState(() {
      showOccupancyTable = !showOccupancyTable;
      if (showOccupancyTable && roomURL != null) {
        Future<LoginResponse> loginToken = LoginResponse.postLogin();
        loginToken.then((value) {
          Future<List<List<List<String>>>> tableContent =
              RoomOccupancyPlan.getRoomPlan(roomURL!, token: value.loginToken);
          tableContent.then((value) {
            setState(() {
              roomPlan = value;
              if (value.isEmpty) {
                // No Data loaded/available
                isRoomSelected = false;
                errorMessageOccupancyTable = "Kein Raumbelegungsplan verfügbar";
                updateView = !updateView;
              }
            });
          });
        }).catchError(onError);
      }
    });
  }

  void onError(var e) {
    setState(() {
      errorMessageOccupancyTable = e.toString();
    });
    throw (e);
  }

  void openRoomPlan() async {
    if (roomURL != null && roomURL!.isNotEmpty) {
      final Uri _url = Uri.parse(baseURL + "/raum/" + roomURL!);
      if (!await launchUrl(_url)) {
        launchUrl(_url);
      }
    }
  }

  Widget futurify(Widget Function(BuildingPageData) widgetBuilder) {
    return FutureBuilder<BuildingPageData>(
        future: widget.room,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Text("No data yet");
          } else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }

          final room = snapshot.data!;
          return widgetBuilder(room);
        });
  }

  Widget filterOption(layerFilterOptions opt) {
    return StatefulBuilder(
      builder: (context, _setState) {
        return Row(
          children: [
            Checkbox(
              value: selectedFilters.contains(opt),
              activeColor: Styling.primaryColor.withAlpha(100),
              checkColor: Theme.of(context).colorScheme.onSurface,
              onChanged: (isSelected) {
                if (isSelected == true) {
                  selectedFilters.add(opt);
                  Storage.Shared.filterSet.add(opt);
                } else {
                  selectedFilters.remove(opt);
                  Storage.Shared.filterSet.remove(opt);
                }
                _setState(() {}); // Update checkbox state
                setState(() {}); // Update parent widget
              },
            ),
            const SizedBox(width: 5),
            Icon(opt.icon),
            const SizedBox(width: 5),
            Text(opt.toString()),
          ],
        );
      },
    );
  }

  Widget dropDown(BuildingPageData roomPage) {
    List<DropdownMenuItem> options = [];

    for (BuildingLevel lev in roomPage.buildingData.levels) {
      options.add(DropdownMenuItem(
        child: Text(lev.name),
        value: lev.name,
      ));
    }
    return DropdownButton(
        value: selectedLevel,
        items: options,
        onChanged: (value) {
          setState(() {
            selectedLevel = value;
            widget.room = BuildingPageData.fetchQuery(
                "${roomPage.queryParts.first}/${value.split(" ").last}");
          });
        });
  }

  Widget buildingAddressBlock(BuildingPageData roomPage) {
    List<Widget> arr = [
      const SizedBox(
          child: Text("Gebäudeadressen",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          width: double.infinity)
    ];
    for (RoomInfo child in roomPage.buildingData.rooms) {
      arr.add(SelectableText(
          child.fullTitle.split(',')[0].trim() +
              " [" +
              child.buildingNumber +
              "]",
          style: const TextStyle(fontWeight: FontWeight.bold)));
      arr.add(SelectableText.rich(TextSpan(children: [
        TextSpan(
            text: child.adress.replaceAll("<br>", "\n"),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Styling.primaryColor,
                decorationColor: Styling.primaryColor,
                decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                MapsLauncher.launchQuery(child.adress.replaceAll("<br>", " "));
              }),
      ])));
      arr.add(const SizedBox(
        height: 10,
      ));
    }
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        // border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: arr,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  Widget occupancyButtons() {
    return isRoomSelected
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: isRoomSelected ? loadOccupancyTable : null,
                  child: Text(
                      "Raumbelegungsplan ${showOccupancyTable ? 'verstecken' : 'laden'}")),
              ElevatedButton(
                onPressed: isRoomSelected ? openRoomPlan : null,
                child: const Icon(Icons.open_in_browser),
              )
            ],
          )
        : const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Open in Web',
            onPressed: () {
              widget.room.then((value) {
                Share.share('$baseURL/etplan/${value.queryParts.join("/")}');
              });
            },
          ),
        ],
      ),
      body: Stack(children: [
        Column(children: [
          DecoratedBox(
            decoration: BoxDecoration(boxShadow: [
              // Blur only on bottom
              BoxShadow(
                blurRadius: 2.5,
                blurStyle: BlurStyle.normal,
                color: Theme.of(context).shadowColor.withAlpha(100),
                offset: const Offset(0, 2.5),
                spreadRadius: 0,
              ),
            ], color: Theme.of(context).colorScheme.surface),
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Row(
                children: [
                  TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              List<Widget> opt = layerFilterOptions.values
                                  .map((e) => filterOption(e))
                                  .toList();
                              opt.insert(
                                  0,
                                  const Text("Available Filter Options:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)));
                              return SingleChildScrollView(
                                  child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(children: opt)));
                            });
                      },
                      child: Row(
                        children: [
                          Text("Filter: (${selectedFilters.length})"),
                          const Icon(Icons.arrow_drop_down_sharp)
                        ],
                      )),
                  const Text("Etage wechseln:"),
                  futurify(dropDown),
                ],
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              ),
            ),
          ),
          asyncInteractiveBuildingView(widget.room,
              size: Size(
                  MediaQuery.sizeOf(context).width,
                  // Necessary to prevent overflow
                  MediaQuery.sizeOf(context).height * 0.9)),
        ]),
        DraggableBottomSheet(
          name: "Location",
          child: Column(
            children: [
              occupancyTableView(roomPlan, showOccupancyTable),
              occupancyButtons(),
              errorMessageOccupancyTable != null
                  ? Text(
                      errorMessageOccupancyTable ?? "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    )
                  : const SizedBox(),
              Divider(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
              futurify(buildingAddressBlock)
            ],
          ),
        )
      ]),
    );
  }
}
