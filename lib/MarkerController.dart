import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerController {
  final Set<Marker> _markers = {};

  Set<Marker> get markers => _markers;

  void addMarker({
    required String id,
    required LatLng position,
    required String title,
    required BitmapDescriptor icon,
    required Function(LatLng) onTap,
  }) {
    _markers.add(
      Marker(
        markerId: MarkerId(id),
        position: position,
        infoWindow: InfoWindow(title: title),
        icon: icon,
        onTap: () => onTap(position),
      ),
    );
  }

  void addToiletMarkers(Function(LatLng) onTap, BitmapDescriptor icon) {
    addMarker(
      id: 'ห้องน้ำ1',
      position: LatLng(14.035978558473701, 100.72472173847785),
      title: 'ห้องน้ำ 1',
      icon: icon,
      onTap: onTap,
    );
  }

  void addFoodMarkers(Function(LatLng) onTap) {
    List<Map<String, dynamic>> foodLocations = [
      {
        'id': 'ตู้เต่าบิน1',
        'position': LatLng(14.0341588, 100.7298778),
        'title': 'ตู้เต่าบิน1',
        'icon': BitmapDescriptor.hueAzure,
      },
      {
        'id': 'ศูนย์อาหารช่อพวงชมพู',
        'position': LatLng(14.039641633441367, 100.72955146567259),
        'title': 'ศูนย์อาหารช่อพวงชมพู',
        'icon': BitmapDescriptor.hueAzure,
      },
    ];

    for (var location in foodLocations) {
      addMarker(
        id: location['id'],
        position: location['position'],
        title: location['title'],
        icon: BitmapDescriptor.defaultMarkerWithHue(location['icon']),
        onTap: (LatLng position) {},
      );
    }
  }
}
