import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../../api/freeroom_search/search_result.dart';

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

  Widget tableView() {
    return DataTable(
      // allows rows to grow
      dataRowMaxHeight: double.infinity,
      columnSpacing: 10.0,

      columns: ['DS', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag']
          .map((e) => DataColumn(label: Text(e)))
          .toList(),
      rows: [1, 2, 3, 4, 5, 6, 7]
          .map((e) => DataRow(
                cells: [
                  DataCell(Text("$e. DS")),
                  ...List<DataCell>.generate(
                      5,
                      (int index) => DataCell(Text(tableData[index][e - 1]
                          .where((element) => element.toLowerCase().startsWith(
                              selectedBuilding?.toLowerCase() ?? ""))
                          .join('\n'))))
                ],
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          label: const Text("Filter"),
          initialSelection: buildings().firstOrNull,
          onSelected: (String? text) {
            setState(() {
              selectedBuilding = text;
            });
          },
        ),
        tableView()
      ],
    );
  }
}
