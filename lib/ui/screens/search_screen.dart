import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/place_navigation.dart';
import 'package:campus_navigator/api/saved_places.dart';
import 'package:campus_navigator/api/search.dart';
import 'package:campus_navigator/ui/search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../campus_identity.dart';
import 'building_screen.dart';
import 'freeroom_search_screen.dart';
import 'settings_screen.dart';

class SearchScreen extends StatefulWidget {
  final PlaceStore? places;
  final RoomSearchController? search;
  final Future<BuildingPageData> Function(SavedPlace)? loadPlace;
  const SearchScreen({super.key, this.places, this.search, this.loadPlace});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final PlaceStore _places;
  late final RoomSearchController _search;
  final _textController = TextEditingController();
  String? _opening;

  AppLocalizations get _l => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _places = widget.places ?? PlaceStore();
    _search = widget.search ?? RoomSearchController();
    _places.addListener(_changed);
    _search.addListener(_changed);
    if (!_places.ready) _places.load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _places.removeListener(_changed);
    _search.removeListener(_changed);
    if (widget.places == null) _places.dispose();
    if (widget.search == null) _search.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggle(SavedPlace place) async {
    if (!await _places.toggle(place)) {
      _message(_l.favoritesSaveFailed);
    }
  }

  Future<void> _open(SavedPlace place) async {
    if (_opening != null) return;
    FocusScope.of(context).unfocus();
    setState(() => _opening = place.key);
    try {
      final data = await (widget.loadPlace ?? loadSavedPlace)(place);
      if (!mounted) {
        data.backgroundImageData?.dispose();
        return;
      }
      final saved = await _places.recordVisit(place);
      if (!mounted) {
        data.backgroundImageData?.dispose();
        return;
      }
      if (!saved) {
        _message(_l.historySaveFailed);
      }
      setState(() => _opening = null);
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BuildingScreen(
                  room: Future.value(data),
                  name: place.name,
                  favoriteAction: AnimatedBuilder(
                      animation: _places,
                      builder: (context, _) => _favoriteButton(place)))));
    } catch (_) {
      if (!mounted) return;
      _message(_l.floorUnavailable);
    } finally {
      if (mounted && _opening != null) setState(() => _opening = null);
    }
  }

  Widget _favoriteButton(SavedPlace place) {
    final selected = _places.contains(place);
    final enabled = _places.ready && !_places.saving;
    final label = selected ? _l.favoriteRemove : _l.favoriteAdd;
    return Semantics(
        label: _l.favoriteActionLabel(label, place.name),
        button: true,
        toggled: selected,
        enabled: enabled,
        excludeSemantics: true,
        onTap: enabled ? () => _toggle(place) : null,
        child: IconButton(
            key: ValueKey('favorite-${place.key}'),
            tooltip: label,
            icon: Icon(
                selected ? Icons.star_rounded : Icons.star_outline_rounded),
            color: selected ? Theme.of(context).colorScheme.primary : null,
            onPressed: enabled ? () => _toggle(place) : null));
  }

  Widget _entry(SavedPlace place,
          {String section = 'result', String? detail}) =>
      ListTile(
          key: ValueKey('place-$section-${place.key}'),
          contentPadding: EdgeInsets.zero,
          leading: CampusIdentity.wayfinding(context)
              ? BuildingCodeBadge(place.buildingCode)
              : Icon(
                  place.kind == PlaceKind.room
                      ? Icons.meeting_room_outlined
                      : Icons.business_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
          title: Text(place.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Tooltip(
              message: [detail, place.subName]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
              child: Text(
                  place.kind == PlaceKind.room
                      ? [
                          if (detail != null && detail.isNotEmpty) detail,
                          _l.roomContext(
                              place.buildingCode.toUpperCase(), place.floor!),
                          if (place.subName != null &&
                              place.subName != detail &&
                              !place.subName!.toLowerCase().startsWith(
                                  '${place.buildingCode.toLowerCase()}/'))
                            place.subName!,
                        ].join(' · ')
                      : '${place.buildingCode.toUpperCase()} · ${_l.buildingKind}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          trailing: _opening == place.key
              ? const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))))
              : _favoriteButton(place),
          onTap: _opening == null ? () => _open(place) : null);

  Widget _heading(String text, {Widget? action}) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: _search.query.isEmpty &&
                      MediaQuery.sizeOf(context).width >= 720
                  ? 48
                  : 0),
          child: Row(children: [
            Expanded(
                child:
                    Text(text, style: Theme.of(context).textTheme.titleSmall)),
            if (action != null) action,
          ])));

  Widget _empty(String text, IconData icon) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon,
            size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))),
      ]));

  List<Widget> _placeStatus() => [
        if (_places.loading) const LinearProgressIndicator(minHeight: 2),
        if (_places.loadFailed) ...[
          _empty(_l.placesLoadFailed, Icons.error_outline),
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                  onPressed: _places.loading ? null : _places.load,
                  child: Text(_l.tryAgain))),
        ],
      ];

  List<Widget> _favorites() => [
        _heading(_l.favoritesTitle),
        if (_places.favorites.isEmpty && !_places.loading)
          _empty(_l.favoritesEmpty, Icons.star_outline_rounded),
        ..._places.favorites.map((p) => _entry(p, section: 'favorite')),
      ];

  List<Widget> _recent() => [
        _heading(_l.recentTitle,
            action: _places.recent.isEmpty
                ? null
                : TextButton(
                    onPressed: _places.saving
                        ? null
                        : () async {
                            if (!await _places.clearHistory()) {
                              _message(_l.historyClearFailed);
                            }
                          },
                    child: Text(_l.clearHistoryAction))),
        if (_places.recent.isEmpty && !_places.loading)
          _empty(_l.recentEmpty, Icons.history),
        ..._places.recent.map((p) => _entry(p, section: 'recent')),
      ];

  List<Widget> _home() => [
        ..._placeStatus(),
        ..._favorites(),
        const Divider(height: 24),
        ..._recent()
      ];

  Widget _list(List<Widget> children, {Key? key}) => ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: children);

  Widget _content() => LayoutBuilder(builder: (context, bounds) {
        if (_search.query.isNotEmpty) return _list(_results());
        if (bounds.maxWidth < 720) return _list(_home());
        return Column(children: [
          ..._placeStatus(),
          Expanded(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Expanded(
                    child: _list(_favorites(),
                        key: const ValueKey('hub-favorites'))),
                const VerticalDivider(width: 1),
                Expanded(
                    child: _list(_recent(), key: const ValueKey('hub-recent'))),
              ])),
        ]);
      });

  List<Widget> _results() {
    final result = _search.result;
    final rooms = result?.resultsRooms
            .map((e) =>
                (place: SavedPlace.tryFromSearch(e, PlaceKind.room), result: e))
            .where((entry) => entry.place != null)
            .toList() ??
        <({SavedPlace? place, SearchResultObject result})>[];
    final buildings = result?.resultsBuildings
            .map((e) => SavedPlace.tryFromSearch(e, PlaceKind.building))
            .whereType<SavedPlace>()
            .toList() ??
        <SavedPlace>[];
    return [
      if (_search.loading) ...[
        const LinearProgressIndicator(minHeight: 2),
        _empty(_l.searchLoading, Icons.search),
      ],
      if (_search.failed) ...[
        _empty(_l.searchFailed, Icons.wifi_off),
        Align(
            alignment: Alignment.centerLeft,
            child:
                TextButton(onPressed: _search.retry, child: Text(_l.tryAgain))),
      ],
      if (result != null) ...[
        if (result.assist.isNotEmpty)
          Text(result.assist, style: Theme.of(context).textTheme.bodySmall),
        if (rooms.isNotEmpty) ...[
          _heading(_l.roomsTitle),
          ...rooms.map(
              (entry) => _entry(entry.place!, detail: entry.result.detail)),
        ],
        if (buildings.isNotEmpty) ...[
          _heading(_l.buildingsTitle),
          ...buildings.map(_entry),
        ],
        if (rooms.isEmpty && buildings.isEmpty)
          _empty(_l.searchNoResults, Icons.search_off),
        if (result.moreRooms || result.moreBuildings)
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  key: const ValueKey('load-all-search-results'),
                  onPressed: _search.loading ? null : _search.loadAllResults,
                  icon: _search.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_search.fullSearchFailed
                          ? Icons.refresh
                          : Icons.expand_more),
                  label: Text(_search.loading
                      ? _l.searchLoadingAll
                      : _search.fullSearchFailed
                          ? _l.searchRetryAll
                          : _l.searchLoadAll))),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('Campus Navigator',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            CampusActionButton(
                icon: const Icon(Icons.settings),
                label: _l.settingsScreen_Title,
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SettingsScreen(places: _places)))),
            CampusActionButton(
                icon:
                    const Badge(smallSize: 6, child: Icon(Icons.meeting_room)),
                label: _l.freeRoomExperimental,
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FreeroomSearchScreen()))),
          ]),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: TextField(
                            controller: _textController,
                            autocorrect: false,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                labelText: _l.searchHint,
                                hintText: _l.searchExample,
                                border: const OutlineInputBorder(),
                                suffixIcon: _textController.text.isEmpty
                                    ? null
                                    : CampusActionButton(
                                        label: _l.clearSearch,
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          _textController.clear();
                                          _search.change('');
                                        })),
                            onChanged: _search.change,
                            onSubmitted: (value) =>
                                _search.change(value, immediately: true))),
                    if (_opening != null)
                      const LinearProgressIndicator(minHeight: 2),
                    Expanded(child: _content()),
                  ])))));
}
