// Define a custom Form widget.
import 'package:flutter/material.dart';
import 'package:flutter_testy/api/search.dart';

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

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                      .map(
                        (r) => Text(
                          r.name,
                          textAlign: TextAlign.left,
                        ),
                      )
                      .toList());
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }

            // By default, show a loading spinner.
            return const CircularProgressIndicator();
          },
        )
      ],
    );
  }
}
