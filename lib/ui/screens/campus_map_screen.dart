import 'dart:async';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/campus/campus_building.dart';
import 'package:campus_navigator/api/campus/campus_catalog.dart';
import 'package:campus_navigator/api/campus/campus_location.dart';
import 'package:campus_navigator/api/campus/campus_tiles.dart';
import 'package:campus_navigator/api/place_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../settings/app_settings_controller.dart';
import '../../settings/app_settings_scope.dart';
import '../campus_identity.dart';
import 'building_screen.dart';

const campusCenter = LatLng(51.0282, 13.7267);
const campusTileUrl = String.fromEnvironment('CAMPUS_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');

class CampusMapScreen extends StatefulWidget {
  final bool active;
  final CampusCatalog? catalog;
  final TileProvider? tiles;
  final Future<LatLng> Function()? locate;
  final Future<BuildingPageData> Function(String)? loadFloor;
  final Future<bool> Function(Uri)? launchRoute;
  const CampusMapScreen(
      {super.key,
      this.active = true,
      this.catalog,
      this.tiles,
      this.locate,
      this.loadFloor,
      this.launchRoute});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  late final CampusCatalog _catalog;
  late final TileProvider _tiles;
  final _map = MapController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'Campus building search');
  final LayerHitNotifier<CampusFeature> _hits = ValueNotifier(null);
  final _tileFailed = ValueNotifier(false);
  CampusFeature? _selected;
  CampusFeature? _pendingFocus;
  LatLng? _position;
  bool _locating = false;
  bool _opening = false;
  bool _routing = false;
  bool? _darkOverride;
  String _query = '';
  int _tileRevision = 0;
  int _zoomBucket = 16;
  bool _mapReady = false;
  final Set<String> _noPlans = {};
  List<Polygon<CampusFeature>> _polygons = [];
  List<CampusFeature>? _polygonBuildings;
  CampusFeature? _polygonSelection;
  bool? _polygonDark;
  int? _polygonZoom;

  AppLocalizations get _l => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _catalog = widget.catalog ?? CampusCatalog();
    _tiles = widget.tiles ??
        CampusTileProvider(onFailure: () {
          if (mounted && !_tileFailed.value) _tileFailed.value = true;
        });
    _catalog.addListener(_changed);
    // Don't notify ancestors during their build.
    unawaited(Future.microtask(() => _catalog.load()));
  }

  void _changed() {
    if (!mounted) return;
    final code = _selected?.code;
    setState(() {
      if (code != null) {
        _selected = _catalog.buildings.where((b) => b.code == code).firstOrNull;
      }
    });
  }

  @override
  void dispose() {
    _catalog.removeListener(_changed);
    if (widget.catalog == null) _catalog.dispose();
    _map.dispose();
    _hits.dispose();
    _tileFailed.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (mounted && widget.active) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _select(CampusFeature building, {bool focus = false}) {
    _searchFocus.unfocus();
    _search.clear();
    setState(() {
      _selected = building;
      _pendingFocus = focus ? building : null;
      _query = '';
    });
  }

  void _focusAfterLayout(bool keyboardOpen) {
    final building = _pendingFocus;
    if (building == null || !_mapReady || keyboardOpen) {
      return;
    }
    _pendingFocus = null;
    if (building.mapPoint == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.active || _selected?.code != building.code) {
        return;
      }
      _map.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(
              building.outlines.expand((r) => r).toList()),
          padding: const EdgeInsets.all(48),
          maxZoom: 18));
    });
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final point = await (widget.locate ?? locateOnCampus)();
      if (!mounted || !widget.active) return;
      setState(() => _position = point);
      _map.move(point, 17);
      _message(_l.mapLocationMeasured);
    } on CampusLocationException catch (error) {
      if (!mounted) return;
      _message(switch (error.reason) {
        CampusLocationFailure.denied => _l.mapLocationDenied,
        CampusLocationFailure.disabled => _l.mapLocationOff,
        CampusLocationFailure.unavailable => _l.mapLocationUnavailable,
      });
    } catch (_) {
      _message(_l.mapLocationUnavailable);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openFloor(CampusFeature building) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final data =
          await (widget.loadFloor ?? loadBuildingFloor)(building.floorCode);
      if (!mounted || !widget.active) {
        data.backgroundImageData?.dispose();
        return;
      }
      // A route must not restore the old search field's focus (and reopen the
      // keyboard, hiding the selected building's details) on the way back.
      _searchFocus.unfocus();
      _searchFocus.canRequestFocus = false;
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BuildingScreen(
                  room: Future.value(data), name: building.name)));
    } on FormatException catch (e) {
      if (mounted) {
        if (e.message == 'No floor plan available') {
          setState(() => _noPlans.add(building.code));
        } else {
          _message(_l.floorUnavailable);
        }
      }
    } catch (_) {
      _message(_l.floorUnavailable);
    } finally {
      if (mounted) {
        _searchFocus.canRequestFocus = true;
        setState(() => _opening = false);
      }
    }
  }

  Future<void> _route(CampusFeature building) async {
    if (_routing) return;
    final uri = building.routeUri;
    if (uri == null) {
      _message(_l.mapRouteInvalid);
      return;
    }
    setState(() => _routing = true);
    try {
      final opened = await (widget.launchRoute?.call(uri) ??
          launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!opened) {
        _message(_l.mapRouteAppMissing);
      }
    } catch (_) {
      _message(_l.mapRouteFailed);
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  void _retryTiles() {
    _tileFailed.value = false;
    setState(() => _tileRevision++);
  }

  List<Polygon<CampusFeature>> _buildingPolygons(bool dark) {
    if (identical(_polygonBuildings, _catalog.buildings) &&
        identical(_polygonSelection, _selected) &&
        _polygonDark == dark &&
        _polygonZoom == _zoomBucket) return _polygons;
    _polygonBuildings = _catalog.buildings;
    _polygonSelection = _selected;
    _polygonDark = dark;
    _polygonZoom = _zoomBucket;
    final ordered = _catalog.buildings.toList()
      ..sort(
          (a, b) => (a == _selected ? 1 : 0).compareTo(b == _selected ? 1 : 0));
    _polygons = [
      for (final building in ordered)
        for (final ring in building.outlines)
          Polygon<CampusFeature>(
              points: ring,
              hitValue: building,
              color: building == _selected
                  ? (dark ? const Color(0xff486c8c) : const Color(0xff9dbbd3))
                  : (dark ? const Color(0xff304657) : const Color(0xffd4e0e9)),
              borderColor: building == _selected
                  ? (dark ? const Color(0xffc5dff4) : const Color(0xff173657))
                  : (dark ? const Color(0xff8da8bc) : const Color(0xff527d9b)),
              borderStrokeWidth:
                  building == _selected ? 3 : (_zoomBucket >= 16 ? 1.3 : 0.8),
              label: _zoomBucket >= 16 || building == _selected
                  ? building.code
                  : null,
              labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : const Color(0xff173657)))
    ];
    return _polygons;
  }

  Widget _banner(BuildContext context, String text, VoidCallback retry,
          {bool busy = false}) =>
      Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 4),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(text,
                        style: Theme.of(context).textTheme.bodySmall)),
                TextButton(
                    onPressed: busy ? null : retry, child: Text(_l.tryAgain))
              ])));

  Widget _details(BuildContext context, CampusFeature b, bool wide) => Material(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
          key: const ValueKey('campus-building-details'),
          constraints: BoxConstraints(maxHeight: wide ? double.infinity : 230),
          decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant))),
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      if (CampusIdentity.wayfinding(context))
                        BuildingCodeBadge(b.code, announceCode: true)
                      else
                        Text(b.code,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                      const Spacer(),
                      CampusActionButton(
                          label: _l.mapCloseSelection,
                          onPressed: () => setState(() => _selected = null),
                          icon: const Icon(Icons.close))
                    ]),
                    Text(b.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (b.address != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(b.address!,
                              style: Theme.of(context).textTheme.bodySmall)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      FilledButton.icon(
                          key: const ValueKey('campus-open-floor'),
                          onPressed: _opening || _noPlans.contains(b.code)
                              ? null
                              : () => _openFloor(b),
                          icon: _opening
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.layers_outlined, size: 18),
                          label: Text(_noPlans.contains(b.code)
                              ? _l.mapNoFloorPlan
                              : _l.mapFloorPlans)),
                      OutlinedButton.icon(
                          key: const ValueKey('campus-route'),
                          onPressed: b.routeUri == null || _routing
                              ? null
                              : () => _route(b),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48)),
                          icon: const Icon(Icons.navigation_outlined, size: 18),
                          label: Text(_l.mapNavigate)),
                    ]),
                    const SizedBox(height: 4),
                    Text(_l.mapRouteNote,
                        style: Theme.of(context).textTheme.bodySmall),
                    if (b.outlines.isEmpty) Text(_l.mapGeometryMissing),
                  ]))));

  Widget _mapView(BuildContext context, bool dark, {bool tools = true}) =>
      LayoutBuilder(
          builder: (context, bounds) => Stack(children: [
                Positioned.fill(
                    child: RepaintBoundary(
                        child: FlutterMap(
                            mapController: _map,
                            options: MapOptions(
                                initialCenter: campusCenter,
                                initialZoom: 16,
                                minZoom: 5,
                                maxZoom: 20,
                                backgroundColor: dark
                                    ? const Color(0xff20282d)
                                    : const Color(0xffe8eeeb),
                                interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.all &
                                        ~InteractiveFlag.rotate),
                                onMapReady: () => _mapReady = true,
                                onPositionChanged: (camera, _) {
                                  final bucket = camera.zoom.floor();
                                  if (bucket != _zoomBucket) {
                                    setState(() => _zoomBucket = bucket);
                                  }
                                },
                                onTap: (_, point) {
                                  final hit = _hits.value;
                                  // Hit values belong to this pointer event; never choose a nearest
                                  // building when the user actually touched empty ground.
                                  if (hit != null && hit.hitValues.isNotEmpty) {
                                    _select(hit.hitValues.first);
                                  } else {
                                    _searchFocus.unfocus();
                                    setState(() => _selected = null);
                                  }
                                }),
                            children: [
                      TileLayer(
                          key: ValueKey(_tileRevision),
                          urlTemplate: campusTileUrl,
                          tileProvider: _tiles,
                          userAgentPackageName: 'com.example.campus_navigator',
                          panBuffer: 0,
                          keepBuffer: 2,
                          maxNativeZoom: 19,
                          retinaMode:
                              MediaQuery.devicePixelRatioOf(context) > 1,
                          tileBuilder: dark
                              ? (context, image, tile) => ColorFiltered(
                                  // One OSM source, a local night style; no extra tile requests.
                                  colorFilter: const ColorFilter.matrix([
                                    -.25,
                                    -.40,
                                    -.10,
                                    0,
                                    240,
                                    -.23,
                                    -.38,
                                    -.09,
                                    0,
                                    245,
                                    -.21,
                                    -.35,
                                    -.09,
                                    0,
                                    250,
                                    0,
                                    0,
                                    0,
                                    1,
                                    0,
                                  ]),
                                  child: image)
                              : null),
                      PolygonLayer<CampusFeature>(
                          polygons: _buildingPolygons(dark),
                          hitNotifier: _hits,
                          polygonCulling: true,
                          simplificationTolerance: 0,
                          drawLabelsLast: true),
                      if (_position != null)
                        MarkerLayer(markers: [
                          Marker(
                              point: _position!,
                              width: 28,
                              height: 28,
                              child: Tooltip(
                                  message: _l.mapLastPosition,
                                  child: Container(
                                      decoration: BoxDecoration(
                                          color: const Color(0xff1769d2),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 3)),
                                      child: const Icon(Icons.circle,
                                          size: 10, color: Colors.white))))
                        ]),
                    ]))),
                if (tools)
                  Positioned(
                      right: 12,
                      top: 12,
                      child: Flex(
                          mainAxisSize: MainAxisSize.min,
                          direction: bounds.maxHeight < 260
                              ? Axis.horizontal
                              : Axis.vertical,
                          children: [
                            _mapButton(
                                context,
                                _l.mapShowCampus,
                                Icons.school_outlined,
                                () => _map.move(campusCenter, 16)),
                            const SizedBox(height: 8, width: 8),
                            _mapButton(
                                context,
                                _l.mapLocate,
                                _locating
                                    ? Icons.hourglass_top
                                    : Icons.my_location,
                                _locating ? null : _locate),
                            const SizedBox(height: 8, width: 8),
                            _mapButton(
                                context,
                                _l.mapZoomIn,
                                Icons.add,
                                () => _map.move(_map.camera.center,
                                    (_map.camera.zoom + 1).clamp(5, 20))),
                            _mapButton(
                                context,
                                _l.mapZoomOut,
                                Icons.remove,
                                () => _map.move(_map.camera.center,
                                    (_map.camera.zoom - 1).clamp(5, 20))),
                          ])),
                Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              InkWell(
                                  onTap: () => launchUrl(
                                      Uri.parse(
                                          'https://www.openstreetmap.org/copyright'),
                                      mode: LaunchMode.externalApplication),
                                  child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      child: Text(
                                          '© OpenStreetMap contributors',
                                          style: TextStyle(fontSize: 11)))),
                              InkWell(
                                  onTap: () => launchUrl(
                                      Uri.parse(
                                          'https://navigator.tu-dresden.de/'),
                                      mode: LaunchMode.externalApplication),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      child: Text(_l.mapBuildingsSource,
                                          style:
                                              const TextStyle(fontSize: 11)))),
                            ]))),
              ]));

  Widget _mapButton(BuildContext context, String label, IconData icon,
          VoidCallback? action) =>
      Material(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant)),
          child: CampusActionButton(
              label: label, onPressed: action, icon: Icon(icon)));

  Widget _content(BuildContext context, bool dark) {
    // Read above this Scaffold: its resized body removes the keyboard inset.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final matches = _query.isEmpty
        ? <CampusFeature>[]
        : _catalog.buildings
            .where((b) => '${b.code} ${b.name} ${b.address ?? ''}'
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .take(12)
            .toList();
    return Scaffold(
        appBar: AppBar(title: Text(_l.settingsMapThemeTitle), actions: [
          CampusActionButton(
              label: _l.mapStyle,
              onPressed: () {
                final settings = AppSettingsScope.maybeOf(context);
                if (settings == null) {
                  setState(() => _darkOverride = !dark);
                  return;
                }
                settings
                    .setCampusMapThemeMode(dark
                        ? CampusMapThemeMode.light
                        : CampusMapThemeMode.dark)
                    .catchError((_) => _message(_l.settingsSaveFailure));
              },
              icon: Icon(
                  dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined)),
          CampusActionButton(
              label: _l.mapRefresh,
              onPressed:
                  _catalog.busy ? null : () => _catalog.load(refresh: true),
              icon: const Icon(Icons.refresh)),
        ]),
        body: SafeArea(
            top: false,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: TextField(
                      key: const ValueKey('campus-search'),
                      controller: _search,
                      focusNode: _searchFocus,
                      autocorrect: false,
                      decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(Icons.search),
                          labelText: _l.mapSearchHint,
                          hintText: _l.mapSearchExample,
                          border: const OutlineInputBorder(),
                          suffixIcon: _query.isEmpty
                              ? null
                              : CampusActionButton(
                                  label: _l.clearSearch,
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() => _query = '');
                                  })),
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                      onSubmitted: (_) {
                        if (matches.isNotEmpty) {
                          _select(matches.first, focus: true);
                        }
                      })),
              if (_query.isNotEmpty)
                Flexible(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 176),
                        child: matches.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(_l.mapNoResults))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: matches.length,
                                itemBuilder: (context, i) {
                                  final b = matches[i];
                                  return ListTile(
                                      key: ValueKey('campus-result-${b.code}'),
                                      leading:
                                          CampusIdentity.wayfinding(context)
                                              ? BuildingCodeBadge(b.code,
                                                  announceCode: true)
                                              : Text(b.code,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge),
                                      title: Text(b.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      onTap: () => _select(b, focus: true));
                                }))),
              if (_catalog.busy) const LinearProgressIndicator(minHeight: 2),
              if (_catalog.failed ||
                  _catalog.stale ||
                  _catalog.cacheWriteFailed)
                _banner(
                    context,
                    _catalog.buildings.isEmpty
                        ? _l.mapBuildingsUnavailable
                        : _catalog.stale
                            ? _l.mapBuildingsStale
                            : _l.mapBuildingsNotSaved,
                    () => _catalog.load(refresh: true),
                    busy: _catalog.busy),
              ValueListenableBuilder<bool>(
                  valueListenable: _tileFailed,
                  builder: (context, failed, _) => failed
                      ? _banner(context, _l.mapTilesUnavailable, _retryTiles)
                      : const SizedBox()),
              Expanded(child: LayoutBuilder(builder: (context, bounds) {
                _focusAfterLayout(keyboardOpen);
                final wide = bounds.maxWidth >= 840;
                // During keyboard entry the map keeps the available height.
                final details =
                    _query.isEmpty && _selected != null && !keyboardOpen
                        ? _details(context, _selected!, wide)
                        : null;
                if (wide) {
                  return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                            child:
                                _mapView(context, dark, tools: !keyboardOpen)),
                        if (details != null)
                          SizedBox(width: 320, child: details)
                      ]);
                }
                return Column(children: [
                  Expanded(
                      child: _mapView(context, dark, tools: !keyboardOpen)),
                  if (details != null)
                    ConstrainedBox(
                        constraints:
                            BoxConstraints(maxHeight: bounds.maxHeight * .5),
                        child: details)
                ]);
              })),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    final dark = settings == null
        ? (_darkOverride ?? Theme.of(context).brightness == Brightness.dark)
        : switch (settings.campusMapThemeMode) {
            CampusMapThemeMode.automatic =>
              Theme.of(context).brightness == Brightness.dark,
            CampusMapThemeMode.light => false,
            CampusMapThemeMode.dark => true,
          };
    return Theme(
        data:
            CampusIdentity.themeData(dark ? Brightness.dark : Brightness.light),
        child: Builder(builder: (context) => _content(context, dark)));
  }
}
