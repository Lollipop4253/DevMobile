import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const Food());
}

class Food extends StatelessWidget {
  const Food({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const FoodScreen(),
    );
  }
}

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final TextEditingController productController = TextEditingController();
  List<dynamic> products = [];
  List<Map<String, dynamic>> favoriteProducts = [];
  bool isLoading = false;
  String errorMessage = '';
  double calories = 0;
  List<Map<String, dynamic>> addedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadAddedProducts();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedFavorites = prefs.getString('favorites');
    if (savedFavorites != null) {
      setState(() {
        favoriteProducts =
            List<Map<String, dynamic>>.from(jsonDecode(savedFavorites));
      });
    }
  }

  Future<void> _loadAddedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedAddedProducts = prefs.getString('added_products');
    if (savedAddedProducts != null) {
      setState(() {
        addedProducts =
            List<Map<String, dynamic>>.from(jsonDecode(savedAddedProducts));
        calories = addedProducts.fold(
            0.0, (sum, item) => sum + item['total_calories']);
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('favorites', jsonEncode(favoriteProducts));
  }

  Future<void> _saveAddedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('added_products', jsonEncode(addedProducts));
  }

  Future<void> fetchProducts(String productName) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      products = [];
    });

    try {
      final url = Uri.parse(
          'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$productName&search_simple=1&action=process&json=true');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          products = data['products'] ?? [];
        });
      } else {
        setState(() {
          errorMessage = 'Ошибка: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showProductDetails(BuildContext context, Map<String, dynamic> product) {
    final name = product['product_name'] ?? 'Без названия';
    final brand = product['brands'] ?? 'Без бренда';
    final nutriments = product['nutriments'] ?? {};
    final kcal = nutriments['energy-kcal_100g'] ?? 'Не указано';
    final proteins = nutriments['proteins_100g'] ?? 'Не указано';
    final fats = nutriments['fat_100g'] ?? 'Не указано';
    final carbs = nutriments['carbohydrates_100g'] ?? 'Не указано';
    final imageUrl = product['image_url'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 150),
                )
              else
                const Icon(Icons.fastfood, size: 150),
              const SizedBox(height: 10),
              Text(
                name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Бренд: $brand'),
              const SizedBox(height: 10),
              Text('Калории: $kcal ккал/100г'),
              const SizedBox(height: 10),
              Text('Белки: $proteins г/100г'),
              Text('Жиры: $fats г/100г'),
              Text('Углеводы: $carbs г/100г'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).pop();
              },
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  void addToFavorites(Map<String, dynamic> product) {
    setState(() {
      final isFavorite = favoriteProducts
          .any((p) => p['product_name'] == product['product_name']);
      if (isFavorite) {
        favoriteProducts
            .removeWhere((p) => p['product_name'] == product['product_name']);
      } else {
        favoriteProducts.add(product);
      }
      _saveFavorites();
    });
  }

  void addCalories(
      BuildContext context, Map<String, dynamic> product, var kcalPer100g) {
    final TextEditingController quantityController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Введите количество грамм'),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Количество (г)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (kcalPer100g == null || kcalPer100g <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Невозможно добавить'),
                    ),
                  );
                  return;
                } else {
                  final quantity =
                      double.tryParse(quantityController.text) ?? 0;
                  final totalCalories = (kcalPer100g * quantity) / 100;

                  setState(() {
                    calories += totalCalories;

                    addedProducts.add({
                      'name': product['product_name'],
                      'quantity': quantity,
                      'total_calories': totalCalories,
                    });

                    _saveAddedProducts();
                  });

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Добавить'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  void showAddedProducts(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: const Text(
                'Добавленные продукты',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              content: addedProducts.isNotEmpty
                  ? SizedBox(
                      width: double.maxFinite,
                      child: ListView.separated(
                        shrinkWrap: true,
                        separatorBuilder: (context, index) => const Divider(
                          color: Colors.grey,
                        ),
                        itemCount: addedProducts.length,
                        itemBuilder: (context, index) {
                          final product = addedProducts[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              title: Text(
                                '${product['name']} - ${product['quantity']} г',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Калории: ${product['total_calories'].toStringAsFixed(1)} ккал',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      final TextEditingController
                                          quantityController =
                                          TextEditingController(
                                              text: product['quantity']
                                                  .toString());
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            title: const Text(
                                              'Изменить количество',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                            content: TextField(
                                              controller: quantityController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: 'Количество (г)',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    final newQuantity =
                                                        double.tryParse(
                                                                quantityController
                                                                    .text) ??
                                                            0;
                                                    if (newQuantity > 0) {
                                                      setState(() {
                                                        final oldCalories =
                                                            product[
                                                                'total_calories'];
                                                        final kcalPerGram =
                                                            oldCalories /
                                                                product[
                                                                    'quantity'];
                                                        final newCalories =
                                                            kcalPerGram *
                                                                newQuantity;

                                                        product['quantity'] =
                                                            newQuantity;
                                                        product['total_calories'] =
                                                            newCalories;

                                                        calories +=
                                                            newCalories -
                                                                oldCalories;

                                                        _saveAddedProducts();
                                                      });
                                                      Navigator.of(context)
                                                          .pop();
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Введите корректное количество.'),
                                                        ),
                                                      );
                                                    }
                                                  });
                                                },
                                                child: const Text(
                                                  'Сохранить',
                                                  style: TextStyle(
                                                      color: Colors.green),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text(
                                                  'Отмена',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        calories -= product['total_calories'];
                                        addedProducts.removeAt(index);
                                        _saveAddedProducts();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : const Text(
                      'Нет добавленных продуктов',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Закрыть',
                    style: TextStyle(color: Colors.green, fontSize: 18),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showFavorites(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: const Text(
                'Избранное',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              content: favoriteProducts.isNotEmpty
                  ? SizedBox(
                      width: double.maxFinite,
                      child: ListView.separated(
                        shrinkWrap: true,
                        separatorBuilder: (context, index) => const Divider(
                          color: Colors.grey,
                        ),
                        itemCount: favoriteProducts.length,
                        itemBuilder: (context, index) {
                          final product = favoriteProducts[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product['image_url'] != null
                                  ? Image.network(
                                      product['image_url'],
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.broken_image),
                                    )
                                  : const Icon(Icons.fastfood, size: 50),
                            ),
                            title: Text(
                              product['product_name'] ?? 'Без названия',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Бренд: ${product['brands'] ?? 'Без бренда'}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  favoriteProducts.removeAt(index);
                                  _saveFavorites();
                                });
                              },
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              showProductDetails(context, product);
                            },
                          );
                        },
                      ),
                    )
                  : const Text(
                      'Нет избранных продуктов',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Закрыть',
                    style: TextStyle(color: Colors.green, fontSize: 18),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Food'),
            const Spacer(),
            IconButton(
              onPressed: () {
                showFavorites(context);
              },
              icon: const Icon(Icons.favorite),
            ),
            IconButton(
              onPressed: () {
                showAddedProducts(context);
              },
              icon: const Icon(Icons.list),
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Center(
              child: Text(
                "Ккал",
                style: TextStyle(fontSize: 32),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  showAddedProducts(context);
                },
                onLongPress: () {
                  setState(() {
                    calories = 0;
                    addedProducts.clear();
                    _saveAddedProducts();
                  });
                },
                child: Text(
                  calories.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 80, color: Colors.green),
                ),
              ),
            ),
            TextField(
              controller: productController,
              onSubmitted: (value) {
                if (productController.text.isNotEmpty) {
                  fetchProducts(productController.text);
                  FocusScope.of(context).unfocus();
                }
              },
              decoration: const InputDecoration(
                labelText: 'Введите название продукта',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (productController.text.isNotEmpty) {
                  fetchProducts(productController.text);
                  FocusScope.of(context).unfocus();
                }
              },
              child: const Text('Найти'),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const CircularProgressIndicator()
            else if (errorMessage.isNotEmpty)
              Text(errorMessage)
            else if (products.isEmpty)
              const Text('Введите название продукта и нажмите "Найти".')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final kcal100g = product['nutriments']['energy-kcal_100g'];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () {
                          addCalories(context, product, kcal100g);
                        },
                        onLongPress: () {
                          showProductDetails(context, product);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              product['image_url'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product['image_url'],
                                        height: 60,
                                        width: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image,
                                                    size: 60),
                                      ),
                                    )
                                  : Container(
                                      height: 60,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child:
                                          const Icon(Icons.fastfood, size: 40),
                                    ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['product_name'] ?? 'Без названия',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Бренд: ${product['brands'] ?? 'Без бренда'}',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (kcal100g != null)
                                      Text(
                                        'Калории: ${kcal100g.toString()} ккал/100г',
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.green),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: favoriteProducts.any((p) =>
                                        p['product_name'] ==
                                        product['product_name'])
                                    ? const Icon(Icons.favorite,
                                        color: Colors.red)
                                    : const Icon(Icons.favorite_border),
                                onPressed: () {
                                  addToFavorites(product);
                                },
                              ),
                            ],
                          ),
                        ),
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
