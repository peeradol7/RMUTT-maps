import 'dart:convert';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

class MapboxDirectionService {
  static const String token =
      'pk.eyJ1IjoicGVlcmFkb2w3NSIsImEiOiJjbTU2N3VtaXoyd3RvMmxzZWZsOTU2a283In0.1H_sKPytOL72AJeNz4U99g';

  Future<List<List<double>>> getDirections(
      double startLat, double startLng, double endLat, double endLng) async {
    final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/$startLng,$startLat;$endLng,$endLat?geometries=polyline&access_token=$token');

    final response = await http.get(url);
    print(response.body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
        final route = data['routes'][0];
        final distance = route['distance'] ?? 0.0;

        print('Total Distance: $distance meters');

        if (distance <= 30) {
          print('ถึงปลายทางแล้ว');
          return [];
        }

        final geometry = route['geometry'];
        if (geometry != null && geometry is String) {
          List<PointLatLng> polylinePoints =
              PolylinePoints().decodePolyline(geometry);

          return polylinePoints
              .map((point) => [point.latitude, point.longitude])
              .toList();
        } else {
          throw Exception('Invalid geometry data');
        }
      } else {
        throw Exception('No routes found');
      }
    } else {
      throw Exception('Failed to load directions: ${response.body}');
    }
  }
}
