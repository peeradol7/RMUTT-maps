import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:maps/OpenChat/OTPVerification.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _phoneController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> sendOTP() async {
    String phoneNumber = _phoneController.text.trim();

    // Check if the number starts with 0 and replace it with +66
    if (phoneNumber.startsWith('0')) {
      phoneNumber = '+66' + phoneNumber.substring(1);
    } else if (!phoneNumber.startsWith('+66')) {
      phoneNumber = '+66' + phoneNumber;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-sign-in, can be ignored in this context
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Verification failed: ${e.message}');
        // Show error message
      },
      codeSent: (String verificationId, int? resendToken) {
        print('OTP sent: $verificationId');
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendOTP,
              child: Text("Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
