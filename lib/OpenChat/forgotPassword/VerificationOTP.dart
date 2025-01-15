import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps/OpenChat/forgotPassword/ResetPassword.dart';
import 'package:pinput/pinput.dart';

class VerificationOTPScreen extends StatefulWidget {
  final String phoneNumber;
  final String userId;
  final String token;

  const VerificationOTPScreen({
    Key? key,
    required this.phoneNumber,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _VerificationOTPScreenState createState() => _VerificationOTPScreenState();
}

class _VerificationOTPScreenState extends State<VerificationOTPScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  Future<void> _verifyOTP(String pin) async {
    setState(() => _isLoading = true);

    try {
      const String url = 'https://apicall.deesmsx.com/v1/otp/verify';
      final response = await http.post(Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "secretKey": "ec7ccf46-90cff8f2-170e19f1-725835ce",
            "apiKey": "ac22861a-3b9eb09a-ad300ddd-d26d94a3",
            "token": widget.token,
            "pin": pin,
          }));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == '200') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              userId: widget.userId,
            ),
          ),
        );
      } else {
        String errorMessage = data['msg'] ?? 'รหัส OTP ไม่ถูกต้อง';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการยืนยัน OTP')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isResending = true);

    try {
      const String url = 'https://apicall.deesmsx.com/v1/otp/request';
      final response = await http.post(Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "secretKey": "ec7ccf46-90cff8f2-170e19f1-725835ce",
            "apiKey": "ac22861a-3b9eb09a-ad300ddd-d26d94a3",
            "to": widget.phoneNumber,
            "sender": "RMUTT-Nav",
            "lang": "th",
            "isShowRef": "1",
          }));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == '200') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งรหัส OTP ใหม่แล้ว')),
        );
      } else {
        String errorMessage = data['msg'] ?? 'ไม่สามารถส่งรหัส OTP ได้';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Error resending OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการส่งรหัส OTP')),
      );
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('ยืนยันรหัส OTP'),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'กรุณากรอกรหัส OTP',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'รหัสยืนยันถูกส่งไปที่เบอร์ ${widget.phoneNumber}',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              Pinput(
                length: 6,
                controller: _pinController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: Colors.teal),
                  ),
                ),
                onCompleted: (pin) => _verifyOTP(pin),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed:
                    _isLoading ? null : () => _verifyOTP(_pinController.text),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text('ยืนยันรหัส OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.teal, // Use backgroundColor instead of primary
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: _isResending ? null : _resendOTP,
                child: _isResending
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.teal),
                      )
                    : Text(
                        'ส่งรหัส OTP อีกครั้ง',
                        style: TextStyle(color: Colors.teal),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
