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

  // Update button color when new position is found
  Color locationUpdateColor = Colors.grey;
  Location oldLocation = Location();

  @override
  void dispose() {
    locationListener?.cancel();
    super.dispose();
  }

  Future<void> updateLocationIcon() async {
    setState(() {
      locationUpdateColor = Colors.green;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      locationUpdateColor = Colors.grey;
    });
  }

  @override
  void initState() {
    super.initState();
    requestServices();

    locationListener =
        location.onLocationChanged.listen((LocationData currentLocation) {
      // If the received location contains a latitude and longitude we check
      // if it lies in one of he buildings
      final lat = currentLocation.latitude;
      final long = currentLocation.longitude;
      if (lat != null && long != null) {
        campusMapData.then((map) {
          final foundBuilding = map.checkLocation(long, lat);

          if (location != oldLocation || location == Location()) {
            updateLocationIcon();
          }
          oldLocation = location;

          setState(() {
            currentBuilding = foundBuilding;

            if (foundBuilding != null) {
              buildingPageData =
                  BuildingPageData.fetchQuery(foundBuilding.query);
            }
          });
          // Navigate into building if one is found
          if (foundBuilding != null) {
            Route route = MaterialPageRoute(
                builder: (context) => BuildingScreen(
                    room: BuildingPageData.fetchQuery(foundBuilding.query),
                    name: "${currentBuilding?.shortName}"));
            Navigator.pushReplacement(context, route);
            // Stop listening for location updates
            locationListener?.cancel();
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

  Widget errorWidget(localizations) {
    var style = const TextStyle(fontWeight: FontWeight.bold);

    if (!_serviceEnabled) {
      return Container(
          color: Colors.red,
          child: Text(localizations.locationScreenErrorText, style: style));
    } else if (_permissionGranted != PermissionStatus.granted &&
        _permissionGranted != PermissionStatus.grantedLimited) {
      return Container(
          color: Colors.grey,
          child: Text(_permissionGranted.toString(), style: style));
    } else {
      return Container(
          color: Colors.grey,
          child: Text(
              _locationData == null
                  ? ""
                  : "${_locationData?.latitude} ${_locationData?.longitude}",
              style: style));
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
          actions: [
            IconButton(
                tooltip: localizations.locationScreenUpdateText,
                onPressed: () {
                  requestServices();
                },
                icon: const Icon(Icons.refresh)),
            IconButton(
                tooltip: "Update info",
                onPressed: null,
                icon: Icon(
                  Icons.location_on,
                  color: locationUpdateColor,
                ))
          ],
        ),
        body: Stack(
          children: [
            Column(children: [Center(child: errorWidget(localizations))]),
            _serviceEnabled
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox(),
            Opacity(
                opacity: 0.4,
                child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage('images/campusMap.png'),
                      ),
                    )))
          ],
        ));
  }
}
