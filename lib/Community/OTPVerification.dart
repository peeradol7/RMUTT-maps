import 'package:flutter/material.dart';

import 'auth_controller.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  OTPVerificationScreen({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthController _authController = AuthController();

  bool isValidUsername(String username) {
    // Username must contain only English letters and numbers, and be at least 6 characters long
    return RegExp(r'^[a-zA-Z0-9]{6,}$').hasMatch(username);
  }

  bool isValidPassword(String password) {
    return RegExp(r'^[a-zA-Z0-9]{8,}$').hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.text,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String username = _usernameController.text.trim();
                String password = _passwordController.text.trim();
                String confirmPassword = _confirmPasswordController.text.trim();
                String smsCode = _otpController.text.trim();

                if (isValidUsername(username) && isValidPassword(password)) {
                  if (password == confirmPassword) {
                    _authController.signInWithPhoneNumber(
                      verificationId: widget.verificationId,
                      smsCode: smsCode,
                      phoneNumber: widget.phoneNumber,
                      name: _nameController.text.trim(),
                      username: username,
                      password: password,
                      context: context,
                    );
                  } else {
                    _showErrorDialog(context, 'Passwords do not match.');
                  }
                } else {
                  String errorMessage = '';
                  if (!isValidUsername(username)) {
                    errorMessage +=
                        'Username must contain only English letters and numbers and be at least 6 characters long.\n';
                  }
                  if (!isValidPassword(password)) {
                    errorMessage += 'Password must be at least 8 characters.';
                  }
                  _showErrorDialog(context, errorMessage);
                }
              },
              child: Text("Verify OTP"),
            ),
          ],
        ),
      ),
    );
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
