import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:maps/OpenChat/ChatScreen.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
    required String name,
    required String username,
    required String password,
    required BuildContext context,
  }) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    try {
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      QuerySnapshot usernameSnapshot = await FirebaseFirestore.instance
          .collection('usersRMUTT')
          .where('username', isEqualTo: username)
          .get();

      if (usernameSnapshot.docs.isNotEmpty) {
        // Username already exists
        _showErrorDialog(
            context, 'Username already exists. Please choose another one.');
        return;
      }

      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('usersRMUTT')
          .doc(userCredential.user!.uid)
          .set({
        'phoneNumber': phoneNumber,
        'name': name,
        'username': username,
        'password': password,
      });

      // Navigate to ChatScreen with username and name
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            username: username,
            name: name,
          ),
        ),
      );
    } catch (e) {
      print('Error during sign-in: $e');
      _showErrorDialog(
          context, 'An error occurred during sign-in. Please try again.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
