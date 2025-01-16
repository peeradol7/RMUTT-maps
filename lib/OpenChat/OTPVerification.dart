import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps/OpenChat/UserInfoScreen.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String token;

  const VerificationScreen({
    required this.phoneNumber,
    required this.token,
  });

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> verifyOTP(String pin) async {
    const String url = 'https://apicall.deesmsx.com/v1/otp/verify';
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final Map<String, dynamic> body = {
      "secretKey": "ec7ccf46-90cff8f2-170e19f1-725835ce",
      "apiKey": "ac22861a-3b9eb09a-ad300ddd-d26d94a3",
      "token": widget.token,
      "pin": pin,
    };

    setState(() => _isLoading = true);

    try {
      final response = await http.post(Uri.parse(url),
          headers: headers, body: jsonEncode(body));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == "0") {
          _navigateToUserInfoScreen();
        } else {
          _showErrorDialog("Invalid OTP. Please try again.");
        }
      } else {
        _showErrorDialog("Server error: ${response.statusCode}");
      }
    } catch (error) {
      _showErrorDialog("An error occurred. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToUserInfoScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserInfoScreen(phoneNumber: widget.phoneNumber),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Verify OTP"),
        backgroundColor: const Color.fromARGB(255, 4, 42, 73),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "ยืนยัน OTP ที่ส่งจากSMS",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: "OTP",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock, color: Colors.teal),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final otp = _otpController.text.trim();
                          if (otp.isEmpty || otp.length != 6) {
                            _showErrorDialog(
                                "Please enter a valid 6-digit OTP.");
                            return;
                          }
                          await verifyOTP(otp);
                        },
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          "ยืนยันรหัส OTP",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 4, 42, 73),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
