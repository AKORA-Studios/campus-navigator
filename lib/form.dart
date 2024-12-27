// Define a custom Form widget.
import 'package:campus_navigator/Views/RoomView.dart';
import 'package:campus_navigator/Views/a.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/search.dart';
import 'package:flutter/material.dart';

import 'Views/building_view.dart';
import 'Views/locationView.dart';
import 'Views/settingsView.dart';

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  State<MyCustomForm> createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final myController = TextEditingController();
  Future<SearchResult>? searchResult;
  Future<BuildingPageData>? roomResult;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  Widget getResultButton(r) {
    return TextButton(
      child: Text(
        r.name,
        textAlign: TextAlign.left,
        style: const TextStyle(fontSize: 18),
      ),
      onPressed: () {
        setState(() {
          roomResult = BuildingPageData.fetchQuery(r.identifier);
          roomResult!.then((v) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => RoomView(
                      myController: myController,
                      room: roomResult!,
                      name: r.name)),
            );
          }, onError: (e) {
            print(e);
          });
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Raumsuche"),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Open in Web',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsView(name: "Settings")),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.map),
              tooltip: 'Open Location',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LocationView(name: "Location")),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.map),
              tooltip: 'Open Location',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyDraggableSheet(name: "Location")),
                );
              },
            ),
          ],
        ),
        body: Container(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextField(
                    enableInteractiveSelection: true,
                    autocorrect: false,
                    controller: myController,
                    decoration: const InputDecoration(
                        hintText: 'Raumabkürzung hier eingeben'),
                    onChanged: (text) {
                      setState(() {
                        var searchFuture =
                            SearchResult.searchRoom(myController.text);
                        searchResult = searchFuture;

                        searchFuture.then((value) {
                          var result = value.resultsRooms.firstOrNull;
                          if (result == null) return;

                          setState(() {
                            roomResult =
                                BuildingPageData.fetchQuery(result.identifier);
                          });
                        });
                      });
                    },
                  ),
                  FutureBuilder<SearchResult>(
                    future: searchResult,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: snapshot.data!.resultsRooms
                                .take(8)
                                .map((r) => getResultButton(r))
                                .toList());
                      } else if (snapshot.hasError) {
                        return Text('${snapshot.error}');
                      }
                      // By default, show a loading spinner.
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 100),
                  roomResult != null
                      ? asyncInteractiveBuildingView(roomResult!)
                      : const Text("No room selected")
                ],
              ),
            )));
  }
}
