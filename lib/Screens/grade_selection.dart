import 'package:flutter/material.dart';
import 'package:vertretungsplan/units_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';

import 'package:flutter/foundation.dart';

class GradeSelection extends StatefulWidget {
  const GradeSelection({super.key});

  @override
  State<GradeSelection> createState() => _GradeSelectionState();
}

class _GradeSelectionState extends State<GradeSelection> {
  late Future<Map<String, int>> gradeMap;
  late Future<SharedPreferences> prefs;

  Future<Map<String, int>> getGradeDict() async {
    SharedPreferences prefsInstance = await prefs;
    if (prefsInstance.getString("username") != null && prefsInstance.getString("password") != null) {
      Response login = await untisLogin(prefsInstance.getString("username")!, prefsInstance.getString("password")!);
      print(login.statusCode);
      if (login.statusCode != 200) {
        if (kDebugMode) {
          print("ATTENTION!!!! NAVIGATED");
        }
        if (context.mounted) Navigator.pushNamed(context, "/login");
      }
    } else {
      if (context.mounted) Navigator.pushNamed(context, "/login");
    }
    return getGradeIdDict();

  }

  @override
  void initState() {
    super.initState();
    prefs = SharedPreferences.getInstance();
    gradeMap = getGradeDict();
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
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: () async {
              SharedPreferences prefsInstance = await prefs;
              prefsInstance.remove('username');
              prefsInstance.remove('password');
              Navigator.pushNamed(context, '/login');
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: gradeMap,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print(snapshot.data);
            return ListView(
              children: List.generate(
                snapshot.data!.length,
                (index) {
                  return GradeElement(snapshot.data!.keys.elementAt(index), prefs, gradeMap);
                },
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

class GradeElement extends StatelessWidget {
  const GradeElement(this.name, this.prefs, this.gradeMap, {super.key});
  final String name;
  final Future<SharedPreferences> prefs;
  final Future<Map<String, int>> gradeMap;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 3, left: 6, right: 6),
        child: Material(
          surfaceTintColor: Theme.of(context).colorScheme.primary,
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              SharedPreferences prefsInstance = await prefs;
              Map<String, int> gradeMapInstance = await gradeMap;
              await prefsInstance.setInt("gradeId", gradeMapInstance[name]!);
              //await prefsInstance.remove("courses");
              if(context.mounted) Navigator.pushNamed(context, "/");
            },
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                name,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        )
        );
  }
}
