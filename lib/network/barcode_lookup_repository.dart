import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../models/scanned_product.dart';

abstract class BarcodeLookupRepository {
  /// Looks a barcode up, or returns null if the product isn't in the
  /// database, or is but doesn't have enough nutrition data (calories) to
  /// be useful — both cases get the same "try manual entry" UX.
  Future<ScannedProduct?> lookup(String barcode, Locale locale);
}

/// Looks products up via Open Food Facts (world.openfoodfacts.org) — a
/// free, open, crowdsourced product database; no API key needed for reads.
/// Never called for logging/writing anything back, only for display, so a
/// bad/incomplete entry in their data can't corrupt anything of ours.
class OpenFoodFactsRepository implements BarcodeLookupRepository {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';
  static const _fields =
      'product_name,product_name_en,product_name_ru,product_name_uk,brands,'
      'nutriscore_grade,nova_group,nutriments,image_front_url,image_url,'
      'serving_quantity';

  @override
  Future<ScannedProduct?> lookup(String barcode, Locale locale) async {
    final uri = Uri.parse('$_baseUrl/$barcode.json?fields=$_fields');
    final response = await http.get(
      uri,
      // Open Food Facts asks API consumers to identify themselves.
      headers: const {'User-Agent': 'BodyX - Flutter - Version 1.0'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['status'] != 1) return null;

    final product = json['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    final nutriments = product['nutriments'] as Map<String, dynamic>?;
    final kcal = _numField(nutriments, 'energy-kcal_100g');
    if (kcal == null) return null; // Not enough data to be useful.

    return ScannedProduct(
      barcode: barcode,
      name: _resolveName(product, locale) ?? barcode,
      brand: (product['brands'] as String?)?.split(',').first.trim(),
      imageUrl: product['image_front_url'] as String? ??
          product['image_url'] as String?,
      nutriScore: _parseNutriScore(product['nutriscore_grade'] as String?),
      novaGroup: (product['nova_group'] as num?)?.toInt(),
      kcalPer100g: kcal,
      proteinPer100g: _numField(nutriments, 'proteins_100g') ?? 0,
      carbsPer100g: _numField(nutriments, 'carbohydrates_100g') ?? 0,
      fatPer100g: _numField(nutriments, 'fat_100g') ?? 0,
      servingGrams: (product['serving_quantity'] as num?)?.round(),
    );
  }

  double? _numField(Map<String, dynamic>? map, String key) {
    final v = map?[key];
    return v is num ? v.toDouble() : null;
  }

  String? _resolveName(Map<String, dynamic> product, Locale locale) {
    final localized = product['product_name_${locale.languageCode}'];
    if (localized is String && localized.isNotEmpty) return localized;
    final generic = product['product_name'];
    if (generic is String && generic.isNotEmpty) return generic;
    final en = product['product_name_en'];
    if (en is String && en.isNotEmpty) return en;
    return null;
  }

  NutriScoreGrade? _parseNutriScore(String? grade) {
    switch (grade) {
      case 'a':
        return NutriScoreGrade.a;
      case 'b':
        return NutriScoreGrade.b;
      case 'c':
        return NutriScoreGrade.c;
      case 'd':
        return NutriScoreGrade.d;
      case 'e':
        return NutriScoreGrade.e;
      default:
        return null; // 'unknown', 'not-applicable', or missing entirely.
    }
  }
}
