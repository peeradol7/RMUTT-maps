import 'package:flutter/material.dart';
import 'package:maps/OpenChat/ChatScreen.dart';
import 'package:maps/OpenChat/InputPhoneNumber.dart';

import 'Login.dart';
import 'sharepreferenceservice.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late SharedPreferencesService _pref;
  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _pref = await SharedPreferencesService.getInstance();
  }

  Future<void> handlePlayButton(BuildContext context) async {
    try {
      print('Starting login process');

      final storedUid = await _pref.getStoredUid();
      print('Stored UID: $storedUid');

      if (storedUid != null && storedUid.isNotEmpty) {
        print('Valid UID found');

        final userData = await _pref.getStoredUserData();
        print('Stored User Data: $userData');

        if (!context.mounted) {
          print('Context not mounted');
          return;
        }

        if (userData != null && userData.isNotEmpty) {
          print('User data is not empty, navigating to ChatScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(),
            ),
          );
          return;
        } else {
          print('User data is empty');
        }
      } else {
        print('No valid UID found');
      }

      if (!context.mounted) {
        print('Context not mounted');
        return;
      }

      print('Navigating to LoginScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    } catch (e) {
      print('Error in login process: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 35),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("assets/image1.png", height: 200),
                const SizedBox(height: 30),
                const Text(
                  "Login (OpenChat)",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 15),
                const Text(
                  "เข้าสู่ระบบเพื่อเข้าใช้งานระบบ OpenChat",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 40),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
                      },
                      child: const Text("เข้าสู่ระบบ",
                          style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InputPhoneNumberScreen(),
                          ),
                        );
                      },
                      child: const Text("สมัครสมาชิก",
                          style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
