import 'package:flutter/material.dart';

void main() {
  runApp(const BuildCalendar());
}

class BuildCalendar extends StatelessWidget {
  const BuildCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Calendar',
      debugShowCheckedModeBanner: false,
      home: Calendar(),
    );
  }
}

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  CalendarState createState() => CalendarState();
}

class CalendarState extends State<Calendar> {
  late int day, month, year;
  late int selectedMonth, selectedYear;
  late List<int> yearsList;

  final List<String> weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  final Map<int, String> monthNames = {
    1: "Январь",
    2: "Февраль",
    3: "Март",
    4: "Апрель",
    5: "Май",
    6: "Июнь",
    7: "Июль",
    8: "Август",
    9: "Сентябрь",
    10: "Октябрь",
    11: "Ноябрь",
    12: "Декабрь",
  };

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    day = now.day;
    month = now.month;
    year = now.year;
    selectedMonth = month;
    selectedYear = year;
    yearsList = List.generate(201, (index) => year - 100 + index);
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int _firstWeekdayOffset() {
    return DateTime(year, month, 1).weekday - 1;
  }

  void _showPopup(BuildContext context) {
    selectedMonth = month;
    selectedYear = year;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выбрать'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                height: 100,
                child: Column(
                  children: [
                    DropdownButton<int>(
                      value: selectedMonth,
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedMonth = newValue!;
                        });
                      },
                      items: monthNames.entries
                          .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                          .toList(),
                    ),
                    DropdownButton<int>(
                      value: selectedYear,
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedYear = newValue!;
                        });
                      },
                      items: yearsList
                          .map((year) => DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  month = selectedMonth;
                  year = selectedYear;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Ок'),
            ),
          ],
        );
      },
    );
  }

  void _changeForward() {
    setState(() {
      if (month >= 12) {
        month = 1;
        year++;
      } else {
        month++;
      }
      selectedMonth = month;
      selectedYear = year;
    });
  }

  void _changeBack() {
    setState(() {
      if (month <= 1) {
        month = 12;
        year--;
      } else {
        month--;
      }
      selectedMonth = month;
      selectedYear = year;
    });
  }

  void _returnCurrentDate() {
    setState(() {
      DateTime now = DateTime.now();
      day = now.day;
      month = now.month;
      year = now.year;
      selectedMonth = month;
      selectedYear = year;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 74, 123, 156),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                IconButton(
                  onPressed: _changeBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showPopup(context),
                  onLongPress: () {
                    _returnCurrentDate();
                  },
                  child: Text(
                    "${monthNames[month]} $year",
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _changeForward,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            shrinkWrap: true,
            children: weekdays
                .map((day) => Center(
                      child: Text(day,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 24)),
                    ))
                .toList(),
          ),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _daysInMonth(year, month) + _firstWeekdayOffset(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7),
              itemBuilder: (context, index) {
                if (index < _firstWeekdayOffset()) {
                  return const SizedBox();
                } else {
                  int day = index - _firstWeekdayOffset() + 1;
                  bool isToday = day == this.day &&
                      month == DateTime.now().month &&
                      year == DateTime.now().year;

                  return Center(
                    child: GestureDetector(
                      onTap: () {
                        print("Показал задачи для дня $day");
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: isToday
                            ? const BoxDecoration(
                                color: Color.fromARGB(255, 74, 123, 156),
                                shape: BoxShape.circle,
                              )
                            : null,
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 22,
                            color: isToday
                                ? Colors.white
                                : const Color.fromARGB(255, 63, 63, 63),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
