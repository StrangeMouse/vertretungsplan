import 'package:flutter/material.dart';
import 'package:vertretungsplan/Screens/home.dart';
import 'package:vertretungsplan/Screens/course_selection.dart';
import 'package:vertretungsplan/Screens/login.dart';
import 'package:vertretungsplan/Screens/grade_selection.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
  Size size = view.physicalSize / view.devicePixelRatio;
  final double screenWidth = size.width;
  if (screenWidth < 500) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Vertretungsplan LIO",
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        //colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        //brightness: Brightness.dark,
      ),
      routes: {
        "/" : (context) => const Home(),
        //"/": (context) => const GradeSelection(),
        //"/": (context) => LoginScreen(),
        "/home" : (context) => const Home(),
        "/gradeSelection": (context) => const GradeSelection(),
        "/selectionScreen" : (context) => const SelectionScreen(),
        "/login": (context) => const LoginScreen(),
      },
    );
  }
}
