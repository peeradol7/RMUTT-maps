import 'package:flutter/material.dart';

import 'Controller/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthController _authController = AuthController();
  bool _isButtonDisabled = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Register"),
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 4, 42, 73),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
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
                    onPressed: _isButtonDisabled
                        ? null
                        : () async {
                            setState(() => _isButtonDisabled = true);
                            await _authController.sendOTP(
                              phoneNumber: _phoneController.text.trim(),
                              context: context,
                            );
                            // รอ 60 วินาทีก่อนจะให้กดปุ่มอีกครั้ง
                            Future.delayed(Duration(seconds: 60), () {
                              setState(() => _isButtonDisabled = false);
                            });
                          },
                    child: Text(
                      "Send OTP",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 4, 42, 73),
                      foregroundColor: Colors.white,
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
      ),
    );
  }
}
