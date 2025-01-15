import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps/OpenChat/forgotPassword/VerificationOTP.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  // แปลงรูปแบบเบอร์โทร
  String formatPhoneNumber(String phone) {
    if (phone.startsWith('0')) {
      return '66${phone.substring(1)}';
    }
    return phone;
  }

  Future<void> _checkPhoneAndSendOTP() async {
    String phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกเบอร์โทรศัพท์')),
      );
      return;
    }

    // ตรวจสอบรูปแบบเบอร์โทร
    if (!phoneNumber.startsWith('0')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาใส่เบอร์โทรที่ขึ้นต้นด้วย 0')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ตรวจสอบเบอร์โทรใน Firebase
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('usersRMUTT')
          .where('phoneNumber', isEqualTo: formatPhoneNumber(phoneNumber))
          .get();

      if (result.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบเบอร์โทรศัพท์ในระบบ')),
        );
        return;
      }

      String userId = result.docs.first.id;
      String formattedPhone = formatPhoneNumber(phoneNumber);

      // ส่ง OTP ผ่าน API
      const String url = 'https://apicall.deesmsx.com/v1/otp/request';
      final response = await http.post(Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "secretKey": "ec7ccf46-90cff8f2-170e19f1-725835ce",
            "apiKey": "ac22861a-3b9eb09a-ad300ddd-d26d94a3",
            "to": formattedPhone,
            "sender": "RMUTT-Nav",
            "lang": "th",
            "isShowRef": "1",
          }));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == '200') {
        final token = data['result']['token'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationOTPScreen(
              phoneNumber: formattedPhone,
              userId: userId,
              token: token,
            ),
          ),
        );
      } else {
        String errorMessage = data['msg'] ?? 'เกิดข้อผิดพลาดในการส่ง OTP';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ลืมรหัสผ่าน"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "เบอร์โทรศัพท์",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _checkPhoneAndSendOTP,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(
                        "ส่ง OTP",
                        style: TextStyle(fontSize: 16),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.teal, // Use backgroundColor instead of primary
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
