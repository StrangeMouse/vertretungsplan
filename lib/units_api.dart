//import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'package:cookie_jar/cookie_jar.dart';
import 'package:intl/intl.dart';
import 'dart:developer';

var session = http.Client();
String cookies = '';

String getCookiesFromHeader(Map<String, String> headers) {
  String cookies = '';

  if (headers["set-cookie"] != null) {
    // Split the "Set-Cookie" headers into individual cookie strings.
    String setCookies = headers["set-cookie"]!;
    var cookieStrings = setCookies.split(',');

    for (var cookieString in cookieStrings) {
      // Split each cookie string by semicolons to extract attributes.
      var cookieAttributes = cookieString.trim().split(';');

      // The first part of the cookieAttributes array is the cookie name and value.
      var cookieNameAndValue = cookieAttributes[0].trim();
      var parts = cookieNameAndValue.split('=');

      if (parts.length >= 2) {
        var name = parts[0];
        var value = parts.sublist(1).join('=').trim();

        cookies += name;
        cookies += "=";
        cookies += value;
        cookies += ";";
      }
    }
  }
  return cookies;
}

Future<http.Response> untisLogin(String username, String password) async {
  var payload = {
    'school': 'jl-schule darmstadt',
    'j_username': username,
    'j_password': password,
    'token': '',
  };
  var headers = {
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
  };
  var response = await session.post(Uri.parse("https://mese.webuntis.com/WebUntis/j_spring_security_check"), headers: headers, body: payload);

  cookies = getCookiesFromHeader(response.headers);
  return response;
}

Future<String> getTimeTableJSONString(String id, int year, int month, int dayy) async {
  DateTime day = DateTime(year, month, dayy);
  DateTime weekDay = day.subtract(Duration(days: day.weekday - 1));
  Map<String, String> headers = {
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
    'Cookie': cookies
    //'Cookie': 'JSESSIONID=E394B47AD7E0BFBBBF245E83BB8F6325;schoolname="_amwtc2NodWxlIGRhcm1zdGFkdA==";schoolname="_amwtc2NodWxlIGRhcm1zdGFkdA==";auth="_c2FtbA=="'
  };
  Map<String, String> params = {
    'elementType': '1',
    'elementId': id,
    'date': DateFormat('yyyy-MM-dd').format(weekDay),
    'formatId': '2',
  };

  http.Response timetable = await session.get(
    Uri.parse('https://mese.webuntis.com/WebUntis/api/public/timetable/weekly/data').replace(queryParameters: params),
    headers: headers,
  );
  return timetable.body;
}

Future<Map<String, dynamic>> getTimeTableJSONDict(String id, int year, int month, int day) async {
  Map<String, dynamic> timetableDict = jsonDecode(await getTimeTableJSONString(id, year, month, day));
  return timetableDict;
}

Future<List<String>> getCoursesList(String id, int year, int month, int day) async {
  Map<String, dynamic> timetableJSONDict = await getTimeTableJSONDict(id, year, month, day);
  List<String> courses = [];
  for (var course in timetableJSONDict["data"]["result"]["data"]["elements"]) {
    if (course["type"] == 3) {
      courses.add(course["longName"]);
    }
  }
  return courses;
}

Future<Map<int, dynamic>> getCoursesIdDict(String id, int year, int month, int day) async {
  Map<String, dynamic> timetableJSONDict = await getTimeTableJSONDict(id, year, month, day);
  Map<int, dynamic> courses = {};
  for (var course in timetableJSONDict["data"]["result"]["data"]["elements"]) {
    if (course["type"] == 3) {
      courses[course["id"]] = course;
    }
  }
  return courses;
}

Future<Map<int, dynamic>> getLocationsIdDict(String id, int year, int month, int day) async {
  Map<String, dynamic> timetableJSONDict = await getTimeTableJSONDict(id, year, month, day);
  Map<int, dynamic> locations = {};
  for (var location in timetableJSONDict["data"]["result"]["data"]["elements"]) {
    if (location["type"] == 4) {
      locations[location["id"]] = location;
    }
  }
  return locations;
}

