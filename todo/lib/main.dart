import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BuildToDo());
}

class BuildToDo extends StatelessWidget {
  const BuildToDo({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ToDo',
      debugShowCheckedModeBanner: false,
      home: ToDo(),
    );
  }
}

class ToDo extends StatefulWidget {
  const ToDo({super.key});

  @override
  ToDoState createState() => ToDoState();
}

class ToDoState extends State<ToDo> {
  Map<String, Map<String, bool>> user_tasks = {};
  Map<String, Map<String, bool>> viewTasks = {};
  Color sortColor = Colors.white;
  bool sortedValue = true;

  void _showTaskEditor(BuildContext context,
      {String? existingTitle, String? existingBody}) {
    String? title = existingTitle;
    String? body = existingBody;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(existingTitle == null
              ? 'Добавить задачу'
              : 'Редактировать задачу'),
          content: SizedBox(
            height: 200,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Заголовок"),
                  controller: TextEditingController(text: existingTitle),
                  onChanged: (value) {
                    title = value;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: "Описание"),
                  controller: TextEditingController(text: existingBody),
                  onChanged: (value) {
                    body = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (title != null && body != null) {
                  if (existingTitle != null) {
                    _editTask(existingTitle, title!, body!);
                  } else {
                    _addTask(title!, body!);
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text('Ок'),
            ),
          ],
        );
      },
    );
  }

  void _addTask(String title, String body) {
    setState(() {
      user_tasks[title] = {body: false};
      viewTasks = Map.from(user_tasks);
      _saveTasks(user_tasks);
    });
  }

  void _editTask(String oldTitle, String newTitle, String newBody) {
    setState(() {
      bool? status = user_tasks[oldTitle]?.values.first;

      if (oldTitle != newTitle) {
        final updatedTasks = Map<String, Map<String, bool>>.from(user_tasks);
        updatedTasks.remove(oldTitle);
        updatedTasks[newTitle] = {newBody: status ?? false};

        user_tasks = updatedTasks;
      } else {
        user_tasks[oldTitle] = {newBody: status ?? false};
      }

      viewTasks = Map.from(user_tasks);

      _saveTasks(user_tasks);
    });
  }

  Future<void> _saveTasks(Map<String, Map<String, bool>> tasks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(tasks);
    await prefs.setString('UserTasks', jsonString);
    print("Saved $tasks");
  }

  Future<void> _loadTasks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('UserTasks');

    if (jsonString != null) {
      final Map<String, dynamic> decodedMap = jsonDecode(jsonString);

      final Map<String, Map<String, bool>> finalMap = Map.fromEntries(
        decodedMap.entries.map((outerEntry) {
          final innerMap = outerEntry.value as Map<String, dynamic>;

          final convertedInnerMap = Map<String, bool>.fromEntries(
            innerMap.entries.map((innerEntry) {
              return MapEntry(innerEntry.key, innerEntry.value == true);
            }),
          );

          return MapEntry(outerEntry.key, convertedInnerMap);
        }),
      );

      setState(() {
        user_tasks = finalMap;
        viewTasks = finalMap;
        print("Loaded $user_tasks");
      });
    }
  }

  void _sortedColor() {
    setState(() {
      if (sortColor == Colors.white) {
        sortColor = Colors.green;
        sortedValue = true;
      } else if (sortColor == Colors.green) {
        sortColor = Colors.red;
        sortedValue = false;
      } else {
        sortColor = Colors.white;
        return;
      }
    });
  }

  void _sorted(bool sortedValue) {
    viewTasks = Map.fromEntries(
      user_tasks.entries.map((outerEntry) {
        final filteredInnerMap = Map.fromEntries(
          outerEntry.value.entries
              .where((innerEntry) => innerEntry.value == sortedValue),
        );

        return MapEntry(outerEntry.key, filteredInnerMap);
      }).where((outerEntry) => outerEntry.value.isNotEmpty),
    );

    viewTasks.removeWhere((key, value) => value.isEmpty);
  }

  void _deleteTask(String title) {
    setState(() {
      user_tasks.remove(title);
      viewTasks = Map.from(user_tasks);
      _saveTasks(user_tasks);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              "ToDo",
              style: TextStyle(color: Colors.white),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                _showTaskEditor(context);
              },
              icon: const Icon(
                Icons.add_outlined,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () {
                _sortedColor();
                if (sortColor == Colors.white) {
                  viewTasks = user_tasks;
                } else {
                  _sorted(sortedValue);
                }
              },
              icon: const Icon(
                Icons.sort,
              ),
              color: sortColor,
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  user_tasks.clear();
                  viewTasks.clear();
                  _saveTasks(user_tasks);
                });
              },
              icon: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 118, 212, 152),
      ),
      body: ListView(
        children: viewTasks.entries.map((entry) {
          return Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
            child: ExpansionTile(
              title: Text(
                entry.key,
                style: const TextStyle(color: Colors.black, fontSize: 18),
              ),
              children: entry.value.entries.map((subEntry) {
                return ListTile(
                  title: Text(
                    subEntry.key,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: subEntry.value,
                        onChanged: (bool? newValue) {
                          setState(() {
                            user_tasks[entry.key] =
                                Map.from(user_tasks[entry.key]!);
                            user_tasks[entry.key]![subEntry.key] = newValue!;
                            viewTasks = Map.from(user_tasks);
                            if (sortColor != Colors.white) {
                              _sorted(sortedValue);
                            }
                            _saveTasks(user_tasks);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showTaskEditor(
                            context,
                            existingTitle: entry.key,
                            existingBody: subEntry.key,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteTask(entry.key);
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
