import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> saveUserData({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    await FirebaseFirestore.instance.collection('usersRMUTT').add({
      'name': name,
      'username': username,
      'phoneNumber': phoneNumber,
      'password': password,
    });
  }
}
