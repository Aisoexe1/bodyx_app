import 'package:flutter/material.dart';

/// Food category for grouping the search/browse list — matches how people
/// actually think about groceries, not a macro-nutrient bucket.
enum FoodCategory {
  meat,
  cheese,
  fruits,
  vegetables,
  dairy,
  nuts,
  grains,
  other,
}

extension FoodCategoryX on FoodCategory {
  String get label {
    switch (this) {
      case FoodCategory.meat:
        return 'Мясо и рыба';
      case FoodCategory.cheese:
        return 'Сыр';
      case FoodCategory.fruits:
        return 'Фрукты';
      case FoodCategory.vegetables:
        return 'Овощи';
      case FoodCategory.dairy:
        return 'Молочные продукты';
      case FoodCategory.nuts:
        return 'Орехи';
      case FoodCategory.grains:
        return 'Крупы и злаки';
      case FoodCategory.other:
        return 'Другое';
    }
  }

  IconData get icon {
    switch (this) {
      case FoodCategory.meat:
        return Icons.set_meal_rounded;
      case FoodCategory.cheese:
        return Icons.icecream_rounded;
      case FoodCategory.fruits:
        return Icons.eco_rounded;
      case FoodCategory.vegetables:
        return Icons.grass_rounded;
      case FoodCategory.dairy:
        return Icons.local_drink_rounded;
      case FoodCategory.nuts:
        return Icons.spa_rounded;
      case FoodCategory.grains:
        return Icons.rice_bowl_rounded;
      case FoodCategory.other:
        return Icons.restaurant_rounded;
    }
  }
}

/// Macros are stored per 100g so any gram amount the user picks can be
/// scaled exactly, rather than being locked to one fixed serving size.
/// [defaultGrams] is just the amount the gram picker opens with — a
/// realistic "typical portion" for that food, not a hard limit.
class FoodItem {
  const FoodItem({
    required this.name,
    required this.category,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.defaultGrams,
    required this.icon,
  });

  final String name;
  final FoodCategory category;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final int defaultGrams;
  final IconData icon;

  int kcalFor(int grams) => (kcalPer100g * grams / 100).round();
  int proteinFor(int grams) => (proteinPer100g * grams / 100).round();
  int carbsFor(int grams) => (carbsPer100g * grams / 100).round();
  int fatFor(int grams) => (fatPer100g * grams / 100).round();
}

/// A small local database of common foods — no external barcode/food-API
/// service is available in this app, so this stays a fixed local list.
class FoodDatabase {
  FoodDatabase._();

