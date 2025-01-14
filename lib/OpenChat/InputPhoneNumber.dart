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
  bool _isCheckbox = false;

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
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerificationOTPScreen(phoneNumber: phoneNumber),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error. Please check your connection.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAgreementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ข้อตกลงการขอข้อมูลส่วนตัว"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "คำชี้แจงเกี่ยวกับข้อมูลส่วนตัว\n\nในขั้นตอนการสมัครสมาชิก คุณจะต้องให้ข้อมูลบางประการเพื่อทำการลงทะเบียนในระบบ โดยข้อมูลที่เราขอจากคุณคือ เบอร์โทรศัพท์มือถือ เท่านั้น\n\nการใช้ข้อมูล\nข้อมูลเบอร์โทรศัพท์ของคุณจะถูกใช้เพียงเพื่อการยืนยันตัวตนและการส่งรหัส OTP (One Time Password) เพื่อให้คุณสามารถยืนยันการสมัครสมาชิกในระบบของเรา\n\nการรักษาความปลอดภัย\nเรามีมาตรการในการรักษาความปลอดภัยของข้อมูลส่วนตัวของคุณอย่างเข้มงวด โดยข้อมูลของคุณจะไม่ถูกเปิดเผยหรือใช้เพื่อวัตถุประสงค์อื่นใดโดยไม่ได้รับความยินยอมจากคุณ\n\nการยินยอม\nโดยการให้ข้อมูลเบอร์โทรศัพท์มือถือกับเรา คุณยอมรับว่าคุณได้อ่านและเข้าใจข้อตกลงนี้ และยินยอมให้เรานำข้อมูลดังกล่าวไปใช้ในการยืนยันตัวตนสำหรับการสมัครสมาชิกในระบบของเรา"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ปิด"),
          ),
        ],
      ),
    );
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _isCheckbox,
                      onChanged: (value) {
                        setState(() => _isCheckbox = value ?? false);
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showAgreementDialog,
                        child: RichText(
                          text: TextSpan(
                            text: 'ยอมรับข้อตกลง ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: 'อ่านข้อตกลง',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                  onPressed: (_isCheckbox && !_isLoading && !_isButtonDisabled)
                      ? () async {
                          setState(() => _isButtonDisabled = true);
                          await sendOTP(_phoneController.text.trim());
                          Future.delayed(Duration(seconds: 60), () {
                            if (mounted) {
                              setState(() => _isButtonDisabled = false);
                            }
                          });
                        }
                      : null,
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
