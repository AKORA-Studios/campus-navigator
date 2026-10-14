// Emulator-only QA entry point. Original TU fixtures stay outside app assets.
// Serve data/renderer-fixtures on 127.0.0.1:8765, control with scenario.json.
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/building/page_image_data.dart';
import 'package:campus_navigator/ui/components/painter.dart';
import 'package:campus_navigator/ui/styling.dart';
import 'akora_painter.dart' as akora;
import 'baseline_painter.dart' as baseline;

const host = 'http://10.0.2.2:8765';
void main() {
  APIServices.Shared = APIServices.withoutCache();
  APIServices.Shared.client = FixtureClient();
  APIServices.Shared.storage.filterSet = layerFilterOptions.values.toSet();
  runApp(const Preview());
}

class Preview extends StatefulWidget {
  const Preview({super.key});
  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  final transform = TransformationController();
  final paintTransform = ValueNotifier<Matrix4>(Matrix4.identity());
  final frameTimings = <ui.FrameTiming>[];
  bool benchmarking = false;
  String? lastBenchmark;
  Timer? timer;
  BuildingPageData? floor;
  Map<String, dynamic> config = {};
  String lastConfig = '';
  String message = 'Waiting for scenario.json';
  bool busy = false;
  bool positioned = false;
  @override
  void initState() {
    super.initState();
    transform.addListener(updatePaintScale);
    WidgetsBinding.instance.addTimingsCallback(recordTimings);
    timer = Timer.periodic(const Duration(milliseconds: 500), (_) => refresh());
    refresh();
  }

  void updatePaintScale() {
    if (paintTransform.value.getMaxScaleOnAxis() !=
        transform.value.getMaxScaleOnAxis()) {
      paintTransform.value = transform.value.clone();
    }
  }

  void recordTimings(List<ui.FrameTiming> values) {
    if (benchmarking) frameTimings.addAll(values);
  }

