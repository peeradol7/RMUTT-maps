import 'dart:convert';

import 'package:maps/model/usermodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String uidKey = 'uid';
  static const String userData = 'userData';

  static const String userId = 'userid';
  static final SharedPreferencesService _instance =
      SharedPreferencesService._internal();
  static SharedPreferences? _prefs;

  factory SharedPreferencesService() {
    return _instance;
  }

  SharedPreferencesService._internal();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> setString(String key, String value) async {
    return await _prefs!.setString(key, value);
  }

  String? getString(String key) {
    return _prefs!.getString(key);
  }

  Future<String?> getStoredUid() async {
    final uid = _prefs!.getString(uidKey);
    print('Retrieved UID from storage: $uid');
    return uid;
  }

  Future<void> saveLoginData(UserModel usermodel) async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance(); // Ensure initialization
      }

      final data = usermodel.toJson();
      print(
          '6. In saveLoginData before encode - password: ${data['password']}');

      final encoded = json.encode(data);
      print(encoded);

      await _prefs!.setString(userData, encoded);
      await _prefs!.setString(uidKey, usermodel.userId);
    } catch (e) {
      print('Error in saveLoginData: $e');
    }
  }

  Future<UserModel?> getStoredUserData() async {
    try {
      final userDataString = _prefs?.getString(userData);
      if (userDataString != null && userDataString.isNotEmpty) {
        print('User data string from SharedPreferences: $userDataString');
        final decoded = json.decode(userDataString);
        print('Decoded user data: $decoded');

        return UserModel.fromJson(decoded);
      } else {
        print('No user data found in SharedPreferences.');
      }
    } catch (e) {
      print('Error getting stored user data: $e');
    }
    return null;
  }

  Future<void> clearLoginData() async {
    _prefs!.clear();
  }
}
