import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:maps/OpenChat/model/usermodel.dart';

import '../ChatScreen.dart';

class LoginController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    print('Input Password: $password');
    print('Hashed Result: ${hash.toString()}');
    return hash.toString();
  }

  Future<bool> login({
    required String username,
    required String password,
    required BuildContext context,
  }) async {
    try {
      print('Input Password: $password');

      QuerySnapshot querySnapshot = await _firestore
          .collection('usersRMUTT')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userDoc = querySnapshot.docs.first;
        String storedPassword = userDoc['password'];

        print('Stored Password: $storedPassword');
        print('Login Password: $password');

        if (storedPassword == password) {
          UserModel user = UserModel(
            userId: userDoc['userId'],
            username: userDoc['username'],
            name: userDoc['name'],
            password: userDoc['password'],
            phoneNumber: (userDoc.data() != null &&
                    (userDoc.data() as Map<String, dynamic>)
                        .containsKey('phoneNumber'))
                ? userDoc['phoneNumber']
                : '',
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ChatScreen(user: user),
            ),
          );
          return true;
        } else {
          _showErrorDialog(context, 'Incorrect password. Please try again.');
          return false;
        }
      } else {
        _showErrorDialog(context, 'Username not found. Please try again.');
        return false;
      }
    } catch (e) {
      print('Error during login: $e');
      _showErrorDialog(context, 'An error occurred. Please try again later.');
      return false;
    }
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
