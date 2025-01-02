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
    return SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [...data.rooms.map((r) => Text(r))]));
  }
}
