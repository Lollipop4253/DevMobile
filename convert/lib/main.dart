import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'convertValue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Carousel extends StatefulWidget {
  @override
  CarouselState createState() => CarouselState();
}

class CarouselState extends State<Carousel> with WidgetsBindingObserver {
  final PageController _controller = PageController(
    viewportFraction: 0.3,
  );
  int currentIndex = 0;
  String result = "0";
  String? selectedItem1;
  String? selectedItem2;

  final TextEditingController _textController =
      TextEditingController(text: "0");
  bool _isKeyboardVisible = false;

  final List<Widget> buttonLabels = [
    const FaIcon(
      FontAwesomeIcons.weightHanging,
      color: Color.fromARGB(255, 255, 255, 255),
      size: 20,
    ),
    const FaIcon(
      FontAwesomeIcons.temperatureLow,
      color: Color.fromARGB(255, 255, 255, 255),
      size: 20,
    ),
    const FaIcon(
      FontAwesomeIcons.rubleSign,
      color: Color.fromARGB(255, 255, 255, 255),
      size: 20,
    ),
    const FaIcon(
      FontAwesomeIcons.clock,
      color: Color.fromARGB(255, 255, 255, 255),
      size: 20,
    ),
    const FaIcon(
      FontAwesomeIcons.ruler,
      color: Color.fromARGB(255, 255, 255, 255),
      size: 20,
    ),
  ];

  final List<String> categoryName = [
    'Вес',
    'Температура',
    'Деньги',
    'Время',
    'Расстояние',
  ];

  final List<List<String>> categoryValues = [
    ["Килограмм", "Грамм", "Центнер", "Тонна"],
    ["Цельсий", "Кельвин", "Фаренгейт"],
    ["Доллары", "Рубли", "Евро", "Йены"],
    ["Часы", "Минуты", "Секунды", "Дни", "Недели", "Месяца", "Года"],
    [
      "Метры",
      "Миллиметры",
      "Сантиметры",
      "Дециметры",
      "Километры",
      "Миля (сухопутная)",
      "Миля (морская)"
    ],
  ];

  Map<String, Map<String, double>> moneyConversions = {};

  @override
  void initState() {
    super.initState();
    _updateSelectedItems();
    WidgetsBinding.instance.addObserver(this);
    _loadExchangeRates().then((rates) {
      if (rates != null) {
        moneyConversions = {
          "Рубли": {
            "Доллары": 1 / rates["RUB"] * rates["USD"],
            "Евро": 1 / rates["RUB"],
            "Йены": 1 / rates["RUB"] * rates["JPY"]
          },
          "Доллары": {
            "Рубли": 1 / rates["USD"] * rates["RUB"],
            "Евро": 1 / rates["USD"],
            "Йены": 1 / rates["USD"] * rates["JPY"]
          },
          "Евро": {
            "Рубли": rates["RUB"],
            "Доллары": rates["USD"],
            "Йены": rates["JPY"]
          },
          "Йены": {
            "Рубли": 1 / rates["JPY"] * rates["RUB"],
            "Доллары": 1 / rates["JPY"] * rates["USD"],
            "Евро": 1 / rates["JPY"]
          },
        };
        print("Loaded rates: $rates");
      } else {
        _fetchExchangeRates();
      }
    });
  }

