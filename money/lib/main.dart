import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money/pages/addPage.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ColorAdapter());
  await Hive.openBox('mybox');

  initializeDateFormatting('ru_RU', null).then((_) => runApp(const MoneyApp()));
}

class ColorAdapter extends TypeAdapter<Color> {
  @override
  final typeId = 1;

  @override
  Color read(BinaryReader reader) {
    int colorValue = reader.readInt();
    return Color(colorValue);
  }

  @override
  void write(BinaryWriter writer, Color obj) {
    writer.writeInt(obj.value);
  }
}

class MoneyApp extends StatelessWidget {
  const MoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
      ),
      title: 'Анализ финансов',
      routes: {
        '/home': (context) => const Home(),
        '/add': (context) => const AddMoney(),
        // '/addCategory': (context) => const AddCategory(),
        // '/addOperation': (context) => const AddOperation(),
        // '/Operation': (context) => const Operation()
      },
      initialRoute: '/home',
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final myBox = Hive.box('mybox');
  late List<String> categoryList;
  late var tiles = myBox.get("money", defaultValue: {});
  int type = 1;
  DateTime now = DateTime.now();

  ListView _getInfo() {
    int modifier = 0;
    var entry;
    tiles = myBox.get("money", defaultValue: {});
    print(tiles);

    if (type == 2) {
      tiles = tiles[now.year];
    } else if (type == 3) {
      tiles = tiles[now.year][now.month];
    } else if (type == 4) {
      tiles = tiles[now.year][now.month][now.day];
    }

    return ListView.builder(
      itemCount: tiles.length - 2,
      itemBuilder: (context, index) {
        entry = tiles.entries.elementAt(index + modifier);
        if (entry.key.toString() == "all") {
          modifier = 1;
          entry = tiles.entries.elementAt(index + modifier);
          if (entry.key.toString() == "color") {
            modifier = 2;
            entry = tiles.entries.elementAt(index + modifier);
          }
        }
        return Card(
          color: entry.value["color"] as Color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.only(bottom: 5),
          elevation: 3,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              entry.key.toString(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white),
            ),
            subtitle: Text(
              entry.value["all"].toString(),
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _pieSections() {
    tiles = myBox.get("money", defaultValue: {});
    double allMoney = tiles["all"];

    if (type == 2) {
      tiles = tiles[now.year];
      allMoney = tiles["all"];
    } else if (type == 3) {
      tiles = tiles[now.year][now.month];
      allMoney = tiles["all"];
    } else if (type == 4) {
      tiles = tiles[now.year][now.month][now.day];
      allMoney = tiles["all"];
    }

    List<PieChartSectionData> result = [];

    tiles.forEach((key, value) {
      if (key != "all" && key != "color" && value is Map) {
        result.add(
          PieChartSectionData(
            color: value["color"],
            value: value["all"].abs() / allMoney.abs(),
            title: key.toString(),
            titleStyle: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            radius: 60,
          ),
        );
      }
    });

    return result;
  }

  @override
  void initState() {
    // myBox.put("categoryList", ["Без категории", "Учеба", "Красота", "Продукты"]);
    categoryList = myBox.get("categoryList",
        defaultValue: ["Без категории", "Учеба", "Красота", "Продукты"]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 238, 238, 238),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          "MyMoney",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<int>(
            onSelected: (int value) {
              if (value == 1) {
                Navigator.pushNamed(context, '/add', arguments: {
                  'mode': true,
                  "categoryList": categoryList,
                }).then((result) {
                  if (result == true) {
                    setState(() {
                      tiles = myBox.get("money", defaultValue: {});
                    });
                  }
                });
              } else if (value == 2) {
                Navigator.pushNamed(context, '/add', arguments: {
                  'mode': false,
                  "categoryList": categoryList,
                }).then((result) {
                  if (result == true) {
                    setState(() {
                      tiles = myBox.get("money", defaultValue: {});
                    });
                  }
                });
              }
            },
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Доходы'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Расходы'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ToggleButtons(
              borderRadius: BorderRadius.circular(10),
              selectedColor: Colors.white,
              fillColor: const Color(0xFF4CAF50),
              color: Colors.black,
              isSelected: [type == 1, type == 2, type == 3, type == 4],
              onPressed: (int index) {
                setState(() {
                  type = index + 1;
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Все время"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Год"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Месяц"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("День"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: tiles.isEmpty
                  ? const Center(
                      child: Text(
                        "Нет данных",
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : PieChart(
                      PieChartData(
                        sections: _pieSections(),
                        sectionsSpace: 4,
                        centerSpaceRadius: 50,
                        startDegreeOffset: 180,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: tiles.isEmpty
                  ? const Center(
                      child: Text(
                        "Нет данных",
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : _getInfo(),
            )
          ],
        ),
      ),
    );
  }
}
