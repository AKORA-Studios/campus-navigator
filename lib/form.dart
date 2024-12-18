// Define a custom Form widget.
import 'package:campus_navigator/Views/RoomView.dart';
import 'package:flutter/material.dart';
import 'package:campus_navigator/api/building/building.dart';
import 'package:campus_navigator/api/search.dart';

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  State<MyCustomForm> createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final myController = TextEditingController();
  Future<SearchResult>? searchResult;
  Future<RoomPage>? roomResult;

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
          roomResult = RoomPage.fetchRoom(r.identifier);
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
        ),
        body: Container(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextField(
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
                            roomResult = RoomPage.fetchRoom(result.identifier);
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
                      ? asyncInteractiveRoomView(roomResult!)
                      : const Text("No room selected")
                ],
              ),
            )));
  }
}
