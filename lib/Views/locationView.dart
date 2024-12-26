import 'package:flutter/material.dart';

class LocationView extends StatefulWidget {
  LocationView({super.key, required this.name});

  final String name;

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  bool errorOccured = false;
  String? errrorMessage;

  @override
  void initState() {
    super.initState();

    /*  _determinePosition().then((value) {
      print(value);
    }).catchError(onError);*/
  }

  void onError(var e) {
    errorOccured = true;
    print(e);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.name),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(10.0),
            child: Column(children: [
              Text("hhhhh"),
              Text(
                errorOccured ? errrorMessage! : "",
                style: TextStyle(color: Colors.red),
              )
            ])));
  }
}
