import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

const baseURL = "https://navigator.tu-dresden.de";

/// This is a helper method for loading images that
/// automatically caches them for ease of use
Future<ui.Image?> fetchImage(Uri uri) async {
  final cachedImageFile =
      await DefaultCacheManager().getFileFromCache(uri.toString());
  if (cachedImageFile != null) {
    return await decodeImage(await cachedImageFile.file.readAsBytes());
  }

  final response = await http.get(uri);

  if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
    return null;
  }

  // This wont get awaited
  DefaultCacheManager().putFile(uri.toString(), response.bodyBytes,
      maxAge: const Duration(days: 1));

  return await decodeImage(response.bodyBytes);
}

Future<ui.Image> decodeImage(Uint8List bytes) async {
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(bytes, (ui.Image img) {
    return completer.complete(img);
  });

  return await completer.future;
}
