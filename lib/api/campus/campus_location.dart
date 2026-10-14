import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

enum CampusLocationFailure { denied, disabled, unavailable }

class CampusLocationException implements Exception {
  final CampusLocationFailure reason;
  const CampusLocationException(this.reason);
}

/// Invoked only by the location button. No background tracking or startup prompt.
Future<LatLng> locateOnCampus() async {
  final location = Location();
  if (!await location.serviceEnabled() && !await location.requestService()) {
    throw const CampusLocationException(CampusLocationFailure.disabled);
  }
  var permission = await location.hasPermission();
  if (permission == PermissionStatus.denied) {
    permission = await location.requestPermission();
  }
  if (permission != PermissionStatus.granted &&
      permission != PermissionStatus.grantedLimited) {
    throw const CampusLocationException(CampusLocationFailure.denied);
  }
  final result =
      await location.getLocation().timeout(const Duration(seconds: 20));
  final lat = result.latitude;
  final lon = result.longitude;
  if (lat == null ||
      lon == null ||
      !lat.isFinite ||
      !lon.isFinite ||
      lat.abs() > 85 ||
      lon.abs() > 180) {
    throw const CampusLocationException(CampusLocationFailure.unavailable);
  }
  return LatLng(lat, lon);
}
