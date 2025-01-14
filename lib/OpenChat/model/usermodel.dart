import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String username;
  final String name;
  final String password;
  final String phoneNumber;

  UserModel({
    required this.userId,
    required this.username,
    required this.name,
    required this.password,
    required this.phoneNumber,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    return UserModel(
      userId: doc.id,
      username: doc['username'],
      name: doc['name'],
      password: doc['password'],
      phoneNumber: doc['phoneNumber'],
    );
  }

  // แปลงข้อมูลเป็น Map สำหรับบันทึกไป Firestore
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'name': name,
      'password': password,
      'phoneNumber': phoneNumber,
    };
  }
}
