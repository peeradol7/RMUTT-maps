import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
