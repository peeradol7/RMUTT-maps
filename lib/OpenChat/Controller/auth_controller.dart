import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:maps/OpenChat/OTPVerification.dart';

import '../ChatScreen.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> saveUserData({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    await FirebaseFirestore.instance.collection('users').add({
      'name': name,
      'username': username,
      'phoneNumber': phoneNumber,
      'password': password,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendOTP({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    print('Original phone number: $phoneNumber');
    if (phoneNumber.startsWith('0')) {
      phoneNumber = '+66' + phoneNumber.substring(1);
    } else if (!phoneNumber.startsWith('+66')) {
      phoneNumber = '+66' + phoneNumber;
    }
    print('Formatted phone number: $phoneNumber');

    try {
      final QuerySnapshot result = await firestore
          .collection('usersRMUTT')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      print('Firebase Auth instance: ${FirebaseAuth.instance}');

      if (result.docs.isNotEmpty) {
        _showErrorDialog(context, 'คุณได้สมัครสมาชิกไปแล้ว.');
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'เกิดข้อผิดพลาดในการส่ง OTP';

          if (e.code == 'too-many-requests') {
            errorMessage =
                'มีการขอ OTP บ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่อีกครั้ง';
          } else if (e.message?.contains('BILLING_NOT_ENABLED') ?? false) {
            errorMessage = 'ระบบยังไม่พร้อมใช้งาน กรุณาติดต่อผู้ดูแลระบบ';
          }

          print('Verification failed: ${e.code}');
          print('Error message: ${e.message}');
          _showErrorDialog(context, errorMessage);
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
      print('Firebase initialization error: $e');
      _showErrorDialog(context, 'เกิดข้อผิดพลาดในการตรวจสอบหมายเลขโทรศัพท์');
    }
  }

  Future<void> verifyOTP({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
    required String name,
    required String username,
    required String password,
    required BuildContext context,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      QuerySnapshot usernameSnapshot = await firestore
          .collection('usersRMUTT')
          .where('username', isEqualTo: username)
          .get();

      if (usernameSnapshot.docs.isNotEmpty) {
        _showErrorDialog(context, 'Username already exists.');
        return;
      }

      await firestore
          .collection('usersRMUTT')
          .doc(userCredential.user!.uid)
          .set({
        'phoneNumber': phoneNumber,
        'name': name,
        'username': username,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            username: username,
            name: name,
          ),
        ),
      );
    } catch (e) {
      print('Error verifying OTP: $e');
      _showErrorDialog(context, 'OTP Verification failed.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
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
