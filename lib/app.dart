import 'package:flutter/material.dart';
import 'package:vertretungsplan/units_api.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vertretungsplan LiO"),
      ),
    );
  }
}