Future<List<dynamic>> getTimeGridJSONFromServer() async {
  var headers = {
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
    'Cookie': cookies,
  };
  var response = await http.get(
      Uri.parse('https://mese.webuntis.com/WebUntis/api/public/timegrid?schoolyearId=16'),
      headers: headers);
  var timeGridJSON = jsonDecode(response.body)["data"]["rows"];
  print(timeGridJSON.runtimeType);
  return timeGridJSON;
}

int getLessonNumberFromJSON(List<dynamic> timeGridJSON, int startTime) {
  for (int i = 0; i < 12; i++) {
    if (startTime == timeGridJSON[i]["startTime"]) {
      return i;
    }
  }
  throw Exception("the provided time has no associated period");
}

String getWeekdayFromDate(int date) {
  DateTime dateTime = DateTime.parse(date.toString());
  return DateFormat('EEEE').format(dateTime);
}

Future<Map<String, dynamic>> getCustomTimeTableJSON(String id, int year, int month, int day, List<String> courses) async {
  Map<String, dynamic> timetableJSONDict = await getTimeTableJSONDict(id, year, month, day);
  Map<int, dynamic> coursesIdDict = await getCoursesIdDict(id, year, month, day);
  Map<int, dynamic> locationsIdDict = await getLocationsIdDict(id, year, month, day);
  List<dynamic> timeGridJSON = await getTimeGridJSONFromServer();

  Map<String, dynamic> classesJSONDict = {
    "Monday": {},
    "Tuesday": {},
    "Wednesday": {},
    "Thursday": {},
    "Friday": {},
  };

  for (var schoolClass in timetableJSONDict["data"]["result"]["data"]["elementPeriods"][id]) {
    for (var element in schoolClass["elements"]) {
      if (element["type"] == 3 && coursesIdDict[element["id"]]["name"] is String && courses.contains(coursesIdDict[element["id"]]["name"])) {
        String weekday = getWeekdayFromDate(schoolClass["date"]);
        int lesson = getLessonNumberFromJSON(timeGridJSON, schoolClass["startTime"]);

        if (!classesJSONDict[weekday]!.containsKey(lesson)) {
          classesJSONDict[weekday]![lesson] = [];
        }


        Map<String, dynamic> tempLessonDict = {};
        classesJSONDict[weekday]![lesson]!.add(tempLessonDict);
        Map<String, dynamic> lessonDict = classesJSONDict[weekday]![lesson]!.last;

        lessonDict["name"] = coursesIdDict[element["id"]]["name"];
        lessonDict["longName"] = coursesIdDict[element["id"]]["longName"];

        if (element["orgId"] != 0) {
          lessonDict["orgName"] = coursesIdDict[element["orgId"]]["name"];
          lessonDict["orgLongName"] = coursesIdDict[element["orgId"]]["longName"];
        } else {
          lessonDict["orgName"] = "";
          lessonDict["orgLongName"] = "";
        }

        lessonDict["lessonText"] = schoolClass["lessonText"];
        lessonDict["periodText"] = schoolClass["periodText"];
        lessonDict["periodInfo"] = schoolClass["periodInfo"];
        lessonDict["substText"] = schoolClass["substText"];
        lessonDict["cellState"] = schoolClass["cellState"];
        lessonDict["classState"] = element["state"];

        for (var element in schoolClass["elements"]) {
          if (element["type"] == 4) {
            lessonDict["location"] = locationsIdDict[element["id"]]["name"];
            lessonDict["longLocationName"] = locationsIdDict[element["id"]]["longName"];

            if (element["orgId"] != 0) {
              lessonDict["orgLocation"] = locationsIdDict[element["orgId"]]["name"];
              lessonDict["orgLongLocationName"] = locationsIdDict[element["orgId"]]["longName"];
            } else {
              lessonDict["orgLocation"] = "";
              lessonDict["orgLongLocationName"] = "";
            }

            lessonDict["locationState"] = element["state"];
          }
        }
      }
    }
  }

  log(classesJSONDict.toString());
  return classesJSONDict;
}
