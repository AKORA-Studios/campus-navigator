// Inspect a single saved, raw ISO-8859-1 TU API response without network access.
import 'dart:convert';
import 'dart:io';
import 'package:campus_navigator/api/campus/campus_building.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
        'Usage: dart run tools/inspect-campus.dart <raw-api-response.json>');
    exitCode = 64;
    return;
  }
  final raw = latin1.decode(File(args.single).readAsBytesSync());
  final buildings = parseCampusBuildings(raw);
  stdout.writeln(const JsonEncoder.withIndent('  ').convert({
    'sourceRecords': (jsonDecode(raw) as List).length,
    'parsedBuildings': buildings.length,
    'outlines': buildings.fold<int>(0, (n, b) => n + b.outlines.length),
    'vertices': buildings.fold<int>(
        0, (n, b) => n + b.outlines.fold<int>(0, (m, r) => m + r.length)),
    'withoutGeometry':
        buildings.where((b) => b.outlines.isEmpty).map((b) => b.code).toList(),
  }));
}
