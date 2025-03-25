import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class Cardirectionservice {
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

class RouteTrackingService {
  Timer? _timer;
  final Function(List<LatLng>) onRouteUpdate;
  final Function() onDestinationReached;

  RouteTrackingService({
    required this.onRouteUpdate,
    required this.onDestinationReached,
  });

  double _calculateDistance(LatLng point1, LatLng point2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 -
        c((point2.latitude - point1.latitude) * p) / 2 +
        c(point1.latitude * p) *
            c(point2.latitude * p) *
            (1 - c((point2.longitude - point1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R; R = 6371 km
  }

  void startRouteTracking(
    LatLng currentLocation,
    LatLng destination,
    String destinationName,
  ) {
    stopRouteTracking();

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        // Get updated route
        List<LatLng> route = await Cardirectionservice.getRoute(
          currentLocation,
          destination,
          destinationName,
        );

        if (route.isNotEmpty) {
          double distanceToDestination = _calculateDistance(
            currentLocation,
            destination,
          );

          onRouteUpdate(route);

          if (distanceToDestination <= 100) {
            print('ถึงปลายทางแล้ว');
            onDestinationReached();
            stopRouteTracking();
          }
        }
      } catch (e) {
        print('Error updating route: $e');
      }
    });
  }

  void stopRouteTracking() {
    _timer?.cancel();
    _timer = null;
  }
}
