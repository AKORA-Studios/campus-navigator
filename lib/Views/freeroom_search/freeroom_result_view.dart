import 'package:flutter/material.dart';

import '../../api/freeroom_search/search_result.dart';

class FreeroomResultView extends StatefulWidget {
  final FreeroomSearchResult data;

  const FreeroomResultView({super.key, required this.data});

  @override
  State<FreeroomResultView> createState() => _FreeroomResultViewState();
}

class _FreeroomResultViewState extends State<FreeroomResultView> {
  @override
  void initState() {
    super.initState();
  }

  // Shorthand
  FreeroomSearchResult get data => widget.data;

  @override
  Widget build(BuildContext context) {
    final rows = widget.data.toTable();

    return SingleChildScrollView(
        child: Table(
      border: TableBorder.all(color: Colors.grey),
      children: rows
          .map((e) => TableRow(
              children: e
                  .map((e) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: e.map((e) => Text(e)).toList(),
                      ))
                  .toList()))
          .toList(),
    ));
  }
}
