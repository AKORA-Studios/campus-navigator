import 'package:campus_navigator/api/BuildingLevels.dart';
import 'package:campus_navigator/api/RoomInfo.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:campus_navigator/api/building/building.dart';
import 'package:campus_navigator/painter.dart';

import 'package:url_launcher/url_launcher.dart';

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
  BuildingLevel? selectedLevel;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    widget.room.then((room) {
      setState(() {
        selectedLevel = room.buildingData.getCurrentLevel();
      });
    });
  }

  void _launchMapsUrl(String adress) async {
    final Uri url = Uri.parse('https://maps.google.com/maps/search/?q=$adress');
    await launchUrl(url);

    /*   if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }*/
  }

  Widget dropDown() {
    return FutureBuilder<RoomPage>(
      future: widget.room,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text("bruh");
        }

        final room = snapshot.data!;

        List<DropdownMenuItem> options = [];

        for (BuildingLevel lev in room.buildingData.levels) {
          options.add(DropdownMenuItem(
            child: Text(lev.name),
            value: lev,
          ));
        }
        return DropdownButton(
            value: selectedLevel,
            items: options,
            onChanged: (value) {
              setState(() {
                selectedLevel = value;
                widget.room = RoomPage.fetchRoom("pot/03");
              });
            });
      },
    );
  }

  Widget adressInfo(Future<RoomPage> roomPage) {
    return FutureBuilder<RoomPage>(
      future: widget.room,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text("bruh");
        }

        final room = snapshot.data!;

        List<Widget> arr = [
          const SizedBox(
              child: Text("Gebäudeadressen",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              width: double.infinity)
        ];
        for (RoomInfo child in room.buildingData.rooms) {
          arr.add(Text(
              child.fullTitle.split(',')[0].trim() +
                  " [" +
                  child.buildingNumber +
                  "]",
              style: const TextStyle(fontWeight: FontWeight.bold)));
          arr.add(RichText(
              text: TextSpan(children: [
            TextSpan(
                text: child.adress.replaceAll("<br>", "\n"),
                style: const TextStyle(
                    color: Colors.deepPurpleAccent,
                    decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    _launchMapsUrl(child.adress.replaceAll("<br>", " "));
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.name),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              Row(
                children: [
                  const Text("Etage wechseln:"),
                  dropDown(),
                ],
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              ),
              asyncInteractiveRoomView(widget.room,
                  size: MediaQuery.sizeOf(context)),
              adressInfo(widget.room)
            ])));
  }
}

Widget interactiveRoomView(RoomPage roomResult,
    {Size size = const Size(300, 300)}) {
  return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(34.0),
      minScale: 0.001,
      maxScale: 16.0,
      child:
          CustomPaint(painter: MapPainter(roomResult: roomResult), size: size));
}

Widget asyncInteractiveRoomView(Future<RoomPage> roomResult,
    {Size size = const Size(300, 300)}) {
  return FutureBuilder<RoomPage>(
    future: roomResult,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return interactiveRoomView(snapshot.data!, size: size);
      } else if (snapshot.hasError) {
        return Text('${snapshot.error}');
      }

      // By default, show a loading spinner.
      return const SizedBox.shrink();
    },
  );
}
