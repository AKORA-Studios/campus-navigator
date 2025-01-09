import 'dart:async';

import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/building/parsing/campus_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:location/location.dart';

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
          // Navigate into building if one is found
          if (foundBuilding != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BuildingScreen(
                      room: BuildingPageData.fetchQuery(foundBuilding.query),
                      name: "${currentBuilding?.shortName}!")),
            );
          }
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

  Widget errorWidget(localitzations) {
    var style = const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
    if (!_serviceEnabled) {
      return Text(localitzations.locationScreenErrorText, style: style);
    } else if (_permissionGranted != PermissionStatus.granted &&
        _permissionGranted != PermissionStatus.grantedLimited) {
      return Text(_permissionGranted.toString(), style: style);
    } else {
      return Text(_locationData == null
          ? ""
          : "${_locationData?.latitude} ${_locationData?.longitude}");
    }
  }

  void onError(var e) {
    print(e);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.name),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(10.0),
            child: Column(children: [
              Text(localizations.locationScreenBuildingText),
              ElevatedButton(
                  onPressed: () {
                    requestServices();
                  },
                  child: Text(localizations.locationScreenUpdateText)),
              Center(child: errorWidget(localizations)),
              Text(localizations.locationScreenText +
                  "${currentBuilding?.shortName}")
            ])));
  }
}
