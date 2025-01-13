import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';

import '../../api/building/building_page_data.dart';
import '../../api/building/parsing/room_info.dart';
import '../styling.dart';

Widget adressSection(BuildingPageData roomPage, localizations) {
  List<Widget> arr = [
    SizedBox(
        child: Text(localizations.adresssection_Title, //TODO: Localize
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        width: double.infinity)
  ];
  for (RoomInfo child in roomPage.buildingData.rooms) {
    arr.add(SelectableText(
        child.fullTitle.split(',')[0].trim() +
            " [" +
            child.buildingNumber +
            "]",
        style: const TextStyle(fontWeight: FontWeight.bold)));
    arr.add(SelectableText.rich(TextSpan(children: [
      TextSpan(
          text: child.adress.replaceAll("<br>", "\n"),
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Styling.primaryColor,
              decorationColor: Styling.primaryColor,
              decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              MapsLauncher.launchQuery(child.adress.replaceAll("<br>", " "));
            }),
    ])));
    arr.add(const SizedBox(
      height: 10,
    ));
  }
  return Container(
    padding: const EdgeInsets.all(8.0),
    decoration: BoxDecoration(
      // border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Column(
      children: arr,
      crossAxisAlignment: CrossAxisAlignment.start,
    ),
  );
}
