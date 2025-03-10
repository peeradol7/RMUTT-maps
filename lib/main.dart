import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'Map_page/map.dart';

void main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MapSample(),
        title: 'RMUTT Nav',
        theme: ThemeData(
          primarySwatch: Colors.lightBlue,
        ),
      ),
    );
  }
}
