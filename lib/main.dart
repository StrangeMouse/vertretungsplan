import 'package:flutter/material.dart';
import 'package:vertretungsplan/Screens/home.dart';
import 'package:vertretungsplan/Screens/course_selection.dart';
import 'package:vertretungsplan/Screens/login.dart';

void main() {
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
        //"/": (context) => LoginScreen(),
        "/home" : (context) => const Home(),
        "/selectionScreen" : (context) => const SelectionScreen(),
        "/login": (context) => const LoginScreen(),
      },
    );
  }
}
