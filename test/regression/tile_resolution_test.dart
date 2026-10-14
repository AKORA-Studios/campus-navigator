import 'dart:async';
import 'dart:ui' as ui;
import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/building/page_image_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<int> png;
  setUp(() async {
    APIServices.Shared = APIServices.withoutCache();
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.black, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(2, 2);
    png = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    image.dispose();
    picture.dispose();
  });
  const grids = [(h: 1, v: 1), (h: 2, v: 1), (h: 4, v: 1), (h: 8, v: 1)];

  test('resolution switch retains the complete old plan until all tiles arrive',
      () async {
    final requests = <Completer<http.Response>>[];
    APIServices.Shared.client = MockClient((request) {
      if (request.url.path.contains('TEST_1/')) {
        return Future.value(http.Response.bytes(png, 200));
      }
      final response = Completer<http.Response>();
      requests.add(response);
      return response.future;
    });
    final images =
        PageImageData.fetchLevelImages('TEST', [], grids, adaptive: true);
    await images.loaded;
    final original = images.getBackgroundImage(0, 0);
    final pending = images.setResolutionForScale(4);
    await Future<void>.delayed(Duration.zero);
    expect(requests.length, 4);
    expect(images.qualiStep, 1);
    expect(images.getBackgroundImage(0, 0), same(original));
    for (final response in requests.take(3)) {
      response.complete(http.Response.bytes(png, 200));
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(images.qualiStep, 1);
    requests.last.complete(http.Response.bytes(png, 200));
    await pending;
    expect(images.qualiStep, 4);
    expect(images.width, 4);
    expect(images.imageMap.length, 4);
    expect(images.getBackgroundImage(0, 0), isNot(same(original)));
    images.dispose();
  });

  test('obsolete zoom requests stop and never replace the active raster',
      () async {
    final requests = <Completer<http.Response>>[];
    APIServices.Shared.client = MockClient((request) {
      if (request.url.path.contains('TEST_1/')) {
        return Future.value(http.Response.bytes(png, 200));
      }
      final response = Completer<http.Response>();
      requests.add(response);
      return response.future;
    });
    final images =
        PageImageData.fetchLevelImages('TEST', [], grids, adaptive: true);
    await images.loaded;
    final original = images.getBackgroundImage(0, 0);
    final loading = images.setResolutionForScale(8);
    await Future<void>.delayed(Duration.zero);
    final latest = images.setResolutionForScale(1);
    for (final response in requests) {
      response.complete(http.Response.bytes(png, 200));
    }
    await Future.wait([loading, latest]);
    expect(requests.length, 4);
    expect(images.qualiStep, 1);
    expect(images.getBackgroundImage(0, 0), same(original));
    images.dispose();
  });

  test('failed resolution keeps old geometry and can retry; quality is capped',
      () async {
    var fail = true;
    APIServices.Shared.client = MockClient((request) async =>
        http.Response.bytes(
            png, fail && request.url.path.contains('TEST_2/') ? 503 : 200));
    final images = PageImageData.fetchLevelImages('TEST', [], grids,
        qualiIndex: 1, adaptive: true);
    await images.loaded;
    final original = images.getBackgroundImage(0, 0);
    await images.setResolutionForScale(16);
    expect(images.qualiStep, 1);
    expect(images.getBackgroundImage(0, 0), same(original));
    expect(images.failedImages, 2);
    fail = false;
    await images.setResolutionForScale(16);
    expect(images.qualiStep, 2);
    expect(images.failedImages, 0);
    await images.setResolutionForScale(.25);
    expect(images.qualiStep, 1);
    expect(images.imageMap.length, 1);
    images.dispose();
  });
}
