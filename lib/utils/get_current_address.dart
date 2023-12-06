import 'package:geocoding/geocoding.dart';

Future getAddress(latitude, longitude) async {
  List<Placemark> placemark =
      await placemarkFromCoordinates(latitude, longitude);
  Placemark nearestPlace = placemark[0];

  return nearestPlace;
}
