import 'package:html/parser.dart';
import 'api_services.dart';
import 'building/building_page_data.dart';
import 'networking.dart';
import 'saved_places.dart';

/// Building search URLs refer to campus maps, not floor plans. Resolve an
/// actually advertised floor instead of assuming every building has level 00.
String buildingFloorQuery(String html, String code) {
  final plans = parse(html)
      .querySelectorAll('a[href]')
      .map((a) {
        final uri = Uri.tryParse(a.attributes['href']!);
        if (uri == null ||
            (uri.hasScheme && uri.scheme != 'https' && uri.scheme != 'http') ||
            (uri.hasAuthority && uri.host != Uri.parse(baseURL).host)) {
          return null;
        }
        final parts = uri.pathSegments;
        if (parts.length == 3 &&
            parts[0] == 'etplan' &&
            parts[1] == code &&
            RegExp(r'^[\w-]+$').hasMatch(parts[2])) {
          return '${parts[1]}/${parts[2]}';
        }
        return null;
      })
      .whereType<String>()
      .toSet();
  if (plans.isEmpty) throw const FormatException('No floor plan available');
  return plans.contains('$code/00') ? '$code/00' : plans.first;
}

Future<BuildingPageData> loadSavedPlace(SavedPlace place) async {
  final query = place.identifier;
  if (place.kind == PlaceKind.building) {
    return loadBuildingFloor(place.buildingCode);
  }
  final data = await BuildingPageData.fetchQuery(query);
  if (place.kind == PlaceKind.room && data.selectedRoom?.id != place.roomId) {
    data.backgroundImageData?.dispose();
    throw const FormatException('Room identity no longer available');
  }
  return data;
}

/// Both search/favorites and the geographic catalog use the same floor resolver.
/// The campus API exposes building codes, but no search-region identifiers.
Future<BuildingPageData> loadBuildingFloor(String code) async {
  if (!RegExp(r'^[a-z0-9äöüß_-]+$').hasMatch(code)) {
    throw const FormatException('Invalid building code');
  }
  final body =
      await APIServices.Shared.fetchHMTL(Uri.parse('$baseURL/gebaeude/$code'));
  if (body == null) throw const FormatException('Building unavailable');
  return BuildingPageData.fetchQuery(buildingFloorQuery(body, code));
}
