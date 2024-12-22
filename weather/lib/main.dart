import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final String weatherApiKey = '6d7109712031478cbf1102438240212';
  final TextEditingController cityController = TextEditingController();
  String weatherData = 'Введите название города.';
  String currentTemp = '';
  String currentIcon = '';
  String windSpeed = '';
  String windDirection = '';
  String humidity = '';
  String pressure = '';
  List<Map<String, dynamic>> hourlyForecast = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCity();
  }

  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('home_city');

    if (savedCity != null) {
      cityController.text = savedCity;
      fetchWeather(savedCity);
    } else {
      _getLocationAndFetchWeather();
    }
  }

  Future<void> _getLocationAndFetchWeather() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          weatherData =
              'Для определения местоположения необходимо предоставить доступ.';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String? cityName = await _getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (cityName != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('home_city', cityName);

        cityController.text = cityName;
        fetchWeather(cityName);
      }
    } catch (e) {
      setState(() {
        weatherData = 'Ошибка при получении местоположения: $e';
      });
    }
  }

  Future<String?> _getCityFromCoordinates(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.weatherapi.com/v1/current.json?key=$weatherApiKey&q=$lat,$lon',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['location']['name'];
      }
    } catch (e) {
      setState(() {
        weatherData = 'Ошибка определения города: $e';
      });
    }

    return null;
  }

  Future<void> fetchWeather(String cityName) async {
    try {
      final url = Uri.parse(
        'https://api.weatherapi.com/v1/forecast.json?key=$weatherApiKey&q=$cityName&hours=24&lang=ru',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print(data);
        final location = data['location']['name'];
        final current = data['current'];
        final forecast = data['forecast']['forecastday'][0]['hour'];

        currentTemp = '${current['temp_c']}°C';
        currentIcon = "https:${current['condition']['icon']}";
        windSpeed = '${current['wind_kph']} км/ч';
        windDirection = current['wind_dir'];
        humidity = '${current['humidity']}%';
        pressure = '${current['pressure_mb']} мбар';

        hourlyForecast = forecast.map<Map<String, dynamic>>((hour) {
          return {
            'time': hour['time'],
            'temp_c': hour['temp_c'],
            'icon': "https:${hour['condition']['icon']}",
          };
        }).toList();

        setState(() {
          weatherData = 'Город: $location';
        });
      } else {
        setState(() {
          weatherData = 'Ошибка: ${response.statusCode}';
          currentTemp = '';
          currentIcon = '';
          hourlyForecast.clear();
        });
      }
    } catch (e) {
      setState(() {
        weatherData = 'Ошибка: $e';
        currentTemp = '';
        currentIcon = '';
        hourlyForecast.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.blue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Введите город',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                      ),
                      onPressed: () {
                        if (cityController.text.isNotEmpty) {
                          fetchWeather(cityController.text);
                        }
                      },
                      child: const Text('Обновить'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (weatherData.isNotEmpty)
                  Column(
                    children: [
                      Text(
                        weatherData,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (currentTemp.isNotEmpty && currentIcon.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              currentIcon,
                              width: 50,
                              height: 50,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              currentTemp,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                const SizedBox(height: 20),

                // Прогноз на 24 часа
                if (hourlyForecast.isNotEmpty)
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: hourlyForecast.length,
                      itemBuilder: (context, index) {
                        final forecast = hourlyForecast[index];
                        return Card(
                          color: Colors.white.withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(
                                  forecast['icon'],
                                  width: 40,
                                  height: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  forecast['time'].split(' ')[1],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${forecast['temp_c']}°C',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),

                if (currentTemp.isNotEmpty)
                  Expanded(
                    child: Card(
                      color: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView(
                          children: [
                            InfoRow(
                              title: 'Скорость ветра:',
                              value: windSpeed,
                            ),
                            InfoRow(
                              title: 'Направление ветра:',
                              value: windDirection,
                            ),
                            InfoRow(
                              title: 'Влажность:',
                              value: humidity,
                            ),
                            InfoRow(
                              title: 'Давление:',
                              value: pressure,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const InfoRow({required this.title, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
