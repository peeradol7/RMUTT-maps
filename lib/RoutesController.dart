import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteController {
  final BuildContext context;
  final Function(List<LatLng>, List<Map<String, dynamic>>) onRouteFetched;

  RouteController({required this.context, required this.onRouteFetched});

  Future<void> fetchAndCalculateRoutes(
      LatLng endLocation, String destination) async {
    final String url =
        'https://355c12d0-f697-4646-9c07-0715c29de092-00-b95cq7qvlj7.pike.replit.dev/Route';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK' &&
          json['routes'] != null &&
          json['routes'].isNotEmpty) {
        final route = json['routes'][0];
        print("Received route data: ${route['data']}");

        final matchingData = route['data'].firstWhere(
          (data) =>
              data['end_address'] != null &&
              data['end_address']
                  .toString()
                  .toLowerCase()
                  .contains(destination.toLowerCase()),
          orElse: () => null,
        );

        if (matchingData != null) {
          final steps = matchingData['steps'];
          final List<LatLng> polylineCoordinates = _extractCoordinates(steps);

          onRouteFetched(polylineCoordinates, steps);
        } else {
          print('No matching data found for destination: $destination');
          _findNearestRouteAndDisplay(endLocation, route['data']);
        }
      } else {
        print('No routes found in the response or status is not OK.');
      }
    } else {
      print(
          'Failed to fetch initial route. Status code: ${response.statusCode}');
    }
  }

  void _findNearestRouteAndDisplay(
      LatLng endLocation, List<dynamic> routeData) {
    double minDistance = double.infinity;
    Map<String, dynamic>? nearestRoute;

    for (var data in routeData) {
      LatLng routeStartLocation =
          LatLng(data['start_location']['lat'], data['start_location']['lng']);
      double distance = _calculateDistance(endLocation, routeStartLocation);

      if (distance < minDistance) {
        minDistance = distance;
        nearestRoute = data;
      }
    }

    if (nearestRoute != null) {
      final steps = nearestRoute['steps'];
      final List<LatLng> polylineCoordinates = _extractCoordinates(steps);

      onRouteFetched(polylineCoordinates, steps);
      print('Displaying route to the nearest point.');
    } else {
      print('No suitable route found.');
    }
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
    const double earthRadius = 6371; // Earth's radius in kilometers
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
