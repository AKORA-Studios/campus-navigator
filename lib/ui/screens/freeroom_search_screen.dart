import 'dart:math';

import 'package:campus_navigator/api/freeroom_search/search_options.dart';
import 'package:flutter/material.dart';
import 'package:week_number/iso.dart';

import '../styling.dart';
import '../../api/freeroom_search/search.dart';
import '../../api/freeroom_search/search_result.dart';
import '../../api/storage.dart';
import '../components/freeroom_result_view.dart';

class FreeroomSearchScreen extends StatefulWidget {
  const FreeroomSearchScreen({super.key});

  @override
  State<FreeroomSearchScreen> createState() => _FreeroomSearchScreenState();
}

class _FreeroomSearchScreenState extends State<FreeroomSearchScreen> {
  Future<FreeroomSearchResult>? result;
  Set<UserUniversity> selectedUniversities = {...UserUniversity.values};
  RangeValues weekRange = const RangeValues(43, 43);
  Repetition repetition = Repetition.once;

  @override
  void initState() {
    super.initState();

    updateSearch();

    final weekNumber = DateTime.now().weekNumber.toDouble();
    weekRange = RangeValues(weekNumber, (weekNumber + 3) % 53);
  }

  updateSearch() {
    result = searchFreeRooms(
        startWeek: weekRange.start.round(),
        endWeek: weekRange.end.round(),
        universities: selectedUniversities,
        repetition: repetition,
        maxCapacity: 20);
  }

  Widget weekSelector() {
    const minWeek = 1;
    const maxWeek = 52;
    const divisions = maxWeek - minWeek;

    final startLabel = weekRange.start.round().toString();
    final endLabel = weekRange.end.round().toString();

    if (repetition == Repetition.once) {
      return Slider.adaptive(
          min: minWeek.toDouble(),
          max: maxWeek.toDouble(),
          divisions: divisions,
          value: weekRange.start,
          label: startLabel,
          onChanged: (newValue) {
            setState(() {
              weekRange = RangeValues(newValue, max(weekRange.end, newValue));
            });
          });
    } else {
      // TODO: Use slider theme to gray out ends when they're at the max
      // TODO: Somehow allow disabling min and max restrictions
      return RangeSlider(
          values: weekRange,
          min: minWeek.toDouble(),
          max: maxWeek.toDouble(),
          divisions: divisions,
          labels: RangeLabels(startLabel, endLabel),
          onChanged: (newValue) {
            setState(() {
              weekRange = newValue;
            });
          });
    }
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
                  weekSelector(),
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
