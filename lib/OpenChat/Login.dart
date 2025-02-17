import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:maps/OpenChat/forgotPassword/ForgotPasswordScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './Controller/LoginController.dart';
import 'ChatScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LoginController _loginController = LoginController();

  bool _isRememberMeChecked = false;
  bool _isLoading = false;

  int _failedAttempts = 0;
  Timer? _cooldownTimer;
  DateTime? _cooldownEndTime;

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> _loadFailedAttempts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _failedAttempts = prefs.getInt('failedAttempts') ?? 0;
    String? cooldownEnd = prefs.getString('cooldownEndTime');
    if (cooldownEnd != null) {
      _cooldownEndTime = DateTime.tryParse(cooldownEnd);
      if (_cooldownEndTime != null &&
          DateTime.now().isBefore(_cooldownEndTime!)) {
        _startCooldownTimer();
      } else {
        await prefs.remove('cooldownEndTime');
      }
    }
  }

  void _startCooldownTimer() {
    if (_cooldownEndTime != null) {
      _cooldownTimer?.cancel();
      final duration = _cooldownEndTime!.difference(DateTime.now());
      _cooldownTimer = Timer(duration, () {
        setState(() {
          _failedAttempts = 0;
          _cooldownEndTime = null;
        });
      });
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFailedAttempts();
    _cooldownTimer?.cancel();
  }

  Future<void> _login() async {
    if (_cooldownEndTime != null &&
        DateTime.now().isBefore(_cooldownEndTime!)) {
      _showCooldownDialog();
      return;
    }

    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกชื่อผู้ใช้และรหัสผ่าน')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userModel = await _loginController.login(
        username: username,
        password: password,
        context: context,
      );

      if (userModel != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      } else {
        setState(() {
          _failedAttempts++;
          if (_failedAttempts >= 3) {
            _startCooldown();
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startCooldown() {
    setState(() {
      _cooldownEndTime = DateTime.now().add(Duration(minutes: 5));
    });
    _showCooldownDialog();
  }

  void _showCooldownDialog() {
    if (_cooldownEndTime == null) return;

    final remaining = _cooldownEndTime!.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('การล็อคอินถูกระงับ'),
        content: Text(
          'คุณป้อนรหัสผิดครบ 3 ครั้ง กรุณารอ $minutes:${seconds.toString().padLeft(2, '0')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Login"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          if (_isRememberMeChecked)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('ยืนยันการออกจากระบบ'),
                    content: Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('ยกเลิก'),
                      ),
                      TextButton(
                        onPressed: () async {
                          _usernameController.clear();
                          _passwordController.clear();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('ออกจากระบบสำเร็จ')),
                          );
                        },
                        child: Text('ยืนยัน'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
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
                    height: 250,
                    width: 250,
                  ),
                  SizedBox(height: 30),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: "กรอกชื่อผู้ใช้",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.person, color: Colors.teal),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: "กรอกรหัสผ่าน",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.lock, color: Colors.teal),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      // Checkbox(
                      //   value: _isRememberMeChecked,
                      //   onChanged: (bool? value) {
                      //     setState(() {
                      //       _isRememberMeChecked = value ?? false;
                      //     });
                      //   },
                      // ),
                      // Text("จดจำฉัน"),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "ลืมรหัสผ่าน?",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "เข้าสู่ระบบ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
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
