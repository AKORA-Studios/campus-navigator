import 'package:campus_navigator/api/freeroom_search/search_options.dart';
import 'package:flutter/material.dart';

import '../../Styling.dart';
import '../../api/freeroom_search/search.dart';
import '../../api/freeroom_search/search_result.dart';
import '../../api/storage.dart';
import 'freeroom_result_view.dart';

class FreeroomSearchView extends StatefulWidget {
  const FreeroomSearchView({super.key});

  @override
  State<FreeroomSearchView> createState() => _FreeroomSearchViewState();
}

class _FreeroomSearchViewState extends State<FreeroomSearchView> {
  Future<FreeroomSearchResult>? result;
  Set<UserUniversity> selectedUniversities = {...UserUniversity.values};
  RangeValues weekRange = const RangeValues(43, 43);
  Repetition repetition = Repetition.once;

  @override
  void initState() {
    super.initState();

    updateSearch();
  }

  updateSearch() {
    result = searchFreeRooms(
        startWeek: weekRange.start.round(),
        endWeek: weekRange.end.round(),
        universities: selectedUniversities,
        repetition: repetition,
        maxCapacity: 20);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Freiraumsuche"),
        ),
        body: Container(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SegmentedButton<UserUniversity>(
                    multiSelectionEnabled: true,
                    showSelectedIcon: false,
                    style: Styling.settingsSegmentedButtonStyle,
                    segments: const <ButtonSegment<UserUniversity>>[
                      ButtonSegment<UserUniversity>(
                        value: UserUniversity.TUD,
                        label: Text('TUD'),
                      ),
                      ButtonSegment<UserUniversity>(
                        value: UserUniversity.HTW,
                        label: Text('HTW'),
                      ),
                    ],
                    selected: selectedUniversities,
                    onSelectionChanged:
                        (Set<UserUniversity> newSelection) async {
                      setState(() {
                        selectedUniversities = newSelection;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<Repetition>(
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                    style: Styling.settingsSegmentedButtonStyle,
                    segments: const <ButtonSegment<Repetition>>[
                      ButtonSegment<Repetition>(
                        value: Repetition.once,
                        label: Text('Einmalig'),
                      ),
                      ButtonSegment<Repetition>(
                        value: Repetition.weekly,
                        label: Text('Wöchentlich'),
                      ),
                      ButtonSegment<Repetition>(
                        value: Repetition.biWeekly,
                        label: Text('Zweiwöchentlich'),
                      ),
                    ],
                    selected: {repetition},
                    onSelectionChanged: (Set<Repetition> newSelection) async {
                      setState(() {
                        repetition = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  // TODO: Use slider theme to gray out ends when they're at the max
                  RangeSlider(
                      values: weekRange,
                      min: 1,
                      max: 52,
                      divisions: 51,
                      labels: RangeLabels(
                        weekRange.start.round().toString(),
                        weekRange.end.round().toString(),
                      ),
                      inactiveColor: Colors.red,
                      onChanged: (newValue) {
                        setState(() {
                          weekRange = newValue;
                        });
                      }),
                  const SizedBox(height: 20),
                  TextButton.icon(
                      onPressed: () {
                        setState(() {
                          updateSearch();
                        });
                      },
                      icon: const Icon(Icons.search),
                      label: const Text("Suchen")),

                  // Spacing
                  const SizedBox(
                    height: 20,
                  ),

                  FutureBuilder(
                    future: result,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        throw snapshot.error!;
                        //return Text('${snapshot.error}');
                      } else if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      return FreeroomResultView(data: snapshot.data!);
                    },
                  )
                ],
              ),
            )));
  }
}
