import 'package:flutter/material.dart';
import 'package:vertretungsplan/units_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  late Future<List<String>> classesList;
  late Future<SharedPreferences> prefs;
  late SharedPreferences prefsInstance;
  late List<String>? selectedCoursesList;

  Future<List<String>> getClassesListAndInitPrefs(String username, String password, int pageIndex) async {
    await untisLogin(username, password);
    prefsInstance = await prefs;
    selectedCoursesList = prefsInstance.getStringList('courses');
    selectedCoursesList ??= [];
    DateTime requestWeek = DateTime.now().add(Duration(days: 7 * (pageIndex - 100)));
    return getCoursesList("845", requestWeek.year, requestWeek.month, requestWeek.day);
  }

  @override
  void initState() {
    super.initState();
    prefs = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    final int pageIndex = ModalRoute.of(context)!.settings.arguments as int;
    classesList = getClassesListAndInitPrefs("LiO-Lernende", "Schueler.2021", pageIndex);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Vertretungsplan LIO",
          style: Theme.of(context).primaryTextTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: classesList,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.only(top: 3, bottom: 3),
              child: ListView(
                children: [
                  for (String course in snapshot.data!) CheckBoxElement(course, selectedCoursesList!, prefsInstance),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.data}",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            );
          } else {
            return Center(
              child: Text(
                "Loading",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            );
          }
        },
      ),
    );
  }
}

class CheckBoxElement extends StatefulWidget {
  CheckBoxElement(this.title, this.selectedCoursesList, this.prefsInstance, {super.key});

  final List<String> selectedCoursesList;
  final SharedPreferences prefsInstance;
  final String title;

  @override
  State<CheckBoxElement> createState() => _CheckBoxElementState();
}

class _CheckBoxElementState extends State<CheckBoxElement> {

  late bool checked;

  void initState() {
    super.initState();
    if(widget.selectedCoursesList.contains(widget.title)){
      checked = true;
    }
    else{
      checked = false;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 3, bottom: 3, left: 6, right: 6),
      child: Material(
        surfaceTintColor: Theme.of(context).colorScheme.primary,
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: CheckboxListTile(
            title: Text(widget.title, style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.primary)),
            value: checked,
            onChanged: (value) async {
              if(value!){
                widget.selectedCoursesList.add(widget.title);
                await widget.prefsInstance.setStringList('courses', widget.selectedCoursesList);
              }
              else{
                widget.selectedCoursesList.remove(widget.title);
                await widget.prefsInstance.setStringList('courses', widget.selectedCoursesList);
              }
              setState(() {
                  checked = value;
                },
              );
            }),
      ),
    );
  }
}
