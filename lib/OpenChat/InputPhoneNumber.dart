import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps/OpenChat/OTPVerification.dart';

class InputPhoneNumberScreen extends StatefulWidget {
  @override
  _InputPhoneNumberScreenState createState() => _InputPhoneNumberScreenState();
}

class _InputPhoneNumberScreenState extends State<InputPhoneNumberScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isButtonDisabled = false;
  bool _isCheckbox = false;

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
                "คำชี้แจงเกี่ยวกับข้อมูลส่วนตัว\n\nในขั้นตอนการสมัครสมาชิก คุณจะต้องให้ข้อมูลบางประการเพื่อทำการลงทะเบียนในระบบ โดยข้อมูลที่เราขอจากคุณคือ เบอร์โทรศัพท์มือถือ เท่านั้น\n\nการใช้ข้อมูล\nข้อมูลเบอร์โทรศัพท์ของคุณจะถูกใช้เพียงเพื่อการยืนยันตัวตนและการส่งรหัส OTP (One Time Password) เพื่อให้คุณสามารถยืนยันการสมัครสมาชิกในระบบของเรา\n\nการรักษาความปลอดภัย\nเรามีมาตรการในการรักษาความปลอดภัยของข้อมูลส่วนตัวของคุณอย่างเข้มงวด โดยข้อมูลของคุณจะไม่ถูกเปิดเผยหรือใช้เพื่อวัตถุประสงค์อื่นใดโดยไม่ได้รับความยินยอมจากคุณ\n\nการยินยอม\nโดยการให้ข้อมูลเบอร์โทรศัพท์มือถือกับเรา คุณยอมรับว่าคุณได้อ่านและเข้าใจข้อตกลงนี้ และยินยอมให้เรานำข้อมูลดังกล่าวไปใช้ในการยืนยันตัวตนสำหรับการสมัครสมาชิกในระบบของเรา",
              ),
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

  String formatPhoneNumber(String phone) {
    if (phone.startsWith('0')) {
      return '66${phone.substring(1)}';
    }
    return phone;
  }

  Future<bool> checkPhoneInFirebase(String phoneNumber) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('usersRMUTT')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone in Firebase: $e');
      return false;
    }
  }

  Future<void> sendOTP(String phoneNumber) async {
    setState(() => _isLoading = true);

    try {
      if (!phoneNumber.startsWith('0')) {
        _showErrorDialog("กรุณาใส่เบอร์โทรที่ขึ้นต้นด้วย 0");
        return;
      }

      String formattedPhone = formatPhoneNumber(phoneNumber);

      bool phoneExists = await checkPhoneInFirebase(formattedPhone);
      if (phoneExists) {
        _showErrorDialog("เบอร์โทรนี้มีในระบบอยู่แล้ว กรุณาใช้เบอร์อื่น");
        return;
      }

      const String url = 'https://apicall.deesmsx.com/v1/otp/request';
      final Map<String, String> headers = {'Content-Type': 'application/json'};
      final Map<String, dynamic> body = {
        "secretKey": "ec7ccf46-90cff8f2-170e19f1-725835ce",
        "apiKey": "ac22861a-3b9eb09a-ad300ddd-d26d94a3",
        "to": formattedPhone,
        "sender": "RMUTT-Nav",
        "lang": "th",
        "isShowRef": "1",
      };

      final response = await http.post(Uri.parse(url),
          headers: headers, body: jsonEncode(body));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == '200' &&
            data['result'] != null &&
            data['result']['token'] != null) {
          final token = data['result']['token'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                phoneNumber: formattedPhone, // ส่งเบอร์ที่แปลงแล้วไป
                token: token,
              ),
            ),
          );
        } else {
          String errorMessage =
              data['msg'] ?? "Failed to send OTP. Please try again.";
          _showErrorDialog(errorMessage);
        }
      } else {
        _showErrorDialog(
            "Server error (${response.statusCode}): ${response.body}");
      }
    } catch (error) {
      print('Error sending OTP: $error');
      _showErrorDialog("An error occurred: $error");
    } finally {
      setState(() => _isLoading = false);
    }
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
                    labelText: "กรอกหมายเลขโทรศัพท์",
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
                          "ส่งรหัส OTP",
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
