import 'package:get/get.dart';

class DistanceController extends GetxController {
  var walkDistance = 0.0.obs;
  var carDistance = 0.0.obs;

  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return 'ระยะทาง : ${distanceInMeters.toStringAsFixed(0)} เมตร';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return 'ระยะทาง : ${distanceInKm.toStringAsFixed(2)} กิโล';
    }
  }

  String get carFormat => carDistance.value < 1000
      ? '${carDistance.value.toStringAsFixed(0)} เมตร'
      : '${(carDistance.value / 1000).toStringAsFixed(2)} กิโล';

  String get walkFormat => walkDistance.value < 1000
      ? '${walkDistance.value.toStringAsFixed(0)} เมตร'
      : '${(walkDistance.value / 1000).toStringAsFixed(2)} กิโล';
}
