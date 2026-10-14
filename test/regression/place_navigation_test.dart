import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/building/building_page_data.dart';
import 'package:campus_navigator/api/place_navigation.dart';
import 'package:campus_navigator/api/saved_places.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../support/floor_fixture.dart';

class QualityStorage extends Storage {
  @override
  Future<int> getQualityLevel() async => 1;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final html = syntheticFloor().htmlData.document.outerHtml;

  test(
      'real navigation loader requests the stored room URL and exact target ID',
      () async {
    final paths = <String>[];
    APIServices.Shared = APIServices.withoutCache()
      ..storage = QualityStorage()
      ..client = MockClient((request) async {
        paths.add(request.url.path);
        return http.Response(
            request.url.path.startsWith('/etplan/') ? html : '', 200);
      });
    final place = SavedPlace(
        kind: PlaceKind.room, identifier: 'test/00/raum/test.318', name: '318');
    final data = await loadSavedPlace(place);
    expect(paths.first, '/etplan/test/00/raum/test.318');
    expect(data.selectedRoom!.id, place.roomId);
    await data.backgroundImageData!.loaded;
    data.backgroundImageData!.dispose();
    await expectLater(
        loadSavedPlace(SavedPlace(
            kind: PlaceKind.room,
            identifier: 'test/00/raum/missing',
            name: '318')),
        throwsFormatException);
    APIServices.Shared.client.close();
  });

  test(
      'building favorite resolves advertised floor before using existing loader',
      () async {
    final paths = <String>[];
    APIServices.Shared = APIServices.withoutCache()
      ..storage = QualityStorage()
      ..client = MockClient((request) async {
        paths.add(request.url.path);
        return http.Response(
            request.url.path == '/gebaeude/test'
                ? '<a href="etplan/test/02">2</a>'
                : request.url.path.startsWith('/etplan/')
                    ? html
                    : '',
            200);
      });
    final BuildingPageData data = await loadSavedPlace(SavedPlace(
        kind: PlaceKind.building,
        identifier: 'dresden/geb/test',
        name: 'Building'));
    expect(paths.take(2), ['/gebaeude/test', '/etplan/test/02']);
    expect(data.selectedRoom, isNull);
    await data.backgroundImageData!.loaded;
    data.backgroundImageData!.dispose();
    APIServices.Shared.client.close();
  });
}
