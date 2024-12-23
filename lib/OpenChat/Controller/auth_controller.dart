import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../ChatScreen.dart';
import '../OTPVerification.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> sendOTP({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    // ตรวจสอบและแก้ไขเบอร์โทรศัพท์เป็น +66
    if (phoneNumber.startsWith('0')) {
      phoneNumber = '+66' + phoneNumber.substring(1);
    } else if (!phoneNumber.startsWith('+66')) {
      phoneNumber = '+66' + phoneNumber;
    }

    // เช็คว่าหมายเลขโทรศัพท์มีใน Firestore หรือไม่
    try {
      final QuerySnapshot result = await firestore
          .collection('usersRMUTT')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      final List<DocumentSnapshot> documents = result.docs;
      if (documents.isNotEmpty) {
        // ถ้ามีหมายเลขโทรศัพท์นี้อยู่แล้ว ให้แสดงข้อความเตือน
        _showErrorDialog(context, 'คุณได้สมัครสมาชิกไปแล้ว.');
        return;
      }

      // ถ้าไม่มีหมายเลขโทรศัพท์นี้ใน Firestore ก็ส่ง OTP
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-sign-in, can be ignored in this context
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                verificationId: verificationId,
                phoneNumber: phoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Code auto retrieval timeout: $verificationId');
        },
      );
    } catch (e) {
      print('Error checking phone number: $e');
      _showError(context, 'เกิดข้อผิดพลาดในการตรวจสอบหมายเลขโทรศัพท์');
    }
  }

  void _showError(BuildContext context, String message) {
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

      // Check if the username already exists
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
