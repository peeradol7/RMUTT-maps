import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:maps/OpenChat/model/usermodel.dart';

import '../sharepreferenceservice.dart';

class LoginController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<UserModel?> login({
    required String username,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Hash the input password before comparison
      String hashedPassword = hashPassword(password);
      print('Input Password (hashed): $hashedPassword');

      QuerySnapshot querySnapshot = await _firestore
          .collection('usersRMUTT')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userDoc = querySnapshot.docs.first;
        String storedPassword = userDoc['password'];

        print('Stored Password: $storedPassword');

        if (storedPassword == hashedPassword) {
          UserModel user = UserModel(
            userId: userDoc['userId'],
            username: userDoc['username'],
            name: userDoc['name'],
            password: storedPassword,
            phoneNumber: (userDoc.data() as Map<String, dynamic>)
                    .containsKey('phoneNumber')
                ? userDoc['phoneNumber']
                : '',
          );

          SharedPreferencesService prefs =
              await SharedPreferencesService.getInstance();
          await prefs.saveLoginData(user);

          return user;
        } else {
          _showErrorDialog(context, 'รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง');
          return null;
        }
      } else {
        _showErrorDialog(context, 'ไม่พบชื่อผู้ใช้ กรุณาลองใหม่อีกครั้ง');
        return null;
      }
    } catch (e) {
      print('Error during login: $e');
      _showErrorDialog(context, 'เกิดข้อผิดพลาด กรุณาลองใหม่ภายหลัง');
      return null;
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
