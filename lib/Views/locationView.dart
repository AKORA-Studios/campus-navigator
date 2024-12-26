import 'dart:async';

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

  StreamSubscription<LocationData>? locationListener;

  @override
  void initState() {
    super.initState();

    requestServices();

    locationListener =
        location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _locationData = currentLocation;
      });
      locationListener?.cancel();
    });
  }

  void requestServices() async {
    _serviceEnabled = await location.serviceEnabled();
    setState(() {
      _serviceEnabled = _serviceEnabled;
    });
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      setState(() {
        _serviceEnabled = _serviceEnabled;
      });

      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    setState(() {
      _permissionGranted = _permissionGranted;
    });
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      setState(() {
        _permissionGranted = _permissionGranted;
      });
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  Widget errorWidget() {
    var style = const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
    if (!_serviceEnabled) {
      return Text("Location not enabled :c", style: style);
    } else if (_permissionGranted != PermissionStatus.granted &&
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
              ElevatedButton(
                  onPressed: () {
                    requestServices();
                  },
                  child: Text("Update Permissions?")),
              Center(child: errorWidget()),
              Text(_locationData.toString()),
            ])));
  }
}
