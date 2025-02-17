import 'dart:convert';

import 'package:maps/OpenChat/model/usermodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String uidKey = 'uid';
  static const String userData = 'userData';

  static const String userId = 'userid';

  final SharedPreferences _prefs;
  SharedPreferencesService(this._prefs);

  static Future<SharedPreferencesService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesService(prefs);
  }

  Future<String?> getStoredUid() async {
    final uid = _prefs.getString(uidKey);
    print('Retrieved UID from storage: $uid');
    return uid;
  }

  Future<void> saveLoginData(UserModel usermodel) async {
    try {
      final data = usermodel.toJson();
      print(
          '6. In saveLoginData before encode - password: ${data['password']}');

      final encoded = json.encode(data);
      print('7. In saveLoginData after encode: $encoded');

      await _prefs.setString(userData, encoded);
      print('8. After saving to SharedPreferences');

      await _prefs.setString(uidKey, usermodel.userId);
    } catch (e) {
      print('Error in saveLoginData: $e');
    }
  }

  Future<UserModel?> getStoredUserData() async {
    try {
      final userDataString = _prefs?.getString('userData');
      if (userDataString != null && userDataString.isNotEmpty) {
        final decoded = json.decode(userDataString);
        print('Decoded user data: $decoded');
        return UserModel.fromJson(decoded);
      }
    } catch (e) {
      print('Error getting stored user data: $e');
    }
    return null;
  }

  Future<void> clearLoginData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool userDataRemoved = await prefs.remove('userData');
    bool userIdRemoved = await prefs.remove('userId');

    print('User Data Removed: $userDataRemoved');
    print('User ID Removed: $userIdRemoved');

    if (!userDataRemoved || !userIdRemoved) {
      print('Warning: Some keys were not found in SharedPreferences.');
    }
  }
}
