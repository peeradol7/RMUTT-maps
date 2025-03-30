import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:maps/OpenChat/sharepreferenceservice.dart';
import 'package:maps/model/usermodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserInfoScreen extends StatefulWidget {
  final String phoneNumber;

  UserInfoScreen({required this.phoneNumber});

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final prefs = SharedPreferencesService();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9]{6,}$').hasMatch(username);
  }

  bool isValidPassword(String password) {
    return RegExp(r'^[a-zA-Z0-9]{8,}$').hasMatch(password);
  }

  bool isValidName(String name) {
    return name.trim().isNotEmpty;
  }

  Future<bool> isUsernameAvailable(String username) async {
    final result = await FirebaseFirestore.instance
        .collection('usersRMUTT')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isEmpty;
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> saveUserData({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    setState(() => _isLoading = true);

    try {
      if (!await isUsernameAvailable(username)) {
        _showErrorDialog(context, 'Username is already taken.');
        return;
      }

      final hashedPassword = hashPassword(password);
      final userCollection =
          FirebaseFirestore.instance.collection('usersRMUTT');
      String userId = userCollection.doc().id;

      final data = await UserModel(
        userId: userId,
        username: username,
        name: name,
        password: hashedPassword,
        phoneNumber: phoneNumber,
      );

      await userCollection.doc(userId).set({
        'userId': userId,
        'name': name,
        'username': username,
        'phoneNumber': phoneNumber,
        'password': hashedPassword,
      });
      await prefs.saveLoginData(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครสมาชิกเรียบร้อย')),
        );
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
            context, 'Failed to save user data. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter Your Details"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "กรอกชื่อ",
                border: OutlineInputBorder(),
                helperText: "กรอกชื่อจริงของคุณ",
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "กรอกชื่อผู้ใช้",
                border: OutlineInputBorder(),
                helperText: "กรอกชื่อผู้ใช้อย่างน้อยจำนวน 6 ตัวอักษรและตัวเลข",
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "กรอกรหัสผ่าน",
                border: OutlineInputBorder(),
                helperText:
                    "อักขระขั้นต่ำ 8 ตัว ประกอบด้วยตัวพิมพ์ใหญ่ ตัวพิมพ์เล็ก ตัวเลข และอักขระพิเศษ",
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: "ยืนยันรหัสผ่าน",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      String name = _nameController.text.trim();
                      String username = _usernameController.text.trim();
                      String password = _passwordController.text.trim();
                      String confirmPassword =
                          _confirmPasswordController.text.trim();

                      if (!isValidName(name)) {
                        _showErrorDialog(
                            context, 'คุณยังไม่ได้กรอกชื่อ กรุณากรอกชื่อ');
                        return;
                      }

                      if (!isValidUsername(username)) {
                        _showErrorDialog(context,
                            'ชื่อผู้ใช้ต้องมีอย่างน้อย 6 ตัวอักษรและประกอบด้วยตัวอักษรและตัวเลขเท่านั้น');
                        return;
                      }

                      if (!isValidPassword(password)) {
                        _showErrorDialog(context,
                            'รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษรและประกอบด้วยตัวอักษรและตัวเลขเท่านั้น');
                        return;
                      }

                      if (password != confirmPassword) {
                        _showErrorDialog(
                            context, 'การยืนยันรหัสผ่านไม่ถูกต้อง');
                        return;
                      }

                      await saveUserData(
                        name: name,
                        username: username,
                        phoneNumber: widget.phoneNumber,
                        password: password,
                      );
                    },
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("ลงทะเบียน"),
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
    );
  }
}