  static const List<FoodItem> _items = [
    FoodItem(name: 'Куриная грудка', category: FoodCategory.meat, kcalPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6, defaultGrams: 150, icon: Icons.set_meal_rounded),
    FoodItem(name: 'Лосось', category: FoodCategory.meat, kcalPer100g: 187, proteinPer100g: 23, carbsPer100g: 0, fatPer100g: 10, defaultGrams: 150, icon: Icons.set_meal_rounded),
    FoodItem(name: 'Говядина', category: FoodCategory.meat, kcalPer100g: 220, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 12, defaultGrams: 150, icon: Icons.kebab_dining_rounded),
    FoodItem(name: 'Тунец консерв.', category: FoodCategory.meat, kcalPer100g: 110, proteinPer100g: 24, carbsPer100g: 0, fatPer100g: 0.7, defaultGrams: 150, icon: Icons.set_meal_rounded),

    FoodItem(name: 'Сыр твёрдый', category: FoodCategory.cheese, kcalPer100g: 400, proteinPer100g: 25, carbsPer100g: 2.5, fatPer100g: 32.5, defaultGrams: 40, icon: Icons.icecream_rounded),

    FoodItem(name: 'Банан', category: FoodCategory.fruits, kcalPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 22.8, fatPer100g: 0.3, defaultGrams: 118, icon: Icons.eco_rounded),
    FoodItem(name: 'Яблоко', category: FoodCategory.fruits, kcalPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 13.8, fatPer100g: 0.2, defaultGrams: 182, icon: Icons.eco_rounded),
    FoodItem(name: 'Ягоды смешанные', category: FoodCategory.fruits, kcalPer100g: 57, proteinPer100g: 0.7, carbsPer100g: 13.3, fatPer100g: 0.3, defaultGrams: 150, icon: Icons.eco_rounded),
    FoodItem(name: 'Авокадо', category: FoodCategory.fruits, kcalPer100g: 160, proteinPer100g: 2, carbsPer100g: 8.5, fatPer100g: 14.7, defaultGrams: 100, icon: Icons.eco_rounded),

    FoodItem(name: 'Салат овощной', category: FoodCategory.vegetables, kcalPer100g: 36, proteinPer100g: 1.2, carbsPer100g: 4.8, fatPer100g: 1.6, defaultGrams: 250, icon: Icons.grass_rounded),
    FoodItem(name: 'Брокколи на пару', category: FoodCategory.vegetables, kcalPer100g: 35, proteinPer100g: 3, carbsPer100g: 6, fatPer100g: 0.5, defaultGrams: 200, icon: Icons.grass_rounded),

    FoodItem(name: 'Творог 5%', category: FoodCategory.dairy, kcalPer100g: 110, proteinPer100g: 18, carbsPer100g: 3, fatPer100g: 2.5, defaultGrams: 200, icon: Icons.icecream_rounded),
    FoodItem(name: 'Греческий йогурт', category: FoodCategory.dairy, kcalPer100g: 73, proteinPer100g: 10, carbsPer100g: 4, fatPer100g: 2, defaultGrams: 200, icon: Icons.icecream_rounded),
    FoodItem(name: 'Молоко 2.5%', category: FoodCategory.dairy, kcalPer100g: 52, proteinPer100g: 3.2, carbsPer100g: 4.8, fatPer100g: 2, defaultGrams: 250, icon: Icons.local_drink_rounded),

    FoodItem(name: 'Орехи миндаль', category: FoodCategory.nuts, kcalPer100g: 583, proteinPer100g: 21, carbsPer100g: 22, fatPer100g: 50, defaultGrams: 30, icon: Icons.spa_rounded),
    FoodItem(name: 'Арахисовая паста', category: FoodCategory.nuts, kcalPer100g: 594, proteinPer100g: 25, carbsPer100g: 19, fatPer100g: 50, defaultGrams: 32, icon: Icons.spa_rounded),

    FoodItem(name: 'Рис отварной', category: FoodCategory.grains, kcalPer100g: 130, proteinPer100g: 2.5, carbsPer100g: 28, fatPer100g: 0.5, defaultGrams: 200, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Овсянка', category: FoodCategory.grains, kcalPer100g: 375, proteinPer100g: 12.5, carbsPer100g: 67.5, fatPer100g: 7.5, defaultGrams: 80, icon: Icons.breakfast_dining_rounded),
    FoodItem(name: 'Гречка отварная', category: FoodCategory.grains, kcalPer100g: 123, proteinPer100g: 4, carbsPer100g: 25, fatPer100g: 1, defaultGrams: 200, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Картофель запечёный', category: FoodCategory.grains, kcalPer100g: 86, proteinPer100g: 2, carbsPer100g: 20, fatPer100g: 0, defaultGrams: 250, icon: Icons.lunch_dining_rounded),
    FoodItem(name: 'Хлеб цельнозерновой', category: FoodCategory.grains, kcalPer100g: 267, proteinPer100g: 10, carbsPer100g: 46.7, fatPer100g: 3.3, defaultGrams: 60, icon: Icons.bakery_dining_rounded),
    FoodItem(name: 'Макароны', category: FoodCategory.grains, kcalPer100g: 140, proteinPer100g: 5, carbsPer100g: 28, fatPer100g: 1, defaultGrams: 200, icon: Icons.ramen_dining_rounded),
    FoodItem(name: 'Батат', category: FoodCategory.grains, kcalPer100g: 86, proteinPer100g: 1.6, carbsPer100g: 20, fatPer100g: 0, defaultGrams: 250, icon: Icons.lunch_dining_rounded),

    FoodItem(name: 'Яйца', category: FoodCategory.other, kcalPer100g: 156, proteinPer100g: 13, carbsPer100g: 1, fatPer100g: 11, defaultGrams: 100, icon: Icons.egg_rounded),
    FoodItem(name: 'Протеиновый шейк', category: FoodCategory.other, kcalPer100g: 220, proteinPer100g: 32, carbsPer100g: 14, fatPer100g: 4, defaultGrams: 100, icon: Icons.local_cafe_rounded),
    FoodItem(name: 'Тофу', category: FoodCategory.other, kcalPer100g: 80, proteinPer100g: 8.7, carbsPer100g: 2, fatPer100g: 4.7, defaultGrams: 150, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Оливковое масло', category: FoodCategory.other, kcalPer100g: 857, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100, defaultGrams: 14, icon: Icons.opacity_rounded),
  ];

  static List<FoodItem> get all => _items;

  static List<FoodItem> search(String query) {
    if (query.trim().isEmpty) return _items;
    final q = query.trim().toLowerCase();
    return _items.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  /// Groups [items] by category in a fixed, stable display order —
  /// used to render the browse list under section headers.
  static List<MapEntry<FoodCategory, List<FoodItem>>> grouped(
      List<FoodItem> items) {
    final byCategory = <FoodCategory, List<FoodItem>>{};
    for (final item in items) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }
    return FoodCategory.values
        .where(byCategory.containsKey)
        .map((c) => MapEntry(c, byCategory[c]!))
        .toList();
  }
}
