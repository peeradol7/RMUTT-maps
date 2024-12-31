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

  void clearMarkers({String? exceptId}) {
    if (exceptId != null) {
      _markers.removeWhere((marker) => marker.markerId.value != exceptId);
    } else {
      _markers.clear();
    }
  }
}
