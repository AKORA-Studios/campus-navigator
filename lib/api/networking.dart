import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart';
import 'api_services.dart';

const baseURL = 'https://navigator.tu-dresden.de';
const requestTimeout = Duration(seconds: 25);

extension APIServices_Util on BaseAPIServices {
  Future<ui.Image?> fetchImage(Uri uri) async {
    return (await fetchImageResult(uri)).image;
  }

  /// Empty HTTP-200 bodies are valid blank plan tiles on the TU server.
  /// Keep them distinct from errors without allocating a transparent bitmap.
  Future<({ui.Image? image, bool empty})> fetchImageResult(Uri uri) async {
    final key = uri.toString();
    final pending = pendingImages.putIfAbsent(key, () => _imageBytes(uri));
    List<int>? bytes;
    try {
      bytes = await pending;
    } finally {
      if (identical(pendingImages[key], pending)) pendingImages.remove(key);
    }
    if (bytes == null) return (image: null, empty: false);
    if (bytes.isEmpty) return (image: null, empty: true);
    return (image: await decodeImage(Uint8List.fromList(bytes)), empty: false);
  }

  Future<List<int>?> _imageBytes(Uri uri) async {
    final key = uri.toString();
    final cached = await cacheManager?.getFileFromCache(key);
    if (cached != null && cached.validTill.isAfter(DateTime.now())) {
      return cached.file.readAsBytes();
    }
    final response =
        await tileRequests.run(() => client.get(uri).timeout(requestTimeout));
    if (response.statusCode != 200) return null;
    await cacheManager?.putFile(key, response.bodyBytes,
        maxAge: (await storage.getCacheDuration()).value,
        fileExtension: 'png',
        eTag: response.headers['etag']);
    return response.bodyBytes;
  }

  Future<String?> fetchHMTL(Uri uri) => cachedStringRequest(uri);

  /// Custom request callers must encode all POST parameters in the cache key.
  Future<String?> cachedStringRequest(Uri uri,
      {Future<Response> Function(Uri uri)? requestFunction,
      String fileExtension = 'html',
      String? cacheKey}) async {
    final key = cacheKey ?? uri.toString();
    final pending = pendingStrings.putIfAbsent(key, () async {
      final cached = await cacheManager?.getFileFromCache(key);
      if (cached != null && cached.validTill.isAfter(DateTime.now())) {
        return cached.file.readAsString();
      }
      final response =
          await (requestFunction ?? client.get)(uri).timeout(requestTimeout);
      if (response.statusCode != 200) return null;
      // HTTP's body getter honors a declared ISO-8859-1 charset.
      final body = response.body;
      if (body.isEmpty) return null;
      await cacheManager?.putFile(key, utf8.encode(body),
          maxAge: (await storage.getCacheDuration()).value,
          fileExtension: fileExtension,
          eTag: response.headers['etag']);
      return body;
    });
    try {
      return await pending;
    } finally {
      if (identical(pendingStrings[key], pending)) pendingStrings.remove(key);
    }
  }

  Future<ui.Image> decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }
}
