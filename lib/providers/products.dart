import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';
import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  final String authToken;
  final String userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((product) => product.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final String filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';

    var url =
        'https://shop-flutter-35e39.firebaseio.com//products.json?auth=$authToken&$filterString';
    try {
      final response = await http.get(url);
      final extractedData = jsonDecode(response.body) as Map<String, dynamic>;
      final List<Product> loadedProducts = [];
      if (extractedData == null) {
        return;
      }

      url =
          'https://shop-flutter-35e39.firebaseio.com//userFavorites/$userId.json?auth=$authToken';

      final favoriteResponse = await http.get(url);
      final favoriteData = jsonDecode(favoriteResponse.body);

      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          isFavorite:
              favoriteData == null ? false : favoriteData[prodId] ?? false,
          imageUrl: prodData['imageUrl'],
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product product) async {
    final url =
        'https://shop-flutter-35e39.firebaseio.com//products.json?auth=$authToken';

    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': userId,
        }),
      );
      final newProduct = Product(
        id: jsonDecode(response.body)['name'],
        title: product.title,
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
      );

      _items.insert(0, newProduct);
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url =
          'https://shop-flutter-35e39.firebaseio.com//products/$id.json?auth=$authToken';
      await http.patch(url,
          body: jsonEncode(
            {
              'title': newProduct.title,
              'description': newProduct.description,
              'price': newProduct.price,
              'imageUrl': newProduct.imageUrl
            },
          ));
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://shop-flutter-35e39.firebaseio.com//products/$id.json?auth=$authToken';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Couldnt delete product');
    }
    existingProduct = null;
  }
}
