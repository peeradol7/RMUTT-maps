import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerController {
  final List<Marker> _markers = [];

  List<Marker> get markers => List.unmodifiable(_markers);
  void addMarker({
    required String id,
    required LatLng position,
    required String title,
    required BitmapDescriptor icon,
    required Function(LatLng) onTap,
  }) {
    _markers.removeWhere((marker) => marker.markerId.value == id);

    // เพิ่มมาร์คเกอร์ใหม่
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
