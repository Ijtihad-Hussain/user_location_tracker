import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'mapScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Location Tracker App',
      theme: ThemeData(primarySwatch: Colors.lightBlue),
      home: MapScreen(), // Replace with your main screen widget
    );
  }
}

