import 'dart:convert'; // สำหรับแปลง JSON

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionController {
  final Function(List<LatLng>, List<Map<String, dynamic>>) onRouteFetched;
  final Function() onArrivalDetected; // Add new callback for arrival

  DirectionController({
    required this.onRouteFetched,
    required this.onArrivalDetected, // Add to constructor
  });

  Future<void> fetchAndCalculateRoutes(LatLng start, LatLng end) async {
    print('\n--- API Request Debug ---');
    print('Start point: ${start.latitude}, ${start.longitude}');
    print('End point: ${end.latitude}, ${end.longitude}');

    final url =
        Uri.parse('https://dijkstarapi-production.up.railway.app/find-path');
    final requestBody = {
      "start": [start.longitude, start.latitude],
      "end": [end.longitude, end.latitude]
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final path = data['path'] as List;
        final totalDistance =
            data['total_distance'] as double; // Extract total_distance

        print('Received path points: ${path.length}');
        print('Total distance: $totalDistance');

        List<LatLng> polylineCoordinates = path.map((point) {
          return LatLng(point[1], point[0]);
        }).toList();

        final int pointsPerStep = 3;
        List<Map<String, dynamic>> steps = [];

        for (int i = 0; i < polylineCoordinates.length; i += pointsPerStep) {
          int endIndex = i + pointsPerStep > polylineCoordinates.length
              ? polylineCoordinates.length
              : i + pointsPerStep;

          Map<String, dynamic> step = {
            'point': polylineCoordinates[i],
            'start_index': i,
            'end_index': endIndex - 1,
            'passed': false,
            'coordinates': polylineCoordinates.sublist(i, endIndex),
          };
          steps.add(step);
        }

        print('Generated steps: ${steps.length}');
        print('----------------------\n');

        // Check if we've arrived (total_distance <= 0.085)
        if (totalDistance <= 0.055) {
          onArrivalDetected(); // Trigger arrival callback
        }

        onRouteFetched(polylineCoordinates, steps);
      } else {
        print('API Error: ${response.statusCode}');
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }
}
