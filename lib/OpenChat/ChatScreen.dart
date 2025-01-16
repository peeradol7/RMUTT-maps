import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maps/OpenChat/model/usermodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final UserModel user;

  ChatScreen({required this.user});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      await _firestore.collection('chat').add({
        'message': message,
        'senderName': widget.user.name,
        'senderUsername': widget.user.username,
        'senderPhoneNumber': widget.user.phoneNumber, // Add phoneNumber here
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _showEditDialog() {
    TextEditingController nameController =
        TextEditingController(text: widget.user.name);
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("แก้ไขข้อมูล"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "เปลี่ยนชื่อ",
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "เปลี่ยนรหัสผ่าน",
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog without saving
              },
              child: Text("ยกเลิก"),
            ),
            // Save button
            ElevatedButton(
              onPressed: () async {
                // Get the updated name and password
                String updatedName = nameController.text.trim();
                String updatedPassword = passwordController.text.trim();

                if (updatedName.isNotEmpty && updatedPassword.isNotEmpty) {
                  // Update the user object with new values
                  UserModel updatedUser = UserModel(
                    userId: widget.user.userId, // Retain the user ID
                    username: widget.user.username,
                    name: updatedName, // New name
                    password: updatedPassword, // New password
                    phoneNumber: widget.user.phoneNumber,
                  );

                  // Save the updated data to Firestore
                  await FirebaseFirestore.instance
                      .collection('usersRMUTT')
                      .doc(widget.user.userId)
                      .update(updatedUser.toJson());

                  // Optionally, save updated data to SharedPreferences as well
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setString('user', jsonEncode(updatedUser.toJson()));

                  // Close the dialog
                  Navigator.pop(context);

                  // Optionally, show a confirmation message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ข้อมูลถูกบันทึกเรียบร้อยแล้ว')),
                  );
                } else {
                  // Show error if fields are empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
                  );
                }
              },
              child: Text("บันทึก"),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    Navigator.of(context).popUntil(
        (route) => route.isFirst); // กลับไปที่หน้าก่อนหน้า หรือหน้าหลัก
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      drawer: Drawer(
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
              leading: Icon(Icons.edit),
              title: Text('แก้ไขข้อมูล'),
              onTap: _showEditDialog,
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('เปลี่ยนเบอร์มือถือ'),
              onTap: () {
                // Show the dialog when the tile is tapped
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('กรุณาติดต่อเจ้าหน้าที่'),
                    content: Text(
                        'หากคุณต้องการเปลี่ยนเบอร์มือถือ \nกรุณาติดต่อเจ้าหน้าที่'),
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
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('ออกจากระบบ'),
              onTap: _logout,
            ),
          ],
        ),
      ),
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

                _scrollToBottom();

                return ListView(
                  controller: _scrollController,
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderUsername'] == widget.user.username;

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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            ),
          ),
        ],
      ),
    );
  }
}
