import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/networking.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'parsing/layer_data.dart';

class PageImageData with ChangeNotifier {
  final Map<String, ui.Image> imageMap;
  int qualiStep;
  int height = 0;
  int width = 0;
  int failedImages = 0;
  bool _disposed = false;
  Future<void> loaded = Future.value();
  String? _pngFileName;
  List<({int h, int v})> _subpics = [];
  int _maxIndex = 0;
  int _desiredIndex = 0;
  int _revision = 0;
  Future<void>? _updating;
  final _retired = <ui.Image>{};
  int _failedSymbols = 0;

  PageImageData({required this.qualiStep, required this.imageMap});

  ui.Image? getLayerSymbol(String name) => imageMap[name];
  ui.Image? getBackgroundImage(int x, int y) => imageMap['${x}_$y'];

  PageImageData.fetchLevelImages(String pngFileName, List<LayerData> layers,
      List<({int h, int v})> subpics,
      {int qualiIndex = 3, bool adaptive = false})
      : qualiStep = adaptive ? 1 : [1, 2, 4, 8][qualiIndex],
        imageMap = {} {
    if (adaptive) {
      _pngFileName = pngFileName;
      _subpics = subpics;
      _maxIndex = qualiIndex;
    }
    final initialIndex = adaptive ? 0 : qualiIndex;
    width = subpics[initialIndex].h;
    height = subpics[initialIndex].v;
    final tasks = _tileTasks(pngFileName, qualiStep, width, height);
    for (final layer in layers.where((l) => l.symbol.isNotEmpty)) {
      tasks[layer.symbolPNG] = layer.getSymbolUri();
    }
    loaded =
        _load(tasks.entries.toList(), imageMap, progress: true).then((failed) {
      if (_disposed) return;
      failedImages = failed;
      notifyListeners();
    });
  }

  static Map<String, Uri> _tileTasks(String name, int step, int w, int h) => {
        for (var x = 0; x < w; x++)
          for (var y = 0; y < h; y++)
            '${x}_$y': Uri.parse(
                '$baseURL/images/etplan_cache/${name}_$step/${x}_$y.png/nobase64')
      };

  /// Closest native raster scale avoids reducing single-pixel server strokes
  /// by a factor of eight. The user's quality setting remains the upper limit.
  // The caller balances logical scale and density. Server strokes have a
  // fixed raster pixel width: using the full physical scale makes them faint,
  // while ignoring density merges small symbols on dense phone screens.
  Future<void> setResolutionForScale(double rasterPixelsPerPlanUnit) {
    if (_disposed ||
        _pngFileName == null ||
        !rasterPixelsPerPlanUnit.isFinite ||
        rasterPixelsPerPlanUnit <= 0) {
      return Future.value();
    }
    var index = 0;
    for (var candidate = 1; candidate <= _maxIndex; candidate++) {
      if (((1 << candidate) - rasterPixelsPerPlanUnit).abs() <
          ((1 << index) - rasterPixelsPerPlanUnit).abs()) {
        index = candidate;
      }
    }
    if (index != _desiredIndex) {
      _desiredIndex = index;
      _revision++;
    }
    return _updating ??=
        _updateResolution().whenComplete(() => _updating = null);
  }

  Future<void> _updateResolution() async {
    await loaded;
    while (!_disposed && qualiStep != 1 << _desiredIndex) {
      final revision = _revision;
      final index = _desiredIndex;
      final step = 1 << index;
      final dimensions = _subpics[index];
      final nextImages = <String, ui.Image>{};
      final failed = await _load(
          _tileTasks(_pngFileName!, step, dimensions.h, dimensions.v)
              .entries
              .toList(),
          nextImages,
          revision: revision);
      if (_disposed || revision != _revision || failed > 0) {
        for (final image in nextImages.values) {
          image.dispose();
        }
        if (_disposed) return;
        if (revision != _revision) continue;
        // Keep the complete previous raster instead of publishing a broken one.
        failedImages = failed + _failedSymbols;
        notifyListeners();
        return;
      }
      final tileKeys = imageMap.keys
          .where((key) => RegExp(r'^\d+_\d+$').hasMatch(key))
          .toList();
      for (final key in tileKeys) {
        _retired.add(imageMap.remove(key)!);
      }
      imageMap.addAll(nextImages);
      qualiStep = step;
      width = dimensions.h;
      height = dimensions.v;
      failedImages = _failedSymbols;
      notifyListeners();
      // Recorded pictures from the preceding frame may still refer to images.
      final retired = _retired.toList();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        for (final image in retired) {
          if (_retired.remove(image)) image.dispose();
        }
      });
      SchedulerBinding.instance.ensureVisualUpdate();
    }
  }

  Future<int> _load(
      List<MapEntry<String, Uri>> tasks, Map<String, ui.Image> destination,
      {bool progress = false, int? revision}) async {
    var next = 0;
    var failed = 0;
    Future<void> worker() async {
      while (!_disposed &&
          (revision == null || revision == _revision) &&
          next < tasks.length) {
        final task = tasks[next++];
        ui.Image? image;
        var emptyTile = false;
        try {
          final result = await APIServices.Shared.fetchImageResult(task.value);
          image = result.image;
          emptyTile = result.empty && RegExp(r'^\d+_\d+$').hasMatch(task.key);
        } catch (_) {
          // A missing tile must not break the other workers or leak an error.
        }
        if (_disposed || (revision != null && revision != _revision)) {
          image?.dispose();
          return;
        }
        if (image == null && !emptyTile) {
          failed++;
          if (progress && !RegExp(r'^\d+_\d+$').hasMatch(task.key)) {
            _failedSymbols++;
          }
        } else if (image != null) {
          destination[task.key] = image;
        }
        if (progress) {
          failedImages = failed;
          notifyListeners();
        }
      }
    }

    // Bound downloads/decode work per floor; switching disposes old loaders.
    await Future.wait(List.generate(min(4, tasks.length), (_) => worker()));
    return failed;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final image in imageMap.values) {
      image.dispose();
    }
    imageMap.clear();
    for (final image in _retired) {
      image.dispose();
    }
    _retired.clear();
    super.dispose();
  }
}
