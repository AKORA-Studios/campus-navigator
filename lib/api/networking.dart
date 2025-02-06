import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import 'api_services.dart';

const baseURL = "https://navigator.tu-dresden.de";

extension APIServices_Util on BaseAPIServices {
  /// This is a helper method for loading images that
  /// automatically caches them for ease of use
  Future<ui.Image?> fetchImage(Uri uri) async {
    final cachedImageFile =
        await cacheManager?.getFileFromCache(uri.toString());

    Uint8List imageBytes;
    if (cachedImageFile != null) {
      imageBytes = await cachedImageFile.file.readAsBytes();
    } else {
      final response = await http.get(uri);
      final eTag = response.headers["etag"];

      if (response.statusCode != 200) {
        return null;
      }

      await cacheManager?.putFile(uri.toString(), response.bodyBytes,
          maxAge: (await storage.getCacheDuration()).value,
          fileExtension: 'png',
          eTag: eTag);

      imageBytes = response.bodyBytes;
    }

    if (imageBytes.isEmpty) return null;

    return await decodeImage(imageBytes);
  }

  Future<String?> fetchHMTL(Uri uri) {
    return cachedStringRequest(uri, fileExtension: 'html');
  }

  /// This is a helper method for loading fetching string data and automatically cache it
  /// The fetched URI is assumed to contain UTF8 data
  Future<String?> cachedStringRequest(Uri uri,
      {Future<Response> Function(Uri uri)? requestFunction,
      String fileExtension = 'html'}) async {
    // The function used to actually execute request
    final requester = requestFunction ?? (uri) => client.get(uri);

    final cachedDataFile = await cacheManager?.getFileFromCache(uri.toString());

    String responseString;
    if (cachedDataFile != null) {
      responseString = await cachedDataFile.file.readAsString();
    } else {
      final response = await requester(uri);
      final eTag = response.headers["etag"];

      if (response.statusCode != 200) {
        return null;
      }

      responseString = response.body;
      // Ensure that cached text is always in utf8 format
      final encodedString = utf8.encode(responseString);

      await cacheManager?.putFile(uri.toString(), encodedString,
          fileExtension: fileExtension,
          maxAge: (await storage.getCacheDuration()).value,
          eTag: eTag);
    }

    if (responseString.isEmpty) return null;

    return responseString;
  }

  Future<ui.Image> decodeImage(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      return completer.complete(img);
    });

    return await completer.future;
  }
}
