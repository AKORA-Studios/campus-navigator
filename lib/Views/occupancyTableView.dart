import 'package:campus_navigator/api/building/roomOccupancyPlan.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

Widget occupancyTableView(
    List<List<List<String>>>? roomPlan, bool showOccupancyTable) {
  var basicStyle = const TextStyle(fontSize: 12);
  var boldStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
  List<Widget> allTables = [];

  if (roomPlan == null || !showOccupancyTable) {
    return const Column(children: []);
  }

  roomPlan!.forEachIndexed((i, table) {
    //  for (var table in roomPlan!) {
    List<TableRow> tableRows = [];

    table.forEachIndexed((index, row) {
      List<Widget> rowEntries = [];
      if (row.isEmpty) {
        return;
      }

      row.forEachIndexed((index2, entry) {
        if (index2 == 0 || index == 0) {
          //  Left side
          rowEntries.add(Text(entry, style: boldStyle));
        } else {
          rowEntries.add(Text(
            entry,
            style: basicStyle,
          ));
        }
      });

      // Add rows
      if (index == 0) {
        tableRows.add(TableRow(
            children: rowEntries,
            decoration: BoxDecoration(color: Colors.blue[300])));
      } else {
        tableRows.add(TableRow(children: rowEntries));
      }
    });

    // Don´t create table if it has no rows/entries
    if (tableRows.isEmpty) {
      return;
    }

    // Add completed table to Widget List
    var fullTable = Table(
      border: TableBorder.all(),
      children: tableRows,
    );
    if (tableRows.isNotEmpty) {
      allTables.add(Text(RoomOccupancyPlan.tableNames[i]));
      allTables.add(fullTable);
      allTables.add(const SizedBox(
        height: 10,
      ));
    }
  });

  return Column(children: allTables);
}
