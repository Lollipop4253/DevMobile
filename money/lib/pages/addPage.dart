import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class AddMoney extends StatefulWidget {
  const AddMoney({super.key});

  @override
  State<AddMoney> createState() => _AddMoneyState();
}

class _AddMoneyState extends State<AddMoney> {
  late DateTime currentDate;
  late String selectedDate;
  List<String> categoryList = [];
  String category = "Без категории";
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _moneyController = TextEditingController();

  @override
  void initState() {
    currentDate = DateTime.now();
    selectedDate = DateFormat('dd-MM-yyyy').format(currentDate);
    super.initState();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateFormat('dd-MM-yyyy').parse(selectedDate),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }

  void _showDialog(BuildContext context) {
    final TextEditingController addCategoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Добавить категорию'),
          content: TextField(
            controller: addCategoryController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Введите название категории',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                _addCategory(addCategoryController.text);
                Navigator.pop(context);
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  void _addCategory(String newCategory) {
    final myBox = Hive.box("mybox");

    if (!categoryList.contains(newCategory)) {
      categoryList.add(newCategory);
      myBox.put("categoryList", categoryList);
    } else {
      final snackBar = SnackBar(
        content: const Text('Категория уже существует'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'ОК',
          onPressed: () {
            _showDialog(context);
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Color _generateRandomColor() {
    Random random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1.0,
    );
  }

  Future<void> _addToDatabase() async {
    final myBox = await Hive.openBox("mybox");
    // myBox.put("money", {});
    // return;
    var db = myBox.get("money", defaultValue: {}) as Map<dynamic, dynamic>;

    DateTime date = DateFormat('dd-MM-yyyy').parse(selectedDate);
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final mode = args["mode"];
    int modifier = mode ? 1 : -1;

    db[date.year] ??= {};
    db[date.year][date.month] ??= {};
    db[date.year][date.month][date.day] ??= {};
    db[date.year][date.month][date.day][category] ??= {};

    if (_titleController.text.isNotEmpty && _moneyController.text.isNotEmpty) {
      double value = double.parse(_moneyController.text) * modifier;

      db[date.year][date.month][date.day][category][_titleController.text] =
          value;

      db[date.year][date.month][date.day][category]["all"] =
          (db[date.year][date.month][date.day][category]["all"] ?? 0) + value;
      db[date.year][date.month][date.day][category]["color"] =
          _generateRandomColor();

      db[date.year][date.month][date.day]["all"] =
          (db[date.year][date.month][date.day]["all"] ?? 0) + value;
      db[date.year][date.month][date.day]["color"] = _generateRandomColor();

      db[date.year][date.month]["all"] =
          (db[date.year][date.month]["all"] ?? 0) + value;
      db[date.year][date.month]["color"] = _generateRandomColor();

      db[date.year]["all"] = (db[date.year]["all"] ?? 0) + value;
      db[date.year]["color"] = _generateRandomColor();

      db["all"] = (db["all"] ?? 0) + value;
      db["color"] = _generateRandomColor();

      await myBox.put("money", db);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    categoryList = args["categoryList"];

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 238, 238, 238),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 71, 138, 73),
        title: Text(
          args["mode"] ? "Добавление доходов" : "Добавление расходов",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 71, 138, 73),
              ),
              child: Text(selectedDate, style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: category,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    category = newValue;
                  });
                }
              },
              dropdownColor: const Color.fromARGB(255, 71, 138, 73),
              items: categoryList.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              isExpanded: true,
            ),
            IconButton(
              onPressed: () => _showDialog(context),
              icon: const Icon(Icons.add, color: Colors.green),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Введите название',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _moneyController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Введите число',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _addToDatabase();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 71, 138, 73),
              ),
              child: const Text('Добавить', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}