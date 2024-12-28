// Define a custom Form widget.
import 'package:campus_navigator/Styling.dart';
import 'package:campus_navigator/Views/RoomView.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/search.dart';
import 'package:flutter/material.dart';

import 'Views/building_view.dart';
import 'Views/locationView.dart';
import 'Views/settingsView.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final myController = TextEditingController();
  Future<SearchResult>? searchResult;
  Future<BuildingPageData>? roomResult;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  Widget getResultButton(SearchResultObject r) {
    return TextButton(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            r.name,
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          r.subName != null
              ? Text(
                  r.subName!,
                  style: TextStyle(
                      fontSize: 17, color: Styling.primaryColor.withAlpha(200)),
                )
              : const SizedBox.shrink()
        ],
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

  void onSearchCahnged(String newQuery) {
    var searchFuture = SearchResult.searchRoom(myController.text);
    setState(() {
      searchResult = searchFuture;
    });

    searchFuture.then((results) {
      var firstResult = results.resultsRooms.firstOrNull;
      if (firstResult == null) return;

      setState(() {
        roomResult = BuildingPageData.fetchQuery(firstResult.identifier);
      });
    });
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
                      builder: (context) =>
                          const SettingsView(name: "Settings")),
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
                      builder: (context) =>
                          const LocationView(name: "Location")),
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
                children: [
                  TextField(
                    enableInteractiveSelection: true,
                    autocorrect: false,
                    controller: myController,
                    decoration: const InputDecoration(
                        hintText: 'Raumabkürzung hier eingeben'),
                    onChanged: onSearchCahnged,
                  ),
                  // Spacing
                  const SizedBox(
                    height: 20,
                  ),
                  FutureBuilder(
                    future: searchResult,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('${snapshot.error}');
                      } else if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: snapshot.data!.resultsRooms
                              .take(8)
                              .map(getResultButton)
                              .toList());
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
