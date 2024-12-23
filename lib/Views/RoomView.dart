import 'package:campus_navigator/api/building/parsing/building_levels.dart';
import 'package:campus_navigator/api/building/parsing/common.dart';
import 'package:campus_navigator/api/building/parsing/room_info.dart';
import 'package:campus_navigator/api/building/roomPlan.dart';
import 'package:campus_navigator/api/building/room_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/login.dart';
import 'building_view.dart';

class RoomView extends StatefulWidget {
  RoomView(
      {super.key,
      required this.myController,
      required this.room,
      required this.name});
  final TextEditingController myController;
  Future<RoomPage> room;
  final String name;

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  String? selectedLevel;
  bool isRoomSelected = true;
  String? roomURL;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.room.then((room) {
      setState(() {
        selectedLevel = room.buildingData.getCurrentLevel()?.name;
        roomURL = room.queryParts.last; // TODO: place somwhere else
        Future<LoginResponse> loginToken =
            LoginResponse.postLogin("query", "query");
        loginToken.then((value) {
          print("aloha------------------------------------");
          print(value.loginToken);
          // TODO: reload page to get table
          Future<String> tableContent =
              RoomPlan.getRoomPlan("325302.0020", token: value.loginToken);
          tableContent.then((value) {
            print("Fetch plan");
            print(value);
          });
        });
      });
    });
  }

  void openRoomPlan() async {
    if (roomURL != null && roomURL!.isNotEmpty) {
      final Uri _url = Uri.parse(baseURL + "/raum/" + roomURL!);
      if (!await launchUrl(_url)) {
        launchUrl(_url);
      }
    }
  }

  Widget futurify(Widget Function(RoomPage) widgetBuilder) {
    return FutureBuilder<RoomPage>(
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

  Widget dropDown(RoomPage roomPage) {
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
            widget.room = RoomPage.fetchRoom(
                "${roomPage.queryParts.first}/${value.split(" ").last}");
          });
        });
  }

  Widget buildingAdressBlock(RoomPage roomPage) {
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
                color: Colors.deepPurpleAccent,
                decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                MapsLauncher.launchQuery(child.adress.replaceAll("<br>", " "));
              })
      ])));
    }
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(children: arr),
    );
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
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(10.0),
            child: Column(children: [
              Row(
                children: [
                  const Text("Etage wechseln:"),
                  futurify(dropDown),
                ],
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              ),
              asyncInteractiveBuildingView(widget.room,
                  size: MediaQuery.sizeOf(context).smallestSquare()),
              ElevatedButton.icon(
                  onPressed: isRoomSelected ? openRoomPlan : null,
                  icon: const Icon(Icons.share),
                  label: const Text("Raumbelegungsplan ansehen")),
              futurify(buildingAdressBlock)
            ])));
  }
}
