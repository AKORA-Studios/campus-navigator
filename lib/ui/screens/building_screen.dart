// ignore_for_file: must_be_immutable

import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/building/parsing/building_levels.dart';
import 'package:campus_navigator/api/building/roomOccupancyPlan.dart';
import 'package:campus_navigator/api/networking.dart';
import 'package:campus_navigator/ui/components/adress_section_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/login.dart';
import '../../api/storage.dart';
import '../components/bottom_sheet_view.dart';
import '../components/floor_view.dart';
import '../components/occupancyTableView.dart';
import '../campus_identity.dart';
import '../styling.dart';

class BuildingScreen extends StatefulWidget {
  BuildingScreen(
      {super.key, required this.room, required this.name, this.favoriteAction});

  Future<BuildingPageData> room;
  final String name;
  final Widget? favoriteAction;

  @override
  State<BuildingScreen> createState() => _BuildingScreenState();
}

class _BuildingScreenState extends State<BuildingScreen> {
  String? selectedLevel;
  bool isRoomSelected = false;
  String? roomURL;
  List<List<List<String>>>? roomPlan;
  bool showOccupancyTable = false;
  String? errorMessageOccupancyTable;
  String? _originalQuery;
  String? _originalLevel;
  final List<Future<BuildingPageData>> _ownedPages = [];
  Set<layerFilterOptions> selectedFilters = {};

  @override
  void dispose() {
    for (final page in _ownedPages) {
      page.then((data) => data.backgroundImageData?.dispose(), onError: (_) {});
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    selectedFilters = Set.of(APIServices.Shared.storage.filterSet);
    _ownedPages.add(widget.room);
    widget.room.then((room) {
      if (!mounted) return;
      setState(() {
        selectedLevel = room.buildingData.getCurrentLevel()?.name;
        _originalLevel = selectedLevel;
        _originalQuery = room.queryParts.join("/");
        roomURL = room.selectedRoom?.id;
        isRoomSelected = roomURL != null;
      });
    }, onError: (_) {});
  }

  Future<void> loadOccupancyTable(localizations, String currentLocale) async {
    setState(() => showOccupancyTable = !showOccupancyTable);
    final id = roomURL;
    if (!showOccupancyTable || id == null) return;
    final level = selectedLevel;
    try {
      final token = await APIServices.Shared.postLogin();
      final content = await APIServices.Shared.getRoomPlan(
          id, token.loginToken, currentLocale);
      if (!mounted || !showOccupancyTable || level != selectedLevel) return;
      setState(() {
        roomPlan = content;
        if (content.isEmpty)
          errorMessageOccupancyTable =
              localizations.buildingScreen_occupancyError;
      });
    } catch (e) {
      if (mounted && level == selectedLevel) onError(e);
    }
  }

  void onError(Object e) {
    if (!mounted) return;
    setState(() {
      errorMessageOccupancyTable =
          AppLocalizations.of(context)!.occupancyFailed;
    });
  }

  void openRoomPlan() async {
    if (roomURL != null && roomURL!.isNotEmpty) {
      final Uri _url = Uri.parse(baseURL + "/raum/" + roomURL!);
      if (!await launchUrl(_url)) {
        launchUrl(_url);
      }
    }
  }

  Widget futurify(
      Widget Function(BuildingPageData) widgetBuilder, localizations) {
    return FutureBuilder<BuildingPageData>(
        future: widget.room,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(localizations.floorUnavailable);
          }
          if (!snapshot.hasData) return const SizedBox.shrink();

          final room = snapshot.data!;
          return widgetBuilder(room);
        });
  }

  String _filterLabel(layerFilterOptions option) {
    final l = AppLocalizations.of(context)!;
    final names = [
      l.filterLabels,
      l.filterSeminarRooms,
      l.filterToilets,
      l.filterAccessibleToilets,
      l.filterStairs,
      l.filterElevators,
      l.filterOtherRooms,
      l.filterWifi,
      l.filterDefibrillators,
      l.filterChangingTables,
    ];
    return names[option.index];
  }

  Widget filterOptionEntry(layerFilterOptions opt) {
    return StatefulBuilder(
      builder: (context, _setState) {
        return Row(
          children: [
            Checkbox(
              value: selectedFilters.contains(opt),
              activeColor: Theme.of(context).colorScheme.primary,
              checkColor: Theme.of(context).colorScheme.onPrimary,
              onChanged: (isSelected) {
                if (isSelected == true) {
                  selectedFilters.add(opt);
                  APIServices.Shared.storage.filterSet.add(opt);
                } else {
                  selectedFilters.remove(opt);
                  APIServices.Shared.storage.filterSet.remove(opt);
                }
                _setState(() {}); // Update checkbox state
                setState(() {}); // Update parent widget
              },
            ),
            const SizedBox(width: 5),
            Icon(opt.icon),
            const SizedBox(width: 5),
            Expanded(child: Text(_filterLabel(opt))),
          ],
        );
      },
    );
  }

  Widget levelSelectionMenu(BuildingPageData roomPage) {
    List<DropdownMenuItem<String>> options = [];

    for (BuildingLevel lev in roomPage.buildingData.levels) {
      options.add(DropdownMenuItem(
        child: Text(
            AppLocalizations.of(context)!.floorLabel(lev.name.split(' ').last),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        value: lev.name,
      ));
    }
    return DropdownButton<String>(
        isExpanded: true,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(8),
        value: selectedLevel,
        items: options,
        onChanged: (value) {
          if (value == null || value == selectedLevel) return;
          final previous = widget.room;
          setState(() {
            selectedLevel = value;
            widget.room = value == _originalLevel
                ? BuildingPageData.fetchQuery(_originalQuery!)
                : BuildingPageData.fetchQuery(
                    '${roomPage.queryParts.first}/${value.split(" ").last}');
            if (!_ownedPages.contains(widget.room))
              _ownedPages.add(widget.room);
            isRoomSelected = value == _originalLevel && roomURL != null;
            showOccupancyTable = false;
            roomPlan = null;
            errorMessageOccupancyTable = null;
          });
          // Keep decoded tiles for the current floor only. Returning to the
          // original target reuses cached response bytes and its exact room URL.
          _ownedPages.remove(previous);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            previous.then((data) => data.backgroundImageData?.dispose(),
                onError: (_) {});
          });
        });
  }

  Widget occupancyButtons(localizations, currentLocale) {
    return isRoomSelected
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                  child: TextButton(
                      onPressed: () {
                        loadOccupancyTable(localizations, currentLocale);
                      },
                      child: Text(showOccupancyTable
                          ? localizations.buildingScreen_occupancyPlan_Hide
                          : localizations.buildingScreen_occupancyPlan_Show))),
              IconButton(
                  tooltip: localizations.buildingScreen_openinWeb,
                  onPressed: isRoomSelected ? openRoomPlan : null,
                  icon: const Icon(Icons.open_in_browser))
            ],
          )
        : const SizedBox();
  }

  Widget _details(localizations, currentLocale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          occupancyButtons(localizations, currentLocale),
          if (showOccupancyTable)
            occupancyTableView(roomPlan, showOccupancyTable, context: context),
          if (errorMessageOccupancyTable != null)
            Padding(
                padding: const EdgeInsets.all(8),
                child: Text(errorMessageOccupancyTable!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          const Divider(),
          futurify(
              (data) => adressSection(data, localizations, context: context),
              localizations),
        ],
      );

  Widget _toolbar(localizations) => Container(
        height: 36 + MediaQuery.textScalerOf(context).scale(16),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
                bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant))),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          Expanded(
              child: TextButton.icon(
            icon: const Icon(Icons.layers_outlined, size: 20),
            label: Text(localizations.filterCount(selectedFilters.length),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => FractionallySizedBox(
                    heightFactor: 0.75,
                    child: SingleChildScrollView(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              Text(localizations.buildingScreen_FilterOptions,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              ...layerFilterOptions.values
                                  .map(filterOptionEntry)
                            ]))))),
          )),
          const SizedBox(width: 8),
          Expanded(child: futurify(levelSelectionMenu, localizations)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = localizations.localeName;
    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            if (widget.favoriteAction != null) widget.favoriteAction!,
            CampusActionButton(
                icon: const Icon(Icons.share),
                label: localizations.roomShare,
                onPressed: () async {
                  final data = await widget.room;
                  if (!mounted) return;
                  Share.share('$baseURL/etplan/${data.queryParts.join("/")}');
                })
          ]),
      body: SafeArea(
          top: false,
          child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            final headerHeight = DraggableBottomSheet.headerHeight(context);
            final details = _details(localizations, currentLocale);
            final map = Column(children: [
              _toolbar(localizations),
              Expanded(
                  child: wide
                      ? _floor()
                      : Stack(children: [
                          // The collapsed 64px header has its own space; the fit view is fully visible.
                          Positioned.fill(
                              bottom: headerHeight, child: _floor()),
                          DraggableBottomSheet(
                              name: widget.name,
                              leading: CampusIdentity.wayfinding(context)
                                  ? BuildingCodeBadge(
                                      _originalQuery?.split('/').first ??
                                          widget.name.split('/').first)
                                  : null,
                              child: details),
                        ])),
            ]);
            if (!wide) return map;
            return Row(children: [
              Expanded(child: map),
              Container(
                  width: 300,
                  height: double.infinity,
                  decoration: BoxDecoration(
                      border: Border(
                          left: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant))),
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              if (CampusIdentity.wayfinding(context)) ...[
                                BuildingCodeBadge(
                                    _originalQuery?.split('/').first ??
                                        widget.name.split('/').first),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                  child: Text(widget.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium)),
                            ]),
                            const SizedBox(height: 12),
                            details,
                          ]))),
            ]);
          })),
    );
  }

  Widget _floor() => Theme(
      // Drawings keep every existing semantic color and transformation.
      data: AppTheme.themeData(Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkColorScheme
          : AppTheme.lightColorScheme),
      child: asyncFloorView(widget.room));
}
