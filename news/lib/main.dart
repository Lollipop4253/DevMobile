import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const NewsApp());
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      debugShowCheckedModeBanner: false,
      home: const NewsScreen(),
    );
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final String NewsApiKey = 'fa0a4d2cba644ffab614f1c3d938d4f5';
  String sortBy = "publishedAt";
  String language = "ru";
  List articles = [];
  Map<String, dynamic> savedArticles = {};
  List loadedList = [];
  TextEditingController searchController = TextEditingController();
  String date = "Загрузка...";
  String requestDate = "";
  List<String> selectList = [
    "Сначала новые",
    "Популярные издания",
    "Наиболее близкие по теме"
  ];
  List<String> selectListValue = ["publishedAt", "popularity", "relevancy"];

  Future<void> fetchNews() async {
    String query = searchController.text;
    _loadArticles();

    setState(() {
      articles = loadedList;
    });

    try {
      final url = Uri.parse('https://newsapi.org/v2/everything?'
          '${requestDate.isNotEmpty ? "to=${requestDate}&" : ""}'
          'q=${query}&'
          'language=${language}&'
          'sortBy=${sortBy}&'
          'searchIn=title,description,content&'
          'apiKey=${NewsApiKey}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          articles = data["articles"];
          date = articles.isNotEmpty
              ? articles[0]["publishedAt"].substring(0, 10)
              : "Нет данных";
          requestDate = date;
          articles = loadedList;
        });
      } else {
        setState(() {});
      }
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _loadArticles() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // prefs.clear();
    String? jsonString = prefs.getString('articles');

    if (jsonString != null) {
      final Map<String, dynamic> decodedMap = jsonDecode(jsonString);

      setState(() {
        loadedList = decodedMap.values.toList();
        savedArticles = decodedMap;
        print("Loaded $loadedList");
      });
    }
  }

  Future<void> _saveArticle(var article) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (savedArticles.length >= 20) {
      savedArticles.remove(savedArticles.keys.first);
    }
    savedArticles[article["title"]] = article;

    String jsonString = jsonEncode(savedArticles);
    await prefs.setString('articles', jsonString);
    print("Saved $article");
  }

  void _launchURL(String url) async {

    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildBottomSheetContent(
      BuildContext context, String description, String url, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _launchURL(url),
            child: Text(
              url,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    DateTime initialDate;

    if (date != "Загрузка..." && DateTime.tryParse(date) != null) {
      initialDate = DateTime.parse(date);
    } else {
      initialDate = DateTime.now();
    }

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        date = selectedDate.toLocal().toString().substring(0, 10);
        requestDate = date;
        fetchNews();
      });
    }
  }

  @override
  void initState() {
    searchController.text = "Пиво";
    fetchNews();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: Row(
          children: [
            const Text(
              "Новости",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _selectDate(context),
              child: Text(
                articles.isNotEmpty ? date : "Загрузка...",
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onSubmitted: (value) => fetchNews(),
                    decoration: InputDecoration(
                      hintText: 'Введите запрос',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    fetchNews();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Поиск"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: sortBy,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    sortBy = newValue;
                    fetchNews();
                  });
                }
              },
              dropdownColor: Color.fromRGBO(255, 189, 0, 1),
              items: List.generate(selectList.length, (index) {
                return DropdownMenuItem<String>(
                  value: selectListValue[index],
                  child: Text(selectList[index]),
                );
              }),
              icon: const Icon(Icons.arrow_drop_down),
              alignment: Alignment.centerLeft,
              isExpanded: true,
              underline: Container(
                height: 1,
                color: Colors.grey.shade400,
              ),
            ),
            Expanded(
              child: articles.isEmpty
                  ? const Center(
                      child: Text(
                        "Нет данных",
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: articles.length,
                      itemBuilder: (context, index) {
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              articles[index]["title"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              articles[index]["publishedAt"].substring(0, 10),
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            onTap: () {
                              _saveArticle(articles[index]);
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                backgroundColor: Colors.white,
                                builder: (context) {
                                  return _buildBottomSheetContent(
                                    context,
                                    articles[index]["title"],
                                    articles[index]["url"],
                                    articles[index]["urlToImage"] != null
                                        ? articles[index]["urlToImage"]
                                        : "https://upload.wikimedia.org/wikipedia/commons/9/9a/%D0%9D%D0%B5%D1%82_%D1%84%D0%BE%D1%82%D0%BE.png",
                                  );
                                },
                              );
                            },
                          ),
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
