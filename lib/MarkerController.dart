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

  void updateMarker({
    required String id,
    required LatLng position,
    String? title,
    BitmapDescriptor? icon,
    Function(LatLng)? onTap,
  }) {
    final index = _markers.indexWhere((marker) => marker.markerId.value == id);

    if (index != -1) {
      // ดึงมาร์คเกอร์เดิม
      final oldMarker = _markers[index];
      _markers[index] = Marker(
        markerId: MarkerId(id),
        position: position,
        infoWindow:
            title != null ? InfoWindow(title: title) : oldMarker.infoWindow,
        icon: icon ?? oldMarker.icon,
        onTap: onTap != null
            ? () => onTap(position)
            : oldMarker.onTap as void Function()?,
      );
    }
  }

  void clearMarkers({String? exceptId}) {
    if (exceptId != null) {
      _markers.removeWhere((marker) => marker.markerId.value != exceptId);
    } else {
      _markers.clear();
    }
  }
}
