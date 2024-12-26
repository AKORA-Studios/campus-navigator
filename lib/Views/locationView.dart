import 'package:flutter/material.dart';
import 'package:location/location.dart';

class LocationView extends StatefulWidget {
  LocationView({super.key, required this.name});

  final String name;

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  Location location = new Location();
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  LocationData? _locationData;

  @override
  void initState() {
    super.initState();

    location.serviceEnabled().then((value) {
      _serviceEnabled = value;
      if (!_serviceEnabled) {
        location.requestService().then((value2) {
          _serviceEnabled = value2;
          if (!_serviceEnabled) {
            return;
          }
        }).catchError(onError);
      }
    }).catchError(onError);

    location.hasPermission().then((value) {
      _permissionGranted = value;
      if (_permissionGranted == PermissionStatus.denied) {
        location.requestPermission().then((value2) {
          _permissionGranted = value2;
          if (_permissionGranted != PermissionStatus.granted) {
            return;
          }
        }).catchError(onError);
      }
    }).catchError(onError);

    location.getLocation().then((value) {
      _locationData = value;
      print("----------------");
      print(_locationData);
    }).catchError(onError);
  }

  Widget errorWidget() {
    var style = const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
    if (!_serviceEnabled) {
      return Text("Location not enabled :c", style: style);
    } else if (_permissionGranted != PermissionStatus.granted ||
        _permissionGranted != PermissionStatus.grantedLimited) {
      return Text(_permissionGranted.toString(), style: style);
    } else {
      return Text("${_locationData?.latitude} ${_locationData?.longitude}");
    }
  }

  void onError(var e) {
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
              Text("Get plan of the building your currently in:"),
              Center(child: errorWidget()),
            ])));
  }
}
