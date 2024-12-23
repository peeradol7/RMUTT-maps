import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../ChatScreen.dart';

class LoginController {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> login({
    required String username,
    required String password,
    required BuildContext context,

  }) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('usersRMUTT')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        var userDoc = querySnapshot.docs.first;
        String storedPassword = userDoc['password'];
        String name = userDoc['name'];

        if (storedPassword == password) {

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                username: username,
                name: name,
              ),
            ),
          );
        } else {
          _showErrorDialog(context, 'Incorrect password. Please try again.');
        }
      } else {
        _showErrorDialog(context, 'Username not found. Please try again.');
      }
    } catch (e) {
      print('Error during login: $e');
      _showErrorDialog(context, 'An error occurred. Please try again later.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text('Login Failed', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay', style: TextStyle(color: Colors.blue)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }
}
