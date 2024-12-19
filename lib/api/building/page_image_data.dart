import 'dart:async';
import 'dart:ui' as ui;

import 'package:campus_navigator/api/building/parsing/common.dart';

import 'parsing/common.dart' as common;
import 'parsing/layer_data.dart';

class PageImageData {
  final int qualiStep;
  final Map<String, ui.Image> backgroundImages;

  PageImageData({
    required this.qualiStep,
    required this.backgroundImages,
  });

  ui.Image? getLayerSymbol(String symbolName) {
    return backgroundImages[symbolName];
  }

  ui.Image? getBackgroundImage(int x, int y) {
    return backgroundImages["${x}_$y"];
  }

  /// Fetches all images for a floor plan given the `pngFileName` of
  /// the current page and all it's layers(needed for fetching of the symbolds)
  static Future<PageImageData> fetchLevelImages(
      String pngFileName, List<LayerData> layers,
      {int qualiIndex = 3}) async {
    final List<int> qualiSteps = [1, 2, 4, 8];
    final int qualiStep = qualiSteps[qualiIndex];

    // Prepare buffer, this is to avoid concurrency bugs during fetching
    List<Future<(String, ui.Image?)>> imageBuffer = [];

    // Background tiles
    for (int x = 0; x < qualiStep; x++) {
      for (int y = 0; y < qualiStep; y++) {
        final uri = Uri.parse(
            "$baseURL/images/etplan_cache/${pngFileName}_$qualiStep/${x}_$y.png/nobase64");

        final imageFuture =
            common.fetchImage(uri).then((image) => ("${x}_$y", image));

        imageBuffer.add(imageFuture);
      }
    }

    // Layer symbols
    for (final layer in layers) {
      final imageFuture = common
          .fetchImage(layer.getSymbolUri())
          .then((image) => (layer.symbolPNG, image));

      imageBuffer.add(imageFuture);
    }

    var imageList = await Future.wait(imageBuffer);

    Map<String, ui.Image> imageMap = {};
    for (final e in imageList) {
      if (e.$2 == null) continue;
      imageMap[e.$1] = e.$2!;
    }

    return PageImageData(backgroundImages: imageMap, qualiStep: qualiStep);
  }
}
