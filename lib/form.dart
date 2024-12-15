// Define a custom Form widget.
import 'package:flutter/material.dart';
import 'package:campus_navigator/api/building.dart';
import 'package:campus_navigator/api/search.dart';
import 'package:campus_navigator/painter.dart';

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  State<MyCustomForm> createState() => _MyCustomFormState();
}

// Define a corresponding State class.
// This class holds the data related to the Form.
class _MyCustomFormState extends State<MyCustomForm> {
  // Create a text controller and use it to retrieve the current value
  // of the TextField.
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
            /*  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LogPage(title: "Log", logEntries: logs)),
                                  );*/
          }, onError: (e) {
            print(e);
          });
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Raumsuche',
            style: TextStyle(fontSize: 50),
          ),
          TextField(
            controller: myController,
            onChanged: (text) {
              setState(() {
                searchResult = SearchResult.searchRoom(myController.text);
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
          FutureBuilder<RoomResult>(
            future: roomResult,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: <Widget>[
                    CustomPaint(
                      size: const Size(300, 300),
                      painter: MapPainter(roomResult: snapshot.data!),
                    ),
                    Text('eeee'),
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
