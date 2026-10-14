// Native design study only. Not imported by lib/main.dart and not a release.
// Configure through run-as in a debug APK; see preview-identity.ps1.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/campus/campus_building.dart';
import 'package:campus_navigator/api/campus/campus_catalog.dart';
import 'package:campus_navigator/api/campus/campus_tiles.dart';
import 'package:campus_navigator/ui/components/floor_view.dart';
import 'package:campus_navigator/ui/styling.dart';

const scenarioPath =
    '/data/user/0/com.example.campus_navigator/files/campus-identity-preview.json';
const readinessPath =
    '/data/user/0/com.example.campus_navigator/files/campus-identity-ready.json';
void main() => runApp(const IdentityPreview());

ThemeData identityTheme(bool dark) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff173657),
    brightness: dark ? Brightness.dark : Brightness.light,
  ).copyWith(
    primary: Color(dark ? 0xffa6c9eb : 0xff173657),
    onPrimary: Color(dark ? 0xff102b45 : 0xffffffff),
    primaryContainer: Color(dark ? 0xff233e55 : 0xffe3ecf3),
    onPrimaryContainer: Color(dark ? 0xffd9e9f6 : 0xff173657),
    secondary: Color(dark ? 0xffa4bed0 : 0xff527d9b),
    surface: Color(dark ? 0xff151a20 : 0xfff5f7f8),
    surfaceContainer: Color(dark ? 0xff20272f : 0xffedf1f4),
    surfaceContainerLow: Color(dark ? 0xff1b222a : 0xffffffff),
    surfaceContainerHighest: Color(dark ? 0xff29323c : 0xffe4eaf0),
    onSurface: Color(dark ? 0xffe5ebf0 : 0xff263442),
    onSurfaceVariant: Color(dark ? 0xffb0bdc9 : 0xff526372),
    outline: Color(dark ? 0xff7c8b99 : 0xff71808e),
    outlineVariant: Color(dark ? 0xff37434f : 0xffd1dae2),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
          color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w600),
    ),
    dividerTheme:
        DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
    iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48))),
    textTheme: const TextTheme(
      titleMedium:
          TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.25),
      titleSmall:
          TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      bodySmall: TextStyle(fontSize: 12, height: 1.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outline)),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    )),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    )),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primaryContainer,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
    ),
  );
}

class IdentityPreview extends StatefulWidget {
  const IdentityPreview({super.key});
  @override
  State<IdentityPreview> createState() => _IdentityPreviewState();
}

