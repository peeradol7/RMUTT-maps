import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class QuestionnaireDialogHelper {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DialogQuestionnaire();
      },
    );
  }
}

class _DialogQuestionnaire extends StatelessWidget {
  final String surveyUrl = 'https://forms.gle/ALzwR2tk6VokcJQA6';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('แบบสอบถาม'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/qrcode.png',
            width: 100,
            height: 100,
          ),
          SizedBox(height: 16),
          Text(
            'สแกน QR Code หรือเปิดลิงค์\n',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('เพื่อทำแบบสอบถามการใช้งานแอปพลิเคชัน'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            launchUrl(Uri.parse('https://forms.gle/ALzwR2tk6VokcJQA6'));
          },
          child: Text('เปิดลิงค์'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // ปิด Dialog
          },
          child: Text('ปิด'),
        ),
      ],
    );
  }
}
