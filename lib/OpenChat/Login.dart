import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:maps/OpenChat/forgotPassword/ForgotPasswordScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './Controller/LoginController.dart';

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
    _checkLoginStatus();
    _loadFailedAttempts();
    _cooldownTimer?.cancel();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    String? username = prefs.getString('username');
    String? hashedPassword = prefs.getString('hashedPassword');

    if (isLoggedIn == true && username != null && hashedPassword != null) {
      _usernameController.text = username;
      setState(() => _isRememberMeChecked = true);
      try {
        await _loginController.login(
          username: username,
          password: hashedPassword,
          context: context,
        );
      } catch (e) {
        await prefs.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'การเข้าสู่ระบบอัตโนมัติล้มเหลว กรุณาเข้าสู่ระบบอีกครั้ง')),
        );
      }
    }
  }

  Future<void> _login() async {
    if (_cooldownEndTime != null &&
        DateTime.now().isBefore(_cooldownEndTime!)) {
      final remaining = _cooldownEndTime!.difference(DateTime.now());
      _showCooldownDialog(remaining);
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
      String hashedPassword = hashPassword(password);
      final isLoginSuccessful = await _loginController.login(
        username: username,
        password: hashedPassword,
        context: context,
      );

      if (isLoginSuccessful) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('failedAttempts');
        await prefs.remove('cooldownEndTime');
        _failedAttempts = 0;
      } else {
        setState(() => _failedAttempts += 1);
        if (_failedAttempts >= 3) {
          _startCooldown();
        }
      }
    } catch (e) {
      setState(() => _failedAttempts += 1);
      if (_failedAttempts >= 3) {
        _startCooldown();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startCooldown() async {
    _cooldownEndTime = DateTime.now().add(Duration(minutes: 5));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('failedAttempts', _failedAttempts);
    await prefs.setString(
        'cooldownEndTime', _cooldownEndTime!.toIso8601String());
    _startCooldownTimer();
    final remaining = _cooldownEndTime!.difference(DateTime.now());
    _showCooldownDialog(remaining);
  }

  void _showCooldownDialog(Duration remaining) {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('การล็อคอินถูกระงับ'),
        content: Text(
            'คุณป้อนรหัสผิดครบ 3 ครั้ง กรุณารอ $minutes:${seconds.toString().padLeft(2, '0')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearStoredCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() => _isRememberMeChecked = false);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        // แก้ไขจาก AppBar เป็น appBar
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
                          await _clearStoredCredentials();
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
                      Checkbox(
                        value: _isRememberMeChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            _isRememberMeChecked = value ?? false;
                          });
                        },
                      ),
                      Text("จดจำฉัน"),
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
