import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maps/OpenChat/Login.dart';
import 'package:maps/model/usermodel.dart';

import 'PasswordResetDialog.dart';
import 'sharepreferenceservice.dart';

class ChatScreen extends StatefulWidget {
  ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> _loadUserData() async {
    try {
      SharedPreferencesService prefs =
          await SharedPreferencesService.getInstance();
      UserModel? user = await prefs.getStoredUserData();

      setState(() {
        _user = user!;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_user == null) return;

    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      try {
        await _firestore.collection('chat').add({
          'message': message,
          'senderName': _user!.name,
          'senderUsername': _user!.username,
          'senderPhoneNumber': _user!.phoneNumber,
          'timestamp': FieldValue.serverTimestamp(),
        });

        _messageController.clear();

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('ไม่สามารถส่งข้อความได้ กรุณาลองใหม่อีกครั้ง')),
        );
      }
    }
  }

  void _logout() async {
    SharedPreferencesService prefs =
        await SharedPreferencesService.getInstance();

    await prefs.clearLoginData();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {}
  }

  Future<void> _resetPassword(String hashedPassword) async {
    try {
      await _firestore
          .collection('usersRMUTT')
          .where('username', isEqualTo: _user?.username)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          querySnapshot.docs.first.reference.update({
            'password': hashedPassword,
          });
        }
      });

      if (_user != null) {
        UserModel updatedUser = UserModel(
          userId: _user!.userId,
          username: _user!.username,
          name: _user!.name,
          password: hashedPassword,
          phoneNumber: _user!.phoneNumber,
        );

        SharedPreferencesService prefs =
            await SharedPreferencesService.getInstance();
        await prefs.saveLoginData(updatedUser);

        setState(() {
          _user = updatedUser;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('รีเซ็ทรหัสผ่านสำเร็จ')),
      );
    } catch (e) {
      print('Error resetting password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      drawer: _user != null
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.teal,
                    ),
                    child: Text(
                      'เมนู',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.password),
                    title: Text('รีเซ็ทรหัสผ่าน'),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      showDialog(
                        context: context,
                        builder: (context) => PasswordResetDialog(
                          user: _user!,
                          onPasswordReset: _resetPassword,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('ออกจากระบบ'),
                    onTap: _logout,
                  ),
                ],
              ),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No messages yet'));
                }

                return ListView(
                  controller: _scrollController,
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderUsername'] == _user?.username;

                    var timestamp = data['timestamp'] != null
                        ? DateFormat('dd MMM yyyy HH:mm')
                            .format((data['timestamp'] as Timestamp).toDate())
                        : 'Unknown time';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.teal[100] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['message'],
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${data['senderName']} • $timestamp',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _user?.userId != null
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            labelText: 'พิมพ์ข้อความ . . .',
                            labelStyle: TextStyle(color: Colors.teal),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send),
                        color: Colors.teal,
                        onPressed: _sendMessage,
                      ),
                    ],
                  )
                : SizedBox.shrink(), // ซ่อนแถบข้อความเมื่อไม่มี user
          ),
        ],
      ),
    );
  }
}
