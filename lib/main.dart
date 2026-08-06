import 'package:flutter/material.dart';
import 'package:my_app2/view/camera_screen.dart';
// import 'viewmodels/home_screen.dart';
// import 'viewmodels/camera_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // TODO : change title name
      title: 'Flutter Demo',
      home: const CameraScreen(),
    );
  }
}
