import 'dart:convert'; // สำหรับแปลง JSON

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteController {
  final Function(List<LatLng>, List<Map<String, dynamic>>) onRouteFetched;

  RouteController({required this.onRouteFetched});

  Future<void> fetchAndCalculateRoutes(LatLng start, LatLng end) async {
    final url = Uri.parse('http://192.168.1.38:5000/find-path');
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
        List<LatLng> polylineCoordinates = path.map((point) {
          return LatLng(point[1], point[0]); // Convert [lng, lat] to LatLng
        }).toList();

        // Create steps with index information
        final steps = List<Map<String, dynamic>>.generate(
          path.length,
          (index) => {
            'point': LatLng(path[index][1], path[index][0]),
            'index': index,
          },
        );

        onRouteFetched(polylineCoordinates, steps);
      } else {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }
}
