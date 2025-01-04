import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps/OpenChat/UserInfoScreen.dart';

class VerificationOTPScreen extends StatefulWidget {
  final String phoneNumber;
  const VerificationOTPScreen({required this.phoneNumber});

  @override
  _VerificationOTPScreenState createState() => _VerificationOTPScreenState();
}

class _VerificationOTPScreenState extends State<VerificationOTPScreen> {
  final TextEditingController _otpController = TextEditingController();

  Future<void> verifyOTP(String otp) async {
    final url = Uri.parse('https://console.sms-kub.com/api/v2/otp/verify');
    final headers = {
      'Key': 'Key',
      'Value': 'thjF6P1TOF5k5zQrTGl7kNs7fFgY03IC',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'otp': otp,
      'phone': widget.phoneNumber,
      'project': '668cc35202f3a7634f532266',
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          responseData['data']['validate'] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UserInfoScreen(phoneNumber: widget.phoneNumber),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Verify OTP"),
        backgroundColor: const Color.fromARGB(255, 4, 42, 73),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: "Enter OTP",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock, color: Colors.teal),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => verifyOTP(_otpController.text.trim()),
                  child: Text(
                    "Verify OTP",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
