import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vertretungsplan/units_api.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  PageController _pageController = PageController(initialPage: 100);
  late Future<List<dynamic>> timeGrid;
  bool loggedIn = false;
  late Future<SharedPreferences> prefs;

  int globalPageIndex = 0;

  Future<List<dynamic>> getTimeGrid() async {
    // ATTENTION -- maybe not a good solution because login might expire
    if (loggedIn == false) {
      SharedPreferences prefsInstance = await prefs;
      if (prefsInstance.getString("username") != null && prefsInstance.getString("password") != null) {
        Response login = await untisLogin(prefsInstance.getString("username")!, prefsInstance.getString("password")!);
        if (login.statusCode != 200) {
          Navigator.pushNamed(context, "/login");
        }
      } else {
        Navigator.pushNamed(context, "/login");
      }
      loggedIn = true;
    }
    return getTimeGridJSONFromServer();
  }

  @override
  void initState() {
    super.initState();
    prefs = SharedPreferences.getInstance();
    timeGrid = getTimeGrid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Vertretungsplan LIO",
          style: Theme.of(context).primaryTextTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/selectionScreen', arguments: globalPageIndex);
            },
          )
        ]
      ),
      
      body: Padding(
        padding: EdgeInsets.only(top: 4, bottom: 4, right: 4),
        child: Row(
          //mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FutureBuilder(
              future: timeGrid,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return PeriodColumn(snapshot.data!);
                } else if (snapshot.hasError) {
                  return FittedBox(
                    child: Center(
                      child: Text(
                        "Error: ${snapshot.data}",
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  );
                } else {
                  return FittedBox(
                    child: Center(
                      child: Text(
                        "Loading",
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 10),
                      ),
                    ),
                  );
                }
              },
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  globalPageIndex = index;
                  return Column(
                    //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DateRow(index),
                      ClassRow(index, prefs),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassRow extends StatefulWidget {
  ClassRow(this.pageIndex, this.prefs, {super.key});
  final Future<SharedPreferences> prefs;
  final int pageIndex;
  final List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  @override
  State<ClassRow> createState() => _ClassRowState();
}

class _ClassRowState extends State<ClassRow> {
  late Future<Map<String, dynamic>> timetable;

  // Get the timetable dictionary from the untis api using the index to generate a date to allow for multiple weeks
  Future<Map<String, dynamic>> getTimetable() async {

    SharedPreferences prefsInstance = await widget.prefs;

    late Map<String, dynamic> timetable;

    if(prefsInstance.getString("username") != null && prefsInstance.getString("password") != null){
      Response login = await untisLogin(prefsInstance.getString("username")!, prefsInstance.getString("password")!);
      if(login.statusCode != 200){
        Navigator.pushNamed(context, "/login");
      }
    }
    else{
      Navigator.pushNamed(context, "/login");
    }
    DateTime requestWeek = DateTime.now().add(Duration(days: 7 * (widget.pageIndex - 100)));
    //ATTENTION -- list of courses still needs updating, not automated yet !!!!!!!!!!!!!!!!!!!! IN PROGRESS
    List<String>? courses = prefsInstance.getStringList('courses');
    
    if(courses != null){
    timetable =
        await getCustomTimeTableDict("845", requestWeek.year, requestWeek.month, requestWeek.day, courses);
    }
    else{
      timetable = await getCustomTimeTableDict("845", requestWeek.year, requestWeek.month, requestWeek.day, []);
    }
    return timetable;
  }

  // Returns the dictionary of lessons of a specific weekday. The weekday is specified by the index where 0 = Monday and 4 = Friday
  Map<dynamic, dynamic> getColumnDict(Map<String, dynamic> timetableDict, int day) {
    return timetableDict[widget.weekdays[day]];
  }

  @override
  void initState() {
    super.initState();
    timetable = getTimetable();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: timetable,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Expanded(
            child: Row(
              children: List.generate(5, (dayIndex) => ClassColumn(getColumnDict(snapshot.data!, dayIndex))),
            ),
          );
        } else if (snapshot.hasError) {
          return Expanded(
            child: Center(
              child: Text(
                "Error: ${snapshot.data}",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        } else {
          return Expanded(
            child: Center(
              child: Text(
                "Loading",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          );
        }
      },
    );
  }
}

class ClassColumn extends StatelessWidget {
  ClassColumn(this.classesDict, {super.key});
  final Map<dynamic, dynamic> classesDict;

  List<dynamic> getClassesList(Map<dynamic, dynamic> localClassesDict) {
    List<dynamic> classList = List.generate(
      12,
      (index) {
        if (localClassesDict.containsKey(index)) {
          return localClassesDict[index];
        } else {
          List<dynamic> nullList = [
            {"name": "null"}
          ];
          return nullList;
        }
      },
    );
    return classList;
  }

  List<int> getFlexList(List classesList) {
    List<int> flexList = List.filled(12, 1);
    for (int i = 1; i < classesList.length; i++) {
      if (classesList[i][0]["name"] != "null") {
        if (mapEquals(classesList[i][0], classesList[i - 1][0])) {
          flexList[i] = flexList[i - 1] + 1;
          flexList[i - 1] = -1;
        }
      }
    }
    print(classesList);
    print(flexList);
    return flexList;
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> classesList = getClassesList(classesDict);
    List<int> flexList = getFlexList(classesList);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(12, (index){
          if(flexList[index] != -1){
          return Class(classesList[index][0], flexList[index]);
          }
          else{
            return SizedBox.shrink();
          }
          }
        ),
      ),
    );
  }
}

class Class extends StatelessWidget {
  const Class(this.singleClassDict, this.flex, {super.key});
  final Map<String, dynamic> singleClassDict;
  final int flex;

  @override
  Widget build(BuildContext context) {
    if (singleClassDict["name"] != "null") {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: EdgeInsets.only(top: 2, bottom: 2, left: 2, right: 2),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              // child: Material(
              //   color: Theme.of(context).colorScheme.surfaceTint,
              //   surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
              //   elevation: 100,
              child: ColoredBox(
                color: singleClassDict["cellState"] == "CANCEL"
                    ? Theme.of(context).colorScheme.error
                    : singleClassDict["cellState"] == "SUBSTITUTION"
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //FittedBox(
                        //child:
                        Text(
                          singleClassDict["name"],
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                        ),
                        // Text(
                        //   singleClassDict["longName"],
                        //   style:
                        //       Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.primaryContainer, fontSize: 7.5),
                        // ),
                        //),
                        //FittedBox(
                        //child:

                        //),
                        //FittedBox(
                        //child:
                        Column(
                          children: [
                            singleClassDict["locationState"] == "SUBSTITUTED" ? Text(singleClassDict["orgLocation"],
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.inversePrimary, decorationThickness: 3, decorationColor:  Theme.of(context).colorScheme.inversePrimary, decoration: TextDecoration.lineThrough)) : SizedBox.shrink(),
                            Text(
                              (singleClassDict["location"] == null) ? "" : singleClassDict["location"],
                              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                            ),
                          ],
                        ),
                        //),
                      ],
                    ),
                  ),
                ),
              )),
        ),
      );
    } else {
      return Spacer();
    }
  }
}

