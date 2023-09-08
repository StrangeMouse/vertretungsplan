//import 'dart:math';

import 'package:flutter/material.dart';
//import 'package:http/http.dart';
import 'package:vertretungsplan/units_api.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String login = '';
  Map<String, String> headers = {};
  String cookies = '';
  late Future<Map<String, dynamic>> timetable;
  late Future<List<String>> courses;
  late Future<Map<int, dynamic>> idList;
  late Future<Map<int, dynamic>> idLocList;
  late Future<int> periodTest;
  late Map<String, dynamic> customTimetable;

  Future<Map<String, dynamic>> getTimeTable() async {
    await untisLogin("LiO-Lernende", "Schueler.2021");
    Map<String, dynamic> timetable = await getTimeTableJSONDict("845", 2023, 9, 6);
    return timetable;
  }

  Future<Map<String, dynamic>> getCustomTimeTable() async {
    await untisLogin("LiO-Lernende", "Schueler.2021");
    Map<String, dynamic> timetable = await getCustomTimeTableJSON("845", 2023, 9, 6, ["M 1", "e 7"]);
    return timetable;
  }

  Future<List<String>> getCourses() async {
    await untisLogin("LiO-Lernende", "Schueler.2021");
    List<String> coursesList = await getCoursesList("845", 2023, 9, 6);
    return coursesList;
  }

  Future<Map<int, dynamic>> getIdList() async {
    await untisLogin("LiO-Lernende", "Schueler.2021");
    Future<Map<int, dynamic>> idList = getCoursesIdDict("845", 2023, 9, 6);
    return idList;
  }

  Future<Map<int, dynamic>> getIdLocList() async {
    await untisLogin("LiO-Lernende", "Schueler.2021");
    Future<Map<int, dynamic>> idLocList = getLocationsIdDict("845", 2023, 9, 6);
    return idLocList;
  }

  Future<int> getPeriod(int time) async {
    await untisLogin("LiO-Lernende", "Schueler.2021");
    var json = await getTimeGridJSONFromServer();
    print(json.runtimeType);
    int lessonNumber = getLessonNumberFromJSON(json, time);
    return lessonNumber;
  }

  @override
  void initState() {
    super.initState();
    timetable = getCustomTimeTable();
    courses = getCourses();
    idList = getIdList();
    idLocList = getIdLocList();
    periodTest = getPeriod(1335);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vertretungsplan LiO"),
      ),
      body: ListView(
        children: [
          Text(getWeekdayFromDate(20230904)),
          FutureBuilder(
            future: timetable,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data!.toString());
              } else if (snapshot.hasError) {
                return Text("something went wrong${snapshot.error}");
              } else {
                return Text("loading");
              }
            },
          ),
          FutureBuilder(
            future: idLocList,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data!.toString());
              } else if (snapshot.hasError) {
                return Text("something went wrong${snapshot.error}");
              } else {
                return Text("loading");
              }
            },
          ),
          FutureBuilder<Map<int, dynamic>>(
            future: idList,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(children: [Text(login), Text(snapshot.data!.toString())]);
              } else if (snapshot.hasError) {
                return Text("something went wrong${snapshot.error}");
              } else {
                return Text("loading");
              }
            },
          ),
        ],
      ),
    );
  }
}
