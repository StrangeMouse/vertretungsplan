import 'package:flutter/material.dart';
import 'package:vertretungsplan/units_api.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
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
      ),
      body: Padding(
        padding: EdgeInsets.all(4),
        child: Column(
          children: [
            DateRow(),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [PeriodColumn(), for (int i = 0; i < 5; i++) ClassColumn()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassColumn extends StatelessWidget {
  const ClassColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          for (int i = 0; i < 12; i++) Class("M1", "LK, Mathe TUT", "L919"),
        ],
      ),
    );
  }
}

class Class extends StatelessWidget {
  const Class(this.name, this.longName, this.location, {super.key});

  final String name;
  final String longName;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(2),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            // child: Material(
            //   color: Theme.of(context).colorScheme.surfaceTint,
            //   surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
            //   elevation: 100,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.primary,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FittedBox(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                    FittedBox(
                      child: Text(
                        longName,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.primaryContainer),
                      ),
                    ),
                    FittedBox(
                      child: Text(
                        location,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ),
    );
  }
}

class PeriodColumn extends StatelessWidget {
  const PeriodColumn({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (int i = 0; i < 12; i++) i == 3 ? PeriodNumber(1, "7:50", "8:35", true) : PeriodNumber(1, "7:50", "8:35", false)],
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
        padding: EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: ColoredBox(
            color: active ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: EdgeInsets.only(left: 4, right: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    startTime,
                    style: active
                        ? Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.outlineVariant, height: 1)
                        : Theme.of(context).textTheme.labelSmall!.copyWith(color: Theme.of(context).colorScheme.outline, height: 1),
                  ),
                  Text(
                    number.toString(),
                    style: active
                        ? Theme.of(context).primaryTextTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold, height: 1)
                        : Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, height: 1),
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
    );
  }
}

class DateRow extends StatelessWidget {
  const DateRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Spacer(
          flex: 2,
        ),
        for (int i = 0; i < 5; i++) i == 3 ? Date("3", "Mon", true) : Date("4", "Tue", false)
      ],
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
      flex: 3,
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
