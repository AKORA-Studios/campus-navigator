import 'dart:async';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

Future<ui.Image?> fetchImage(Uri uri) {
  return http.get(uri).then((response) async {
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      return null;
    }

    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(response.bodyBytes, (ui.Image img) {
      return completer.complete(img);
    });

    var image = await completer.future;
    return image;
  });
}
