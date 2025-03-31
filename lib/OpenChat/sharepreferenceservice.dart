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

  // Make init return the instance for chaining
  static Future<SharedPreferencesService> init() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance;
  }

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<bool> setString(String key, String value) async {
    await _ensureInitialized();
    return await _prefs!.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<String?> getStoredUid() async {
    await _ensureInitialized();
    final uid = _prefs!.getString(uidKey);
    print('Retrieved UID from storage: $uid');
    return uid;
  }

  Future<void> saveLoginData(UserModel usermodel) async {
    try {
      await _ensureInitialized();

      final data = usermodel.toJson();
      print(
          '6. In saveLoginData before encode - password: ${data['password']}');
      final encoded = json.encode(data);

      await Future.wait([
        _prefs!.setString(userData, encoded),
        _prefs!.setString(uidKey, usermodel.userId)
      ]);

      print('DATA *** $encoded');
    } catch (e) {
      print('Error in saveLoginData: $e');
      throw e;
    }
  }

  Future<UserModel?> getStoredUserData() async {
    try {
      await _ensureInitialized();
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
    await _ensureInitialized();
    await Future.wait([_prefs!.remove(userData), _prefs!.remove(uidKey)]);
  }
}