  Future<void> benchmark(String kind) async {
    final original = transform.value.clone();
    frameTimings.clear();
    benchmarking = true;
    for (var frame = 0; frame < 240 && mounted; frame++) {
      final phase = frame / 240 * pi * 4;
      transform.value = original.clone()
        ..translate(sin(phase) * 25, cos(phase) * 15)
        ..scale(kind == 'zoom' ? 1 + .15 * sin(phase) : 1.0);
      await WidgetsBinding.instance.endOfFrame;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    benchmarking = false;
    transform.value = original;
    final timings = frameTimings.skip(20).toList();
    Map<String, dynamic> stats(List<double> values) {
      values.sort();
      if (values.isEmpty) return {'frames': 0};
      return {
        'median_ms': values[values.length ~/ 2],
        'p95_ms': values[(values.length * .95).floor()],
        'over_16_7_ms': values.where((v) => v > 16.7).length,
      };
    }

    final images = floor!.backgroundImageData!;
    debugPrint('RENDER_BENCH ${jsonEncode({
          'kind': kind,
          'baseline': config['baseline'] == true,
          'floor': config['floor'],
          'frames': timings.length,
          'tile_step': images.qualiStep,
          'decoded_mib': images.imageMap.values.fold<int>(
                  0, (sum, image) => sum + image.width * image.height * 4) /
              (1024 * 1024),
          'build': stats(timings
              .map((t) => t.buildDuration.inMicroseconds / 1000)
              .toList()),
          'raster': stats(timings
              .map((t) => t.rasterDuration.inMicroseconds / 1000)
              .toList()),
        })}');
  }

  Future<void> refresh() async {
    if (busy) return;
    busy = true;
    try {
      final response = await http.get(Uri.parse('$host/scenario.json'));
      if (response.body == lastConfig) return;
      final next = jsonDecode(response.body) as Map<String, dynamic>;
      if (next['floor'] != config['floor'] ||
          next['room'] != config['room'] ||
          next['legacy'] != config['legacy'] ||
          next['baseline'] != config['baseline']) {
        final old = floor;
        setState(() {
          floor = null;
          message = 'Loading original tiles';
        });
        await WidgetsBinding.instance.endOfFrame;
        old?.backgroundImageData?.dispose();
        final name = next['floor'] as String;
        final parts = [name.substring(0, 3), name.substring(3)];
        if (next['room'] != null) {
          parts.addAll(['raum', next['room'] as String]);
        }
        final body = await http.get(Uri.parse('$host/$name.html'));
        final data = BuildingPageData.fromHTMLText(body.body, parts);
        final images = PageImageData.fetchLevelImages(
            data.pngFileName, data.layers, data.subpics,
            adaptive: next['legacy'] != true && next['baseline'] != true);
        await images.loaded;
        data.backgroundImageData = images;
        floor = data;
      }
      if (next['legacy'] != true && next['baseline'] != true) {
        final view = WidgetsBinding.instance.platformDispatcher.views.first;
        final size = view.physicalSize / view.devicePixelRatio;
        final bounds = planBounds(floor!);
        final fit =
            min(size.width / bounds.width, (size.height - 104) / bounds.height);
        final zoom = next['view'] == 'fit'
            ? 1.0
            : (next['zoom'] as num? ?? 3).toDouble();
        await floor!.backgroundImageData!.setResolutionForScale(
            fit * zoom * sqrt(view.devicePixelRatio.clamp(1.0, 4.0)));
      }
      setState(() {
        config = next;
        lastConfig = response.body;
        positioned = false;
        message =
            '${next['floor']} ${next['view']} ${next['dark'] == true ? 'dark' : 'light'} ${next['legacy'] == true ? 'AKORA' : 'renderer'}';
      });
    } catch (error) {
      setState(() => message = 'ERROR: $error');
    } finally {
      busy = false;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeTimingsCallback(recordTimings);
    transform.removeListener(updatePaintScale);
    transform.dispose();
    paintTransform.dispose();
    floor?.backgroundImageData?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData(config['dark'] == true
            ? AppTheme.darkColorScheme
            : AppTheme.lightColorScheme),
        home: Scaffold(
          appBar: AppBar(
              title: Text(message, style: const TextStyle(fontSize: 14))),
          body: floor == null
              ? Center(child: Text(message))
              : LayoutBuilder(builder: (context, constraints) {
                  final data = floor!;
                  final size = constraints.biggest;
                  if (!positioned) {
                    positioned = true;
                    final bounds = planBounds(data);
                    final fit = min(
                        size.width / bounds.width, size.height / bounds.height);
                    final center = config['view'] == 'fit' ||
                            data.selectedRoom == null
                        ? Offset.zero
                        : polygonPath(data.selectedRoom!.polygon.points.single)
                            .getBounds()
                            .center;
                    final zoom = config['view'] == 'fit'
                        ? 1.0
                        : (config['zoom'] as num? ?? 3).toDouble();
                    final point = Offset((size.width - bounds.width * fit) / 2,
                            (size.height - bounds.height * fit) / 2) +
                        (center - bounds.topLeft) * fit;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      transform.value = Matrix4.identity()
                        ..translate(size.width / 2 - point.dx * zoom,
                            size.height / 2 - point.dy * zoom)
                        ..scale(zoom);
                      final kind = config['benchmark'] as String?;
                      final key =
                          '${config['baseline']}:$kind:${config['run']}';
                      if (kind != null &&
                          key != lastBenchmark &&
                          !benchmarking) {
                        lastBenchmark = key;
                        benchmark(kind);
                      }
                    });
                  }
                  return ClipRect(
                      child: InteractiveViewer(
                    transformationController: transform,
                    minScale: 0.8,
                    maxScale: 16,
                    boundaryMargin: const EdgeInsets.all(300),
                    child: RepaintBoundary(
                        child: CustomPaint(
                      size: size,
                      painter: config['legacy'] == true
                          ? AlignedAkoraPainter(
                              roomResult: data, context: context)
                          : config['baseline'] == true
                              ? baseline.BaselineMapPainter(
                                  roomResult: data, context: context)
                              : MapPainter(
                                  roomResult: data,
                                  context: context,
                                  transformation: paintTransform),
                    )),
                  ));
                }),
        ),
      );
}

// Run the production tile loader against the frozen original HTTP responses.
class FixtureClient extends http.BaseClient {
  final _client = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final parts = request.url.pathSegments;
    final filename =
        parts.contains('etplan_cache') ? '${parts[2]}_${parts[3]}' : parts.last;
    return _client.send(http.Request('GET', Uri.parse('$host/$filename')));
  }

  @override
  void close() => _client.close();
}

// Compare the original drawing logic in the same coordinate extent/camera.
// Only fit bounds differ from AKORA; no paint/filter/label logic is changed.
class AlignedAkoraPainter extends akora.AkoraMapPainter {
  AlignedAkoraPainter({required super.roomResult, required super.context});
  @override
  Rect calculateDrawingArea() => planBounds(roomResult);
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = calculateDrawingArea();
    final fit = min(size.width / bounds.width, size.height / bounds.height);
    canvas.save();
    canvas.translate((size.width - bounds.width * fit) / 2,
        (size.height - bounds.height * fit) / 2);
    super.paint(canvas, size);
    canvas.restore();
  }
}
