import 'dart:async';

import 'package:campus_navigator/ui/components/floor_view.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/building/parsing/campus_map.dart';
import 'package:campus_navigator/api/networking.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

import 'building_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key, required this.name});

  final String name;

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Location location = Location();
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  LocationData? _locationData;

  StreamSubscription<LocationData>? locationListener;

  /// Future to fetch the entire campus map
  Future<CampusMapData> campusMapData = CampusMapData.fetch();

  /// The building the current `_locationData` lies in
  CampusBuilding? currentBuilding;

  Future<BuildingPageData>? buildingPageData;

  @override
  void dispose() {
    locationListener?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    locationListener =
        location.onLocationChanged.listen((LocationData currentLocation) {
      // If the received location contains a latitude and longitude we check
      // if it lies in one of he buildings
      final lat = currentLocation.latitude;
      final long = currentLocation.longitude;
      if (lat != null && long != null) {
        campusMapData.then((map) {
          final foundBuilding = map.checkLocation(long, lat);

          setState(() {
            currentBuilding = foundBuilding;

            if (foundBuilding != null) {
              buildingPageData =
                  BuildingPageData.fetchQuery(foundBuilding.query);
            }
          });
        });
      }

      setState(() {
        _locationData = currentLocation;
      });
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

  void checkIfInBuilding() {}

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
              const Text("Get plan of the building your currently in:"),
              ElevatedButton(
                  onPressed: () {
                    requestServices();
                  },
                  child: const Text("Update Permissions?")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BuildingScreen(
                              room: BuildingPageData.fetchQuery("pot/00"),
                              name: "aha!")),
                    );

                    requestServices();
                  },
                  child: const Text("Test")),
              Center(child: errorWidget()),
              Text(_locationData.toString()),
              Text("In building ${currentBuilding?.shortName}"),
              RichText(
                text: TextSpan(
                  text: 'but this is',
                  style: const TextStyle(color: Colors.blue),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(Uri.parse(
                          '$baseURL/etplan/${currentBuilding?.query}'));
                    },
                ),
              ),
              buildingPageData != null
                  ? asyncFloorView(buildingPageData!)
                  : const Text("nodata")
            ])));
  }
}