class _IdentityPreviewState extends State<IdentityPreview> {
  Timer? _timer;
  String _last = '';
  bool _reading = false;
  Map<String, dynamic> _config = {
    'variant': 'a',
    'scene': 'hub',
    'dark': false
  };
  final _catalog = CampusCatalog();
  Future<BuildingPageData>? _floor;
  @override
  void initState() {
    super.initState();
    _catalog.addListener(_catalogChanged);
    _catalog.load();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) => _read());
    _read();
  }

  void _catalogChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _read() async {
    if (_reading) return;
    _reading = true;
    try {
      final file = File(scenarioPath);
      if (!await file.exists()) return;
      final body = await file.readAsString();
      if (body == _last) return;
      final next = jsonDecode(body) as Map<String, dynamic>;
      if (next['scene'] == 'floor') {
        _floor ??= BuildingPageData.fetchQuery('bey/03/raum/111103.5220');
      }
      if (mounted) {
        setState(() {
          _config = next;
          _last = body;
        });
      }
    } catch (error) {
      debugPrint('IDENTITY_CONFIG: $error');
    } finally {
      _reading = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _catalog.removeListener(_catalogChanged);
    _catalog.dispose();
    _floor?.then((data) => data.backgroundImageData?.dispose(),
        onError: (_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = _config['dark'] == true;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: identityTheme(dark),
      home: StudyScene(
        key: ValueKey(_last),
        wayfinding: _config['variant'] == 'b',
        dark: dark,
        scene: _config['scene'] as String? ?? 'hub',
        catalog: _catalog,
        floor: _floor,
      ),
    );
  }
}

class StudyScene extends StatefulWidget {
  final bool wayfinding, dark;
  final String scene;
  final CampusCatalog catalog;
  final Future<BuildingPageData>? floor;
  const StudyScene(
      {super.key,
      required this.wayfinding,
      required this.dark,
      required this.scene,
      required this.catalog,
      this.floor});
  @override
  State<StudyScene> createState() => _StudySceneState();
}

class _StudySceneState extends State<StudyScene> {
  late String _scene = widget.scene;
  final _map = MapController();
  late final CampusTileProvider _tiles;
  final _paintedTiles = <TileImage>{};
  Timer? _readinessTimer;
  bool _writingReadiness = false, _tileFailure = false;
  BuildingPageData? _readyFloor;
  DateTime? _rasterChangedAt;
  int? _lastRasterStep;
  final _search = TextEditingController();
  final _sheet = DraggableScrollableController();
  ColorScheme get colors => Theme.of(context).colorScheme;
  bool get wide => MediaQuery.sizeOf(context).width >= 840;
  @override
  void initState() {
    super.initState();
    _tiles = CampusTileProvider(onFailure: () => _tileFailure = true);
    _readinessTimer = Timer.periodic(
        const Duration(milliseconds: 300), (_) => _writeReadiness());
    widget.floor?.then((data) async {
      await data.backgroundImageData?.loaded;
      if (mounted) _readyFloor = data;
    }, onError: (_) {});
    if (_scene == 'results') _search.text = 'BEY 318';
  }

  @override
  void dispose() {
    _readinessTimer?.cancel();
    _map.dispose();
    _search.dispose();
    _sheet.dispose();
    super.dispose();
  }

  Future<void> _writeReadiness() async {
    if (!mounted || _writingReadiness) return;
    _writingReadiness = true;
    try {
      // Readiness describes a rendered frame, not just the requested JSON.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final view = MediaQuery.sizeOf(context);
      final images = _readyFloor?.backgroundImageData;
      if (images != null && _lastRasterStep != images.qualiStep) {
        _lastRasterStep = images.qualiStep;
        _rasterChangedAt = DateTime.now();
      }
      var ready = true;
      if (_scene == 'map') {
        ready = selected != null &&
            !widget.catalog.busy &&
            !_tileFailure &&
            _paintedTiles.isNotEmpty &&
            _paintedTiles.every((tile) =>
                tile.loadFinishedAt != null &&
                !tile.loadError &&
                tile.readyToDisplay);
      } else if (_scene == 'floor') {
        ready = images != null &&
            images.failedImages == 0 &&
            _rasterChangedAt != null &&
            DateTime.now().difference(_rasterChangedAt!).inMilliseconds >= 1500;
      }
      final status = <String, dynamic>{
        'variant': widget.wayfinding ? 'b' : 'a',
        'scene': _scene,
        'dark': widget.dark,
        'ready': ready,
        'widthDp': view.width,
        'rasterStep': _scene == 'floor' ? images?.qualiStep : null,
      };
      if (_scene == 'map' && ready) {
        status.addAll({
          'latitude': _map.camera.center.latitude,
          'longitude': _map.camera.center.longitude,
          'zoom': _map.camera.zoom
        });
      }
      final temporary = File('$readinessPath.tmp');
      await temporary.writeAsString(jsonEncode(status));
      if (mounted) await temporary.rename(readinessPath);
    } catch (error) {
      debugPrint('IDENTITY_READINESS: $error');
    } finally {
      _writingReadiness = false;
    }
  }

  Widget code(String label, IconData icon) => widget.wayfinding
      ? Container(
          width: 48,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(4)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.onPrimaryContainer)),
        )
      : SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: colors.onSurfaceVariant));
  Widget row(String building, String room, String name, String detail,
      {bool favorite = true, bool isBuilding = false}) {
    final title = isBuilding
        ? name
        : widget.wayfinding
            ? 'Raum $room'
            : '$building $room';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 12,
      leading: code(building,
          isBuilding ? Icons.business_outlined : Icons.meeting_room_outlined),
      title: Text(title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(isBuilding ? '$building · Gebäude' : '$name · $detail',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
      trailing: IconButton(
          tooltip: favorite ? 'Favorit entfernen' : 'Als Favorit speichern',
          color: favorite ? colors.primary : colors.onSurfaceVariant,
          onPressed: () {},
          icon:
              Icon(favorite ? Icons.star_rounded : Icons.star_outline_rounded)),
      onTap: () {},
    );
  }

  Widget heading(String title, {String? action}) => SizedBox(
        height: 48,
        child: Row(children: [
          if (widget.wayfinding)
            Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                color: colors.primary),
          Expanded(
              child:
                  Text(title, style: Theme.of(context).textTheme.titleSmall)),
          if (action != null) TextButton(onPressed: () {}, child: Text(action)),
        ]),
      );
  Widget searchField({bool map = false}) => TextField(
        controller: _search,
        autocorrect: false,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: map ? 'Gebäude suchen' : 'Gebäude oder Raum suchen',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Suche leeren',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _search.clear();
                    setState(() => _scene = map ? 'map' : 'hub');
                  }),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          FocusScope.of(context).unfocus();
          if (!map) setState(() => _scene = 'results');
        },
      );
  Widget _favorites() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading('Favoriten'),
        row('APB', 'E069', 'Andreas-Pfitzmann-Bau', 'Etage 00'),
        const Divider(),
        row('BEY', '', 'Beyer-Bau', '', isBuilding: true),
        const Divider(),
        row('BEY', '318', 'Beyer-Bau', 'Etage 03'),
      ]);
  Widget _recent() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading('Zuletzt aufgerufen', action: 'Leeren'),
        row('APB', 'E069', 'Andreas-Pfitzmann-Bau', 'Etage 00'),
        const Divider(),
        row('BEY', '318', 'Beyer-Bau', 'Etage 03'),
        const Divider(),
        row('BAR', '218', 'Barkhausen-Bau', 'Etage 01', favorite: false),
      ]);
  Widget hub() => Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: searchField()),
          Expanded(
              child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _scene == 'results'
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        heading('Räume'),
                        row('BEY', '318', 'Beyer-Bau', 'Etage 03'),
                        const Divider(),
                        heading('Gebäude'),
                        row('BEY', '', 'Beyer-Bau', '', isBuilding: true),
                      ])
                : LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth >= 680
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Expanded(child: _favorites()),
                                    const SizedBox(width: 32),
                                    Expanded(child: _recent()),
                                  ])
                            : Column(children: [
                                _favorites(),
                                const SizedBox(height: 16),
                                const Divider(),
                                _recent()
                              ]),
                  ),
          )),
        ]),
      ));
  CampusFeature? get selected {
    for (final building in widget.catalog.buildings) {
      if (building.code == 'APB') return building;
    }
    return null;
  }

  Widget buildingInfo() => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            code('APB', Icons.business_outlined),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(selected?.name ?? 'Andreas-Pfitzmann-Bau',
                      style: Theme.of(context).textTheme.titleMedium),
                  if (!widget.wayfinding)
                    Text('APB',
                        style: TextStyle(
                            fontSize: 13, color: colors.onSurfaceVariant)),
                ])),
            IconButton(
                tooltip: 'Gebäudeauswahl schließen',
                onPressed: () {},
                icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 8),
          Text(selected?.address ?? 'Gebäudekatalog wird geladen …',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.layers_outlined, size: 18),
                label: const Text('Etagen anzeigen')),
            OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.navigation_outlined, size: 18),
                label: const Text('Navigieren')),
          ]),
          const SizedBox(height: 8),
          Text('Ziel: Gebäudepunkt · Eingang nicht bestätigt',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        ],
      ));
  Widget mapTool(String label, IconData icon, VoidCallback action) =>
      IconButton(tooltip: label, onPressed: action, icon: Icon(icon));
  Widget mapCanvas() => Stack(children: [
        Positioned.fill(
            child: FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter:
                      selected?.mapPoint ?? const LatLng(51.0282, 13.7267),
                  initialZoom: 16.7,
                  minZoom: 5,
                  maxZoom: 20,
                  interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                ),
                children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                tileProvider: _tiles,
                userAgentPackageName: 'com.example.campus_navigator',
                maxNativeZoom: 19,
                panBuffer: 0,
                keepBuffer: 2,
                retinaMode: MediaQuery.devicePixelRatioOf(context) > 1,
                tileBuilder: (context, image, tile) {
                  _paintedTiles.add(tile);
                  return widget.dark
                      ? ColorFiltered(
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
                      : image;
                },
              ),
              PolygonLayer(polygons: [
                for (final b in widget.catalog.buildings)
                  for (final ring in b.outlines)
                    Polygon(
                      points: ring,
                      color: colors.primary
                          .withOpacity(b.code == 'APB' ? .22 : .05),
                      borderColor:
                          colors.primary.withOpacity(b.code == 'APB' ? 1 : .5),
                      borderStrokeWidth: b.code == 'APB' ? 2 : 1,
                      label:
                          widget.wayfinding || b.code == 'APB' ? b.code : null,
                      labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.primary),
                    ),
              ], drawLabelsLast: true, simplificationTolerance: 0),
            ])),
        Positioned(left: 12, top: 12, right: 12, child: searchField(map: true)),
        Positioned(
            right: 12,
            top: 84,
            child: Material(
              color: colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colors.outlineVariant)),
              child: Column(children: [
                mapTool('Zum Campus', Icons.school_outlined,
                    () => _map.move(const LatLng(51.0282, 13.7267), 16)),
                mapTool('Eigene Position', Icons.my_location, () {}),
                mapTool(
                    'Vergrößern',
                    Icons.add,
                    () => _map.move(_map.camera.center,
                        (_map.camera.zoom + 1).clamp(5, 20))),
                mapTool(
                    'Verkleinern',
                    Icons.remove,
                    () => _map.move(_map.camera.center,
                        (_map.camera.zoom - 1).clamp(5, 20))),
              ]),
            )),
        Positioned(
          left: 0,
          bottom: 0,
          child: Material(
              color: colors.surfaceContainerLow,
              child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text('© OpenStreetMap · Gebäude: TU Dresden',
                      style: TextStyle(fontSize: 11)))),
        ),
      ]);
  Widget campusMap() => selected == null
      ? const Center(child: CircularProgressIndicator())
      : wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: mapCanvas()),
              const VerticalDivider(width: 1),
              SizedBox(
                  width: 328,
                  child: SingleChildScrollView(child: buildingInfo()))
            ])
          : Column(children: [
              Expanded(child: mapCanvas()),
              const Divider(),
              buildingInfo()
            ]);
  Widget roomInfo() => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading('Rauminformationen'),
          Text('BEY 318', style: Theme.of(context).textTheme.titleMedium),
          Text('Beyer-Bau · Etage 03',
              style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text('Adresse', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          const Text('Beyer-Bau\nGeorge-Bähr-Straße 1\n01069 Dresden'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Navigieren')),
          const SizedBox(height: 16),
          Text('Weitere Aktionen',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Raumbelegung')),
        ],
      ));
  Widget floorCanvas(BuildingPageData data) => Theme(
        // Keep the established floor drawing palette, transformations and gestures.
        data: AppTheme.themeData(
            widget.dark ? AppTheme.darkColorScheme : AppTheme.lightColorScheme),
        child: FloorView(data: data),
      );
  Widget floorHeader() => Material(
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.layers_outlined, size: 18),
              label: const Text('Etage 03'),
              style: OutlinedButton.styleFrom(side: BorderSide.none)),
          const Icon(Icons.keyboard_arrow_down, size: 18),
          const Spacer(),
          TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list, size: 20),
              label: const Text('Raumfilter'),
              style: TextButton.styleFrom(minimumSize: const Size(0, 48))),
        ]),
      ));
  Widget floor() => Column(children: [
        floorHeader(),
        const Divider(),
        Expanded(
            child: FutureBuilder<BuildingPageData>(
          future: widget.floor,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Grundriss nicht verfügbar: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (wide) {
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: floorCanvas(snapshot.data!)),
                    const VerticalDivider(width: 1),
                    SizedBox(
                        width: 300,
                        child: SingleChildScrollView(child: roomInfo()))
                  ]);
            }
            return LayoutBuilder(builder: (context, constraints) {
              final collapsed = (72 / constraints.maxHeight).clamp(.05, .4);
              return Stack(children: [
                Positioned.fill(bottom: 72, child: floorCanvas(snapshot.data!)),
                DraggableScrollableSheet(
                  controller: _sheet,
                  initialChildSize: collapsed,
                  minChildSize: collapsed,
                  maxChildSize: .8,
                  snap: true,
                  snapSizes: [collapsed, .55, .8],
                  builder: (context, controller) => Material(
                    color: colors.surfaceContainerLow,
                    shape:
                        Border(top: BorderSide(color: colors.outlineVariant)),
                    child: ListView(
                        controller: controller,
                        padding: EdgeInsets.zero,
                        children: [
                          Center(
                              child: Container(
                                  width: 32,
                                  height: 4,
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                      color: colors.outline,
                                      borderRadius: BorderRadius.circular(2)))),
                          ListTile(
                              dense: true,
                              onTap: () => _sheet.animateTo(
                                  _sheet.size < .3 ? .55 : collapsed,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut),
                              leading: code('BEY', Icons.meeting_room_outlined),
                              title: Text(
                                  widget.wayfinding ? 'Raum 318' : 'BEY 318',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              subtitle: const Text('Beyer-Bau · Etage 03'),
                              trailing: const Icon(Icons.keyboard_arrow_up)),
                          roomInfo(),
                        ]),
                  ),
                ),
              ]);
            });
          },
        ))
      ]);
  @override
  Widget build(BuildContext context) {
    final onFloor = _scene == 'floor', onMap = _scene == 'map';
    final content = onFloor
        ? floor()
        : onMap
            ? campusMap()
            : hub();
    return Scaffold(
      appBar: AppBar(
        leading: onFloor
            ? IconButton(
                tooltip: 'Zurück',
                onPressed: () => setState(() => _scene = 'hub'),
                icon: const Icon(Icons.arrow_back))
            : null,
        title: onFloor
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.wayfinding ? 'BEY · Raum 318' : 'BEY 318'),
                Text('Beyer-Bau',
                    style: TextStyle(
                        fontSize: 12, color: colors.onSurfaceVariant)),
              ])
            : Text(onMap ? 'Campuskarte' : 'Campus Navigator'),
        actions: onFloor
            ? [
                IconButton(
                    tooltip: 'Favorit entfernen',
                    onPressed: () {},
                    color: colors.primary,
                    icon: const Icon(Icons.star_rounded)),
                IconButton(
                    tooltip: 'Raum teilen',
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined)),
              ]
            : onMap
                ? []
                : [
                    IconButton(
                        tooltip: 'Freiraumsuche',
                        onPressed: () {},
                        icon: const Icon(Icons.meeting_room_outlined)),
                    IconButton(
                        tooltip: 'Einstellungen',
                        onPressed: () {},
                        icon: const Icon(Icons.settings_outlined)),
                  ],
      ),
      body: SafeArea(
          child: wide && !onFloor
              ? Row(children: [
                  NavigationRail(
                      selectedIndex: onMap ? 1 : 0,
                      labelType: NavigationRailLabelType.all,
                      onDestinationSelected: (index) =>
                          setState(() => _scene = index == 0 ? 'hub' : 'map'),
                      destinations: const [
                        NavigationRailDestination(
                            icon: Icon(Icons.search), label: Text('Suche')),
                        NavigationRailDestination(
                            icon: Icon(Icons.map_outlined),
                            label: Text('Campus')),
                      ]),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ])
              : content),
      bottomNavigationBar: wide || onFloor
          ? null
          : NavigationBar(
              selectedIndex: onMap ? 1 : 0,
              onDestinationSelected: (index) =>
                  setState(() => _scene = index == 0 ? 'hub' : 'map'),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.search), label: 'Raumsuche'),
                NavigationDestination(
                    icon: Icon(Icons.map_outlined), label: 'Campuskarte'),
              ],
            ),
    );
  }
}
