import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionService {
  static const String apiKey =
      "5b3ce3597851110001cf6248fa49e44af4634d66a806d21a70336dbb";
  static const String baseUrl =
      "https://api.openrouteservice.org/v2/directions/driving-car";

  static Future<List<LatLng>> getRoute(LatLng currentLocation,
      LatLng destination, String destinationName) async {
    String url =
        "$baseUrl?api_key=$apiKey&start=${currentLocation.longitude},${currentLocation.latitude}&end=${destination.longitude},${destination.latitude}";

    try {
      final response = await http.get(Uri.parse(url));
      print("Response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['features'] == null || data['features'].isEmpty) {
          print("No routes found in the response");
          return [];
        }

        var geometry = data['features'][0]['geometry'];

        if (geometry == null || geometry['coordinates'] == null) {
          print("No geometry or coordinates found");
          return [];
        }

        List<dynamic> coordinates = geometry['coordinates'];

        return coordinates
            .map((point) {
              if (point is List && point.length >= 2) {
                return LatLng(point[1], point[0]);
              }
              print("Invalid coordinate format: $point");
              return null;
            })
            .whereType<LatLng>()
            .toList();
      } else {
        print("Failed to load route. Status code: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching route: $e");
      return [];
    }
  }
}
