import 'dart:convert'; // สำหรับแปลง JSON

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionController {
  final Function(List<LatLng>, List<Map<String, dynamic>>) onRouteFetched;

  DirectionController({required this.onRouteFetched});

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

        print('Received path points: ${path.length}');

        List<LatLng> polylineCoordinates = path.map((point) {
          return LatLng(point[1], point[0]);
        }).toList();

        print('Generated polyline coordinates: ${polylineCoordinates.length}');

        final steps = List<Map<String, dynamic>>.generate(
          path.length,
          (index) {
            final point = LatLng(path[index][1], path[index][0]);
            print('Step $index: ${point.latitude}, ${point.longitude}');
            return {
              'point': point,
              'index': index,
              'passed': false, // เพิ่ม flag สำหรับติดตามสถานะ
            };
          },
        );

        print('Generated steps: ${steps.length}');
        print('----------------------\n');

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
