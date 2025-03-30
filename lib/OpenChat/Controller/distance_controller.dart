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
}