  Future<void> _fetchExchangeRates() async {
    var response = await http.get(Uri.parse(
        'https://data.fixer.io/api/latest?access_key=4b9619d44f2a59439f49b6cfb1ab0976&format=1'));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success']) {
        Map<String, dynamic> rates = jsonResponse['rates'];
        await _saveExchangeRates(rates);
        print("Fetched and saved exchange rates: $rates");
      }
    } else {
      throw Exception('Failed to load exchange rates');
    }
  }

  Future<void> _saveExchangeRates(Map<String, dynamic> rates) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(rates);
    await prefs.setString('exchangeRates', jsonString);
  }

  Future<Map<String, dynamic>?> _loadExchangeRates() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('exchangeRates');
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }

  void _updateSelectedItems() {
    setState(() {
      selectedItem1 = categoryValues[currentIndex][0];
      selectedItem2 = categoryValues[currentIndex][1];
      _textController.text = "0";
      _getResult(categoryName[currentIndex], categoryValues[currentIndex][0],
          categoryValues[currentIndex][1], double.parse(_textController.text));
    });
  }

  void _swapSelectedItems() {
    setState(() {
      var temp = selectedItem1;
      selectedItem1 = selectedItem2;
      selectedItem2 = temp;

      temp = result;
      result = _textController.text;
      _textController.text = temp;

      try {
        _getResult(categoryName[currentIndex], selectedItem1!, selectedItem2!,
            double.parse(_textController.text));
      } catch (e) {}
    });
  }

  double _convertTemperature(String fromUnit, String toUnit, double value) {
    if (fromUnit == toUnit) return value;
    return temperatureConversions[fromUnit]![toUnit]!(value);
  }

  void _getResult(
      String category, String fromUnit, String toUnit, double value) {
    switch (category) {
      case "Вес":
        result = (value * (weightConversions[fromUnit]?[toUnit] ?? 1))
            .toStringAsFixed(2)
            .toString();
        break;
      case "Температура":
        result = _convertTemperature(fromUnit, toUnit, value)
            .toStringAsFixed(2)
            .toString();
        break;
      case "Деньги":
        result = (value * (moneyConversions[fromUnit]?[toUnit] ?? 1))
            .toStringAsFixed(2)
            .toString();
        break;
      case "Время":
        result = (value * (timeConversions[fromUnit]?[toUnit] ?? 1))
            .toStringAsFixed(2)
            .toString();
        break;
      case "Расстояние":
        result = (value * (distanceConversions[fromUnit]?[toUnit] ?? 1))
            .toStringAsFixed(2)
            .toString();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          categoryName[currentIndex],
          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        ),
        backgroundColor: const Color.fromARGB(255, 210, 183, 183),
      ),
      body: Column(
        children: [
          Expanded(
              flex: 5,
              child: Column(
                children: [
                  if (currentIndex == 2)
                    Container(
                      height: 50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            "Обновить курсы валют ->",
                            style: TextStyle(
                                fontSize: 20,
                                color: Color.fromARGB(255, 74, 72, 72)),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          ElevatedButton(
                              onPressed: () {
                                _fetchExchangeRates();
                              },
                              child: const FaIcon(
                                FontAwesomeIcons.rotateRight,
                                color: Color.fromARGB(255, 143, 143, 143),
                                size: 20,
                              )),
                          const SizedBox(
                            width: 5,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(
                    height: 100,
                  ),
                  if (currentIndex != 2)
                    Container(
                      height: 50,
                    ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 5,
                        ),
                        Container(
                          width: 200,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 251, 233, 233),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: selectedItem1,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedItem1 = newValue;
                                _getResult(
                                    categoryName[currentIndex],
                                    selectedItem1!,
                                    selectedItem2!,
                                    double.parse(_textController.text));
                              });
                            },
                            dropdownColor: Color.fromARGB(255, 210, 183, 183),
                            items: categoryValues[currentIndex]
                                .map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            icon: const SizedBox.shrink(),
                            alignment: Alignment.center,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                          width: 200,
                          child: TextField(
                            controller: _textController,
                            onChanged: (value) {
                              setState(() {
                                try {
                                  _getResult(
                                      categoryName[currentIndex],
                                      selectedItem1!,
                                      selectedItem2!,
                                      double.parse(value));
                                } catch (e) {
                                  ;
                                }
                              });
                            },
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^[0-9.-]*$')),
                            ],
                            decoration: InputDecoration(
                              hintText: "Введите значение",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        ElevatedButton(
                          onPressed: _swapSelectedItems,
                          child: const FaIcon(
                            FontAwesomeIcons.retweet,
                            color: Color.fromARGB(255, 131, 131, 131),
                            size: 20,
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Container(
                          width: 200,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 251, 233, 233),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: selectedItem2,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedItem2 = newValue;
                                _getResult(
                                    categoryName[currentIndex],
                                    selectedItem1!,
                                    selectedItem2!,
                                    double.parse(_textController.text));
                              });
                            },
                            dropdownColor: Color.fromARGB(255, 210, 183, 183),
                            items: categoryValues[currentIndex]
                                .map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            icon: const SizedBox.shrink(),
                            alignment: Alignment.center,
                          ),
                        ),
                        const SizedBox(
                          height: 50,
                        ),
                        Container(
                          width: 200,
                          decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Color.fromARGB(255, 74, 72, 72)))),
                          child: Center(
                              child: Text(
                            result,
                            style: TextStyle(fontSize: 24),
                          )),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
          if (!_isKeyboardVisible)
            Expanded(
              flex: 1,
              child: Center(
                child: SizedBox(
                  height: 300,
                  child: PageView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: _controller,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                        _updateSelectedItems();
                      });
                    },
                    itemCount: buttonLabels.length,
                    itemBuilder: (context, index) {
                      double scale = 1.0;
                      if (index == currentIndex) {
                        scale = 1.5;
                      } else if (index == currentIndex - 1 ||
                          index == currentIndex + 1) {
                        scale = 0.8;
                      }

                      return Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: scale,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 210, 183, 183),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              minimumSize: const Size(60, 60),
                            ),
                            child: buttonLabels[index],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          if (_isKeyboardVisible)
            const Expanded(
              flex: 1,
              child: Center(
                  child: SizedBox(
                height: 10,
              )),
            )
        ],
      ),
    );
  }
}