import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../api/campus/campus_catalog.dart';
import '../../api/saved_places.dart';
import '../search_controller.dart';
import 'campus_map_screen.dart';
import 'search_screen.dart';

/// Lazy campus creation preserves the search screen, query, favorites and map
/// camera when switching. Floor screens remain ordinary Navigator routes.
class HomeScreen extends StatefulWidget {
  final CampusCatalog? catalog;
  final TileProvider? tiles;
  final PlaceStore? places;
  final RoomSearchController? search;
  const HomeScreen(
      {super.key, this.catalog, this.tiles, this.places, this.search});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  bool _mapVisited = false;
  final _tabsKey = GlobalKey();

  void _select(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _index = index;
      _mapVisited |= index == 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final tabs = IndexedStack(key: _tabsKey, index: _index, children: [
      SearchScreen(places: widget.places, search: widget.search),
      if (_mapVisited)
        TickerMode(
            enabled: _index == 1,
            child: CampusMapScreen(
                active: _index == 1,
                catalog: widget.catalog,
                tiles: widget.tiles))
      else
        const SizedBox(),
    ]);
    return Scaffold(
        // Each tab owns its keyboard resizing; keep the actual inset available
        // to the campus camera until the keyboard has finished closing.
        resizeToAvoidBottomInset: false,
        body: Row(children: [
          if (wide) ...[
            NavigationRail(
                minWidth: 112,
                labelType: NavigationRailLabelType.all,
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: [
                  NavigationRailDestination(
                      icon: const Icon(Icons.search),
                      label: SizedBox(
                          width: 96,
                          child: Text(l.navSearch,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center))),
                  NavigationRailDestination(
                      icon: const Icon(Icons.map_outlined),
                      selectedIcon: const Icon(Icons.map),
                      label: SizedBox(
                          width: 96,
                          child: Text(l.navCampus,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center))),
                ]),
            const VerticalDivider(width: 1),
          ],
          Expanded(child: tabs),
        ]),
        bottomNavigationBar: wide || keyboardOpen
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: [
                    NavigationDestination(
                        icon: const Icon(Icons.search), label: l.navSearch),
                    NavigationDestination(
                        icon: const Icon(Icons.map_outlined),
                        selectedIcon: const Icon(Icons.map),
                        label: l.navCampus),
                  ]));
  }
}
