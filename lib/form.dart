// Define a custom Form widget.
import 'package:campus_navigator/api/RoomView.dart';
import 'package:flutter/material.dart';
import 'package:campus_navigator/api/building.dart';
import 'package:campus_navigator/api/search.dart';
import 'package:campus_navigator/painter.dart';

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  State<MyCustomForm> createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final myController = TextEditingController();
  Future<SearchResult>? searchResult;
  Future<RoomResult>? roomResult;

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
        style: TextStyle(fontSize: 18),
      ),
      onPressed: () {
        setState(() {
          roomResult = RoomResult.fetchRoom(r.identifier);
          roomResult!.then((v) {
            print("reload done");
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => RoomView(
                      myController: myController, room: v, name: r.name)),
            );
          }, onError: (e) {
            print(e);
          });
        });
      },
    );
  }

  Widget resultsView() {
    return FutureBuilder<RoomResult>(
      future: roomResult,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: <Widget>[
              CustomPaint(
                size: const Size(300, 300),
                painter: MapPainter(roomResult: snapshot.data!),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        // By default, show a loading spinner.
        return const SizedBox.shrink();
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
                    decoration: InputDecoration(
                        hintText: 'Raumabkürzung hier eingeben'),
                    onChanged: (text) {
                      setState(() {
                        searchResult =
                            SearchResult.searchRoom(myController.text);
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
                  resultsView()
                ],
              ),
            )));
  }
}
