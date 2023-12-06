import 'dart:convert';

import 'package:boats_mobile_app/constants/api_url.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapInformationApi {
  Future<Map<String, dynamic>> getDirections(
      String origin, String destination) async {
    var response =
        await http.get(Uri.parse(getDirectionUrl(origin, destination)));

    var json = jsonDecode(response.body);
    var results = {
      'bounds_ne': json['routes'][0]['bounds']['northeast'],
      'bounds_sw': json['routes'][0]['bounds']['southwest'],
      'start_location': json['routes'][0]['legs'][0]['start_location'],
      'end_location': json['routes'][0]['legs'][0]['end_location'],
      'polyline': json['routes'][0]['overview_polyline']['points'],
      'polyline_decoded': PolylinePoints()
          .decodePolyline(json['routes'][0]['overview_polyline']['points']),
    };

    return results;
  }

  Future<double> getDistance(LatLng origin, LatLng destination) async {
    var response =
        await http.get(Uri.parse(getDistanceUrl(origin, destination)));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['status'] == 'OK') {
        var route = data['routes'][0];
        var legs = route['legs'][0];
        var distance = legs['distance']['value'];

        // Distance is in meters, you can convert it to other units as needed
        double distanceInKm = distance / 1000.0;
        return distanceInKm;
      }
    }

    throw Exception('Failed to retrieve distance.');
  }
}
