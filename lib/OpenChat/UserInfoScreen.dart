import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9]{6,}$').hasMatch(username);
  }

  bool isValidPassword(String password) {
    return RegExp(r'^[a-zA-Z0-9]{8,}$').hasMatch(password);
  }

  Future<void> saveUserData({
    required String name,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final userCollection = FirebaseFirestore.instance.collection('users');
      await userCollection.doc(phoneNumber).set({
        'name': name,
        'username': username,
        'phoneNumber': phoneNumber,
        'password':
            password, // Ensure passwords are hashed in real applications
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User data saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save user data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter Your Details"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String name = _nameController.text.trim();
                String username = _usernameController.text.trim();
                String password = _passwordController.text.trim();
                String confirmPassword = _confirmPasswordController.text.trim();

                if (isValidUsername(username) && isValidPassword(password)) {
                  if (password == confirmPassword) {
                    await saveUserData(
                      name: name,
                      username: username,
                      phoneNumber: widget.phoneNumber,
                      password: password,
                    );
                    Navigator.pop(context);
                  } else {
                    _showErrorDialog(context, 'Passwords do not match.');
                  }
                } else {
                  String errorMessage = '';
                  if (!isValidUsername(username)) {
                    errorMessage +=
                        'Username must be at least 6 characters and contain only letters and numbers.\n';
                  }
                  if (!isValidPassword(password)) {
                    errorMessage += 'Password must be at least 8 characters.';
                  }
                  _showErrorDialog(context, errorMessage);
                }
              },
              child: Text("Submit"),
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

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
