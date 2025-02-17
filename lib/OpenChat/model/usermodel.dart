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
  bool get isNotEmpty {
    return name.isNotEmpty &&
        username.isNotEmpty; // You can check more fields here
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      username: json['username'],
      name: json['name'],
      password: json['password'],
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'name': name,
      'phoneNumber': phoneNumber,
      'password': password,
    };
  }
}
