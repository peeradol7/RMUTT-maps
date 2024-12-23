import 'dart:convert';
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteController {
  final Function(List<LatLng>, List<Map<String, dynamic>>) onRouteFetched;

  RouteController({required this.onRouteFetched});

  Future<void> fetchAndCalculateRoutes(
      LatLng currentLocation, LatLng endLocation, String destination) async {
    final String url =
        'https://355c12d0-f697-4646-9c07-0715c29de092-00-b95cq7qjvlj7.pike.replit.dev/get-route';

    final Map<String, dynamic> requestBody = {
      'currentLat': currentLocation.latitude.toString(),
      'currentLng': currentLocation.longitude.toString(),
      'selectedLat': endLocation.latitude.toString(),
      'selectedLng': endLocation.longitude.toString(),
      'destination': destination,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['message'] == 'Route found' && json['route'] != null) {
          final routeData = json['route']['data'];

          final nearestRoute = _findNearestRoute(routeData, currentLocation);
          if (nearestRoute != null) {
            final steps = nearestRoute['steps'];
            final List<LatLng> polylineCoordinates = _extractCoordinates(steps);
            onRouteFetched(polylineCoordinates, steps);
          }
        }
      } else {
        print('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  Map<String, dynamic>? _findNearestRoute(
      List<dynamic> routeData, LatLng currentLocation) {
    double minDistance = double.infinity;
    Map<String, dynamic>? nearestRoute;

    for (var data in routeData) {
      LatLng routeStartLocation =
          LatLng(data['start_location']['lat'], data['start_location']['lng']);
      double distance = _calculateDistance(currentLocation, routeStartLocation);

      if (distance < minDistance) {
        minDistance = distance;
        nearestRoute = data;
      }
    }
    return nearestRoute;
  }

  List<LatLng> _extractCoordinates(List<dynamic> steps) {
    List<LatLng> polylineCoordinates = [];
    for (var step in steps) {
      LatLng startLocation =
          LatLng(step['start_location']['lat'], step['start_location']['lng']);
      LatLng endLocation =
          LatLng(step['end_location']['lat'], step['end_location']['lng']);

      polylineCoordinates.add(startLocation);
      polylineCoordinates.add(endLocation);
    }
    return polylineCoordinates;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371;
    final double dLat = _degreesToRadians(point2.latitude - point1.latitude);
    final double dLng = _degreesToRadians(point2.longitude - point1.longitude);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(point1.latitude)) *
            cos(_degreesToRadians(point2.latitude)) *
            (sin(dLng / 2) * sin(dLng / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
