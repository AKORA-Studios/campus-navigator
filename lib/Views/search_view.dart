// Define a custom Form widget.
import 'package:campus_navigator/Styling.dart';
import 'package:campus_navigator/Views/RoomView.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/search.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:flutter/material.dart';

import 'locationView.dart';
import 'settingsView.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  Future<SearchResult>? searchResult;

  String hintText = "";

  Widget searchResultList(SearchResult result) {
    final roomButtons =
        result.resultsRooms.take(8).map(roomResultButton).toList();

    final children = roomButtons;
    if (result.resultsRooms.length > 8) {
      children.add(const Text(
        ". . . . . ",
        style: TextStyle(color: Styling.primaryColor),
      ));
    }

    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [...roomButtons]);
  }

  Widget roomResultButton(SearchResultObject resultEntry) {
    return TextButton(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            resultEntry.name,
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          resultEntry.subName != null
              ? Text(
                  resultEntry.subName!,
                  style: TextStyle(
                      fontSize: 17, color: Styling.primaryColor.withAlpha(200)),
                )
              : const SizedBox.shrink()
        ],
      ),
      onPressed: () {
        final roomResult = BuildingPageData.fetchQuery(resultEntry.identifier);

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  RoomView(room: roomResult, name: resultEntry.name)),
        );
      },
    );
  }

  void onSearchChanged(String newQuery) async {
    final searchFuture = SearchResult.searchRoom(newQuery);
    setState(() {
      searchResult = searchFuture;
    });

    final results = await searchFuture;
    final firstResult = results.resultsRooms.firstOrNull;

    setState(() {
      hintText = results.assist;
    });
    if (firstResult == null) return;

    // Prefetching for better UX
    final preFetchingLevel = await Storage.Shared.getPrefetchingLevel();

    switch (preFetchingLevel) {
      case PrefetchingLevel.allResults:
        results.resultsRooms
            .map((e) => BuildingPageData.preFetchQuery(e.identifier));
      case PrefetchingLevel.firstResult:
        BuildingPageData.preFetchQuery(firstResult.identifier);
      case PrefetchingLevel.none:
        break;
    }
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
                  MaterialPageRoute(builder: (context) => const SettingsView()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.location_on),
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
                  Stack(
                    children: [
                      // Show searcch suggestion below actual search text field
                      TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: hintText,
                        ),
                      ),
                      TextField(
                        enableInteractiveSelection: true,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          hintText: 'Raumabkürzung hier eingeben',
                        ),
                        onChanged: onSearchChanged,
                      ),
                    ],
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
                      return searchResultList(snapshot.data!);
                    },
                  )
                ],
              ),
            )));
  }
}
