import 'dart:async';
import 'dart:ui' as ui;
import 'package:campus_navigator/api/campus/campus_tiles.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

class ControlledTileCache extends Fake implements BaseCacheManager {
  final pending = Completer<File>();
  @override
  Future<File> getSingleFile(String url,
          {String? key, Map<String, String>? headers}) =>
      pending.future;
}

void main() {
  testWidgets('a cancelled pending tile cannot blank its same-URL replacement',
      (tester) async {
    await tester.runAsync(() async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder)
          .drawColor(const ui.Color(0xff1769d2), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final pixel = await picture.toImage(1, 1);
      final png = (await pixel.toByteData(format: ui.ImageByteFormat.png))!;
      final file = MemoryFileSystem().file('/tile.png')
        ..writeAsBytesSync(
            png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes));
      pixel.dispose();
      picture.dispose();
      final cache = ControlledTileCache();
      final provider = CampusTileProvider(
          cache: cache, onFailure: () => fail('Unexpected tile failure'));
      final options = TileLayer(
          urlTemplate: 'https://tiles.invalid/{z}/{x}/{y}.png',
          tileProvider: provider);
      final oldCancellation = Completer<void>();
      final newCancellation = Completer<void>();
      const coordinate = TileCoordinates(1, 1, 2);
      final oldFrame = Completer<ImageInfo>();
      final newFrame = Completer<ImageInfo>();
      final oldStream = provider
          .getImageWithCancelLoadingSupport(
              coordinate, options, oldCancellation.future)
          .resolve(ImageConfiguration.empty);
      final oldListener = ImageStreamListener(
          (info, _) => oldFrame.complete(info),
          onError: oldFrame.completeError);
      oldStream.addListener(oldListener);
      await Future<void>.delayed(Duration.zero);
      oldCancellation.complete();
      await Future<void>.delayed(Duration.zero);
      final newStream = provider
          .getImageWithCancelLoadingSupport(
              coordinate, options, newCancellation.future)
          .resolve(ImageConfiguration.empty);
      final newListener = ImageStreamListener(
          (info, _) => newFrame.complete(info),
          onError: newFrame.completeError);
      newStream.addListener(newListener);
      cache.pending.complete(file);
      final oldInfo = await oldFrame.future.timeout(const Duration(seconds: 3));
      final newInfo = await newFrame.future.timeout(const Duration(seconds: 3));
      final rgba =
          (await newInfo.image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      oldStream.removeListener(oldListener);
      newStream.removeListener(newListener);
      oldInfo.dispose();
      newInfo.dispose();
      newCancellation.complete();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      expect(rgba.getUint8(3), 255,
          reason:
              'A new visible tile must receive real pixels, not the cancelled placeholder.');
    });
  });
}
