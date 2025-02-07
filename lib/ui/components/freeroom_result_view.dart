import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/freeroom_search/search.dart';
import 'package:campus_navigator/api/networking.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:campus_navigator/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../api/freeroom_search/search_result.dart';
import '../screens/building_screen.dart';

class FreeroomResultView extends StatefulWidget {
  final FreeroomSearchResult data;

  const FreeroomResultView({super.key, required this.data});

  @override
  State<FreeroomResultView> createState() => _FreeroomResultViewState();
}

class _FreeroomResultViewState extends State<FreeroomResultView> {
  String? selectedBuilding;
  final TextEditingController _selectedBuildingController =
      TextEditingController();

  // Shorthand
  FreeroomSearchResult get data => widget.data;
  List<List<List<String>>> get tableData => data.toTable();

  @override
  void initState() {
    super.initState();

    setState(() {
      selectedBuilding = buildings().firstOrNull;
    });

    /* 
    // Enables prefix only search
    _selectedBuildingController.addListener(() {
      setState(() {
        selectedBuilding = _selectedBuildingController.text;
      });
    });
    */
  }

  Set<String> buildings() {
    return {...data.rooms.map((e) => e.split('/').first)};
  }

  /// Fetches the link of all free rooms in the provided building
  /// The results will then get cached and therefore speed up the
  /// user interaction by one RTT when a room is clicked on as the actual
  /// room link does not have to be fatched anymore
  prefetchBuildingRoomLinks(String building) async {
    final prefetchingLevel = await Storage.Shared.getPrefetchingLevel();
    if (prefetchingLevel == PrefetchingLevel.none) return;

    final freeRoomsInBuilding = data.rooms.where((r) => r.startsWith(building));

    // Wait for all room links to be fetched
    await Future.wait(freeRoomsInBuilding.map((formalRoomName) =>
        APIServices.Shared.fetchRoomLink(building, formalRoomName)));
  }

  DataCell buildCell(int day, int ds) {
    final freeRooms = tableData[day][ds - 1].where((element) => element
        .toLowerCase()
        .startsWith(selectedBuilding?.toLowerCase() ?? ""));

    final buttonStyle = ButtonStyle(
      padding: MaterialStateProperty.all(EdgeInsets.zero),
      minimumSize: MaterialStateProperty.all(Size.zero),
    );

    openRoomCallback(String building, String formalRoomName) {
      return () async {
        final links =
            await APIServices.Shared.fetchRoomLink(building, formalRoomName);
        final query = links.first.replaceFirst("$baseURL/etplan/", "");
        final pagePromise = BuildingPageData.fetchQuery(query);

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  BuildingScreen(room: pagePromise, name: formalRoomName)),
        );
      };
    }

    List<Widget> widgets = [];
    // Map<String, List<String>> grouped = {};
    for (final b in buildings()) {
      final freeRoomsInBuilding =
          freeRooms.where((r) => r.startsWith(b)).toList();

      List<Widget> subWidgets = [];
      final firstRoom = freeRoomsInBuilding.firstOrNull;
      if (firstRoom != null) {
        subWidgets.add(TextButton(
          style: buttonStyle,
          child: Text(firstRoom),
          onPressed: openRoomCallback(b, firstRoom),
        ));
      }

      subWidgets.addAll(freeRoomsInBuilding.skip(1).map((formalRoomName) {
        final parts = formalRoomName.split('/');
        final content = parts.skip(1).join('/');

        return TextButton(
          style: buttonStyle,
          child: Text.rich(
            TextSpan(children: <TextSpan>[
              TextSpan(
                  text: '$b/',
                  style: const TextStyle(color: Colors.transparent)),
              TextSpan(text: content)
            ]),
          ),
          onPressed: openRoomCallback(b, formalRoomName),
        );
      }));

      widgets.addAll(subWidgets);
    }

    return DataCell(Padding(
        padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
        )));
  }

  Widget tableView(localizations) {
    return DataTable(
      // allows rows to grow
      dataRowMaxHeight: double.infinity,
      columns: [
        'DS',
        localizations.weekdayOne,
        localizations.weekdayTwo,
        localizations.weekdayThree,
        localizations.weekdayFour,
        localizations.weekdayFive
      ].map((e) => DataColumn(label: Text(e))).toList(),
      rows: [1, 2, 3, 4, 5, 6, 7]
          .map((row) => DataRow(
                cells: [
                  DataCell(Text(ds_to_time(row))),
                  ...List<DataCell>.generate(
                      5, (int col) => buildCell(col, row))
                ],
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownMenu(
          dropdownMenuEntries: buildings()
              .map((e) => DropdownMenuEntry(value: e, label: e))
              .toList(),
          enableSearch: true,
          enableFilter: false,
          controller: _selectedBuildingController,
          label: Text(localizations.buildingScreen_FilterTitle),
          initialSelection: buildings().firstOrNull,
          onSelected: (String? text) {
            setState(() {
              selectedBuilding = text;
            });
          },
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              // The table will be as small as possible otherwise
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.sizeOf(context).width,
                ),
                child: tableView(localizations),
              )),
        )
      ],
    );
  }
}
