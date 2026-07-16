import 'package:flutter/material.dart';

/// One typical serving of a food, with its macros — used to power quick,
/// searchable meal logging without a real barcode/food-API integration
/// (which would need a third-party service this prototype doesn't have).
/// Values are per common serving, not per 100g, so logging stays one tap.
class FoodItem {
  const FoodItem({
    required this.name,
    required this.serving,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.icon,
  });

  final String name;
  final String serving;
  final int kcal;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final IconData icon;
}

/// A small local database of common foods, grouped so the log-meal sheet
/// can show them without a search term too.
class FoodDatabase {
  FoodDatabase._();

  static const List<FoodItem> protein = [
    FoodItem(name: 'Куриная грудка', serving: '150 г', kcal: 248, proteinG: 46, carbsG: 0, fatG: 5, icon: Icons.set_meal_rounded),
    FoodItem(name: 'Яйца (2 шт)', serving: '2 шт', kcal: 156, proteinG: 13, carbsG: 1, fatG: 11, icon: Icons.egg_rounded),
    FoodItem(name: 'Творог 5%', serving: '200 г', kcal: 220, proteinG: 36, carbsG: 6, fatG: 5, icon: Icons.icecream_rounded),
    FoodItem(name: 'Лосось', serving: '150 г', kcal: 280, proteinG: 34, carbsG: 0, fatG: 15, icon: Icons.set_meal_rounded),
    FoodItem(name: 'Говядина', serving: '150 г', kcal: 330, proteinG: 39, carbsG: 0, fatG: 18, icon: Icons.kebab_dining_rounded),
    FoodItem(name: 'Протеиновый шейк', serving: '1 порция', kcal: 220, proteinG: 32, carbsG: 14, fatG: 4, icon: Icons.local_cafe_rounded),
    FoodItem(name: 'Тунец консерв.', serving: '150 г', kcal: 165, proteinG: 36, carbsG: 0, fatG: 1, icon: Icons.set_meal_rounded),
    FoodItem(name: 'Тофу', serving: '150 г', kcal: 120, proteinG: 13, carbsG: 3, fatG: 7, icon: Icons.rice_bowl_rounded),
  ];

  static const List<FoodItem> carbs = [
    FoodItem(name: 'Рис отварной', serving: '200 г', kcal: 260, proteinG: 5, carbsG: 56, fatG: 1, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Овсянка', serving: '80 г сух.', kcal: 300, proteinG: 10, carbsG: 54, fatG: 6, icon: Icons.breakfast_dining_rounded),
    FoodItem(name: 'Гречка отварная', serving: '200 г', kcal: 246, proteinG: 8, carbsG: 50, fatG: 2, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Картофель запечёный', serving: '250 г', kcal: 215, proteinG: 5, carbsG: 50, fatG: 0, icon: Icons.lunch_dining_rounded),
    FoodItem(name: 'Хлеб цельнозерновой', serving: '2 ломтика', kcal: 160, proteinG: 6, carbsG: 28, fatG: 2, icon: Icons.bakery_dining_rounded),
    FoodItem(name: 'Макароны', serving: '200 г', kcal: 280, proteinG: 10, carbsG: 56, fatG: 2, icon: Icons.ramen_dining_rounded),
    FoodItem(name: 'Батат', serving: '250 г', kcal: 215, proteinG: 4, carbsG: 50, fatG: 0, icon: Icons.lunch_dining_rounded),
  ];

  static const List<FoodItem> fruitVeg = [
    FoodItem(name: 'Банан', serving: '1 шт', kcal: 105, proteinG: 1, carbsG: 27, fatG: 0, icon: Icons.eco_rounded),
    FoodItem(name: 'Яблоко', serving: '1 шт', kcal: 95, proteinG: 0, carbsG: 25, fatG: 0, icon: Icons.eco_rounded),
    FoodItem(name: 'Ягоды смешанные', serving: '150 г', kcal: 85, proteinG: 1, carbsG: 20, fatG: 0, icon: Icons.eco_rounded),
    FoodItem(name: 'Салат овощной', serving: '250 г', kcal: 90, proteinG: 3, carbsG: 12, fatG: 4, icon: Icons.eco_rounded),
    FoodItem(name: 'Брокколи на пару', serving: '200 г', kcal: 70, proteinG: 6, carbsG: 12, fatG: 1, icon: Icons.eco_rounded),
    FoodItem(name: 'Авокадо', serving: '1/2 шт', kcal: 120, proteinG: 1, carbsG: 6, fatG: 11, icon: Icons.eco_rounded),
  ];

  static const List<FoodItem> dairyFats = [
    FoodItem(name: 'Греческий йогурт', serving: '200 г', kcal: 146, proteinG: 20, carbsG: 8, fatG: 4, icon: Icons.icecream_rounded),
    FoodItem(name: 'Молоко 2.5%', serving: '250 мл', kcal: 130, proteinG: 8, carbsG: 12, fatG: 5, icon: Icons.local_drink_rounded),
    FoodItem(name: 'Сыр твёрдый', serving: '40 г', kcal: 160, proteinG: 10, carbsG: 1, fatG: 13, icon: Icons.icecream_rounded),
    FoodItem(name: 'Орехи миндаль', serving: '30 г', kcal: 175, proteinG: 6, carbsG: 6, fatG: 15, icon: Icons.grass_rounded),
    FoodItem(name: 'Арахисовая паста', serving: '2 ст.л.', kcal: 190, proteinG: 8, carbsG: 6, fatG: 16, icon: Icons.grass_rounded),
    FoodItem(name: 'Оливковое масло', serving: '1 ст.л.', kcal: 120, proteinG: 0, carbsG: 0, fatG: 14, icon: Icons.opacity_rounded),
  ];

  static List<FoodItem> get all => [...protein, ...carbs, ...fruitVeg, ...dairyFats];

  static List<FoodItem> search(String query) {
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all.where((f) => f.name.toLowerCase().contains(q)).toList();
  }
}