class PeriodColumn extends StatelessWidget {
  const PeriodColumn(this.timeGridJSON, {super.key});
  final List<dynamic> timeGridJSON;

  List<Widget> getPeriodColumnWidgets(List<dynamic> timeGrid) {
    return List.generate(12, (index) {
      int period = timeGrid[index]["period"];

      int startTimeInt = timeGrid[index]["startTime"];
      String startTimeStr = startTimeInt.toString().padLeft(4, '0');
      String startTimehours = startTimeStr.substring(0, 2);
      String startTimeMinutes = startTimeStr.substring(2);
      String startTimeString = '$startTimehours:$startTimeMinutes';

      int endTimeInt = timeGrid[index]["endTime"];
      String endTimeStr = endTimeInt.toString().padLeft(4, '0');
      String endTimehours = endTimeStr.substring(0, 2);
      String endTimeMinutes = endTimeStr.substring(2);
      String endTimeString = '$endTimehours:$endTimeMinutes';

      DateTime now = DateTime.now();

      if (index < 11) {
        int nextStartTimeInt = timeGrid[index + 1]["startTime"];
        String nextStartTimeStr = nextStartTimeInt.toString().padLeft(4, '0');
        String nextStartTimehours = nextStartTimeStr.substring(0, 2);
        String nextStartTimeMinutes = nextStartTimeStr.substring(2);

        if (now.difference(now.copyWith(hour: int.parse(startTimehours), minute: int.parse(startTimeMinutes))) >= Duration.zero &&
            now.difference(now.copyWith(hour: int.parse(nextStartTimehours), minute: int.parse(nextStartTimeMinutes))) < Duration.zero) {
          return (PeriodNumber(period, startTimeString, endTimeString, true));
        } else {
          return (PeriodNumber(period, startTimeString, endTimeString, false));
        }
      } else if (now.difference(now.copyWith(hour: int.parse(startTimehours), minute: int.parse(startTimeMinutes))) >= Duration.zero &&
                 now.difference(now.copyWith(hour: int.parse(endTimehours), minute: int.parse(endTimeMinutes))) < Duration.zero) {
        return (PeriodNumber(period, startTimeString, endTimeString, true));
      } else {
        return (PeriodNumber(period, startTimeString, endTimeString, false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeriodSpacer(),
        ...getPeriodColumnWidgets(timeGridJSON),
        //for (int i = 0; i < 12; i++) i == 3 ? PeriodNumber(1, "7:50", "8:35", true) : PeriodNumber(1, "7:50", "8:35", false)
      ],
    );
  }
}

class PeriodSpacer extends StatelessWidget {
  const PeriodSpacer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text("ho",
                  style: Theme.of(context).primaryTextTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1,
                        color: Theme.of(context).colorScheme.surface,
                      )),
            ),
            Text(
              "idk",
              style: Theme.of(context).primaryTextTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1,
                    color: Theme.of(context).colorScheme.surface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class PeriodNumber extends StatelessWidget {
  const PeriodNumber(this.number, this.startTime, this.endTime, this.active, {super.key});

  final int number;
  final String startTime;
  final String endTime;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(top: 4, bottom: 4, left: 4, right: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: ColoredBox(
            color: active ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      startTime,
                      style: active
                          ? Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.outlineVariant, height: 1)
                          : Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.outline, height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        number.toString(),
                        style: active
                            ? Theme.of(context).primaryTextTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold, height: 1)
                            : Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, height: 1),
                      ),
                    ),
                    Text(
                      endTime,
                      style: active
                          ? Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.outlineVariant, height: 1)
                          : Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.outline, height: 1),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DateRow extends StatelessWidget {
  const DateRow(this.index, {super.key});
  final int index;

  List<Widget> getDateRowWidgets(int weekIndex) {
    DateTime today = DateTime.now();
    DateTime week = today.add(Duration(days: 7 * (weekIndex - 100)));
    DateTime weekMonday = week.subtract(Duration(days: week.weekday - 1));
    List<DateTime> weekDays = List.generate(5, (index) {
      return weekMonday.add(Duration(days: index));
    });
    return List.generate(5, (index) {
      if (today == weekDays[index]) {
        return Date(weekDays[index].day.toString(), DateFormat("E").format(weekDays[index]), true);
      } else {
        return Date(weekDays[index].day.toString(), DateFormat("E").format(weekDays[index]), false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: getDateRowWidgets(index),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    );
  }
}

class Date extends StatelessWidget {
  Date(this.date, this.weekday, this.active, {super.key});
  final String weekday;
  final String date;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: ColoredBox(
            color: active ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      date,
                      style: active
                          ? Theme.of(context).primaryTextTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1,
                              )
                          : Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                    ),
                  ),
                  Text(
                    weekday,
                    style: active
                        ? Theme.of(context).primaryTextTheme.labelMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1,
                            )
                        : Theme.of(context)
                            .textTheme
                            .labelMedium!
                            .copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, height: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
