import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps/OpenChat/OTPVerification.dart';

class SendOTPScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<SendOTPScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isButtonDisabled = false;

  Future<void> sendOTP(String phoneNumber) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final url = Uri.parse('https://console.sms-kub.com/api/v2/otp/request');

    final headers = {
      'Authorization': 'Key thjF6P1TOF5k5zQrTGl7kNs7fFgY03IC',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'phone': phoneNumber,
      'project': '668cc35202f3a7634f532266',
    });

    try {
      print('Sending OTP request with body: $body');

      final response = await http
          .post(
            url,
            headers: headers,
            body: body,
          )
          .timeout(Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // ตรวจสอบสถานะการตอบกลับ
      if (response.statusCode == 200) {
        // แสดงหน้าสำหรับยืนยัน OTP
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerificationOTPScreen(phoneNumber: phoneNumber),
          ),
        );
      } else {
        // แยกข้อความข้อผิดพลาดจาก Response
        String errorMessage = 'Failed to send OTP. Please try again.';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Error sending OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error. Please check your connection.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Register"),
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
                Image.asset(
                  'assets/image1.png',
                  height: 150,
                  width: 150,
                ),
                SizedBox(height: 30),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.phone, color: Colors.teal),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (_isButtonDisabled || _isLoading)
                      ? null
                      : () async {
                          setState(() => _isButtonDisabled = true);
                          await sendOTP(_phoneController.text.trim());
                          Future.delayed(Duration(seconds: 60), () {
                            if (mounted) {
                              setState(() => _isButtonDisabled = false);
                            }
                          });
                        },
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          "Send OTP",
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
