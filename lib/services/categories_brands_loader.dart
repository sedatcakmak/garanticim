import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CategoryBrandData {
  final String id;
  final String name;
  final List<String> brands;

  CategoryBrandData({
    required this.id,
    required this.name,
    required this.brands,
  });

  factory CategoryBrandData.fromJson(Map<String, dynamic> json) {
    return CategoryBrandData(
      id: json['id'] as String,
      name: json['name'] as String,
      brands: (json['brands'] as List).map((e) => e.toString()).toList(),
    );
  }
}

class CategoriesBrandsLoader {
  static final CategoriesBrandsLoader _instance =
      CategoriesBrandsLoader._internal();
  factory CategoriesBrandsLoader() => _instance;
  CategoriesBrandsLoader._internal();

  List<CategoryBrandData>? _categories;

  Future<List<CategoryBrandData>> loadCategories() async {
    if (_categories != null) {
      return _categories!;
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/categories_brands.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> categoriesList = jsonData['categories'];

      _categories = categoriesList
          .map((json) => CategoryBrandData.fromJson(json))
          .toList();

      return _categories!;
    } catch (e) {
      debugPrint('Error loading categories: $e');
      return [];
    }
  }

  Future<List<String>> getBrandsForCategory(String categoryId) async {
    final categories = await loadCategories();
    final category = categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => CategoryBrandData(id: '', name: '', brands: [_otherLabel]),
    );
    return category.brands;
  }

  Future<String> getCategoryName(String categoryId) async {
    final categories = await loadCategories();
    final category = categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => CategoryBrandData(id: '', name: _otherLabel, brands: []),
    );
    return category.name;
  }

  void clearCache() {
    _categories = null;
  }

  static const String _otherLabel = 'Diger';
}
