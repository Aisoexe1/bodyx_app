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
    FoodItem(name: 'Куриное бедро', category: FoodCategory.meat, kcalPer100g: 209, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 10.9, defaultGrams: 150, icon: Icons.set_meal_rounded),
    FoodItem(name: 'Индейка филе', category: FoodCategory.meat, kcalPer100g: 135, proteinPer100g: 30, carbsPer100g: 0, fatPer100g: 1, defaultGrams: 150, icon: Icons.set_meal_rounded),
    FoodItem(name: 'Свинина нежирная', category: FoodCategory.meat, kcalPer100g: 143, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 4, defaultGrams: 150, icon: Icons.kebab_dining_rounded),
    FoodItem(name: 'Треска', category: FoodCategory.meat, kcalPer100g: 82, proteinPer100g: 18, carbsPer100g: 0, fatPer100g: 0.7, defaultGrams: 150, icon: Icons.set_meal_rounded),
    FoodItem(name: 'Креветки', category: FoodCategory.meat, kcalPer100g: 99, proteinPer100g: 24, carbsPer100g: 0.2, fatPer100g: 0.3, defaultGrams: 120, icon: Icons.set_meal_rounded),
    FoodItem(name: 'Минтай', category: FoodCategory.meat, kcalPer100g: 72, proteinPer100g: 15.9, carbsPer100g: 0, fatPer100g: 0.9, defaultGrams: 150, icon: Icons.set_meal_rounded),
    FoodItem(name: 'Скумбрия', category: FoodCategory.meat, kcalPer100g: 205, proteinPer100g: 18.6, carbsPer100g: 0, fatPer100g: 13.9, defaultGrams: 120, icon: Icons.set_meal_rounded),
    FoodItem(name: 'Ветчина', category: FoodCategory.meat, kcalPer100g: 145, proteinPer100g: 20, carbsPer100g: 1.5, fatPer100g: 6, defaultGrams: 50, icon: Icons.kebab_dining_rounded),
    FoodItem(name: 'Бекон', category: FoodCategory.meat, kcalPer100g: 541, proteinPer100g: 37, carbsPer100g: 1.4, fatPer100g: 42, defaultGrams: 30, icon: Icons.kebab_dining_rounded),
    FoodItem(name: 'Колбаса варёная', category: FoodCategory.meat, kcalPer100g: 257, proteinPer100g: 12, carbsPer100g: 1.5, fatPer100g: 22.8, defaultGrams: 50, icon: Icons.kebab_dining_rounded),
    FoodItem(name: 'Сосиски', category: FoodCategory.meat, kcalPer100g: 266, proteinPer100g: 11.4, carbsPer100g: 1.5, fatPer100g: 23.9, defaultGrams: 80, icon: Icons.kebab_dining_rounded),
    FoodItem(name: 'Печень куриная', category: FoodCategory.meat, kcalPer100g: 140, proteinPer100g: 20.4, carbsPer100g: 0.9, fatPer100g: 5.9, defaultGrams: 150, icon: Icons.set_meal_rounded),
    FoodItem(name: 'Фарш говяжий 15%', category: FoodCategory.meat, kcalPer100g: 215, proteinPer100g: 18, carbsPer100g: 0, fatPer100g: 15, defaultGrams: 150, icon: Icons.kebab_dining_rounded),
    FoodItem(name: 'Баранина', category: FoodCategory.meat, kcalPer100g: 294, proteinPer100g: 25, carbsPer100g: 0, fatPer100g: 21, defaultGrams: 150, icon: Icons.kebab_dining_rounded),

    FoodItem(name: 'Сыр твёрдый', category: FoodCategory.cheese, kcalPer100g: 400, proteinPer100g: 25, carbsPer100g: 2.5, fatPer100g: 32.5, defaultGrams: 40, icon: Icons.icecream_rounded),
    FoodItem(name: 'Моцарелла', category: FoodCategory.cheese, kcalPer100g: 280, proteinPer100g: 18, carbsPer100g: 3.1, fatPer100g: 22, defaultGrams: 50, icon: Icons.icecream_rounded),
    FoodItem(name: 'Пармезан', category: FoodCategory.cheese, kcalPer100g: 431, proteinPer100g: 38, carbsPer100g: 4.1, fatPer100g: 29, defaultGrams: 30, icon: Icons.icecream_rounded),
    FoodItem(name: 'Сыр плавленый', category: FoodCategory.cheese, kcalPer100g: 257, proteinPer100g: 12, carbsPer100g: 4, fatPer100g: 21, defaultGrams: 30, icon: Icons.icecream_rounded),
    FoodItem(name: 'Фета', category: FoodCategory.cheese, kcalPer100g: 264, proteinPer100g: 14, carbsPer100g: 4, fatPer100g: 21, defaultGrams: 50, icon: Icons.icecream_rounded),
    FoodItem(name: 'Сыр творожный', category: FoodCategory.cheese, kcalPer100g: 253, proteinPer100g: 6, carbsPer100g: 4, fatPer100g: 24, defaultGrams: 30, icon: Icons.icecream_rounded),
    FoodItem(name: 'Брынза', category: FoodCategory.cheese, kcalPer100g: 260, proteinPer100g: 17.9, carbsPer100g: 0, fatPer100g: 20.1, defaultGrams: 50, icon: Icons.icecream_rounded),

    FoodItem(name: 'Банан', category: FoodCategory.fruits, kcalPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 22.8, fatPer100g: 0.3, defaultGrams: 118, icon: Icons.eco_rounded),
    FoodItem(name: 'Яблоко', category: FoodCategory.fruits, kcalPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 13.8, fatPer100g: 0.2, defaultGrams: 182, icon: Icons.eco_rounded),
    FoodItem(name: 'Ягоды смешанные', category: FoodCategory.fruits, kcalPer100g: 57, proteinPer100g: 0.7, carbsPer100g: 13.3, fatPer100g: 0.3, defaultGrams: 150, icon: Icons.eco_rounded),
    FoodItem(name: 'Авокадо', category: FoodCategory.fruits, kcalPer100g: 160, proteinPer100g: 2, carbsPer100g: 8.5, fatPer100g: 14.7, defaultGrams: 100, icon: Icons.eco_rounded),
    FoodItem(name: 'Апельсин', category: FoodCategory.fruits, kcalPer100g: 47, proteinPer100g: 0.9, carbsPer100g: 11.8, fatPer100g: 0.1, defaultGrams: 180, icon: Icons.eco_rounded),
    FoodItem(name: 'Груша', category: FoodCategory.fruits, kcalPer100g: 57, proteinPer100g: 0.4, carbsPer100g: 15.2, fatPer100g: 0.1, defaultGrams: 178, icon: Icons.eco_rounded),
    FoodItem(name: 'Виноград', category: FoodCategory.fruits, kcalPer100g: 69, proteinPer100g: 0.7, carbsPer100g: 18.1, fatPer100g: 0.2, defaultGrams: 150, icon: Icons.eco_rounded),
    FoodItem(name: 'Киви', category: FoodCategory.fruits, kcalPer100g: 61, proteinPer100g: 1.1, carbsPer100g: 14.7, fatPer100g: 0.5, defaultGrams: 76, icon: Icons.eco_rounded),
    FoodItem(name: 'Манго', category: FoodCategory.fruits, kcalPer100g: 60, proteinPer100g: 0.8, carbsPer100g: 15, fatPer100g: 0.4, defaultGrams: 165, icon: Icons.eco_rounded),
    FoodItem(name: 'Ананас', category: FoodCategory.fruits, kcalPer100g: 50, proteinPer100g: 0.5, carbsPer100g: 13.1, fatPer100g: 0.1, defaultGrams: 165, icon: Icons.eco_rounded),
    FoodItem(name: 'Клубника', category: FoodCategory.fruits, kcalPer100g: 32, proteinPer100g: 0.7, carbsPer100g: 7.7, fatPer100g: 0.3, defaultGrams: 150, icon: Icons.eco_rounded),
    FoodItem(name: 'Черника', category: FoodCategory.fruits, kcalPer100g: 57, proteinPer100g: 0.7, carbsPer100g: 14.5, fatPer100g: 0.3, defaultGrams: 150, icon: Icons.eco_rounded),
    FoodItem(name: 'Малина', category: FoodCategory.fruits, kcalPer100g: 52, proteinPer100g: 1.2, carbsPer100g: 11.9, fatPer100g: 0.7, defaultGrams: 125, icon: Icons.eco_rounded),
    FoodItem(name: 'Грейпфрут', category: FoodCategory.fruits, kcalPer100g: 42, proteinPer100g: 0.8, carbsPer100g: 10.7, fatPer100g: 0.1, defaultGrams: 230, icon: Icons.eco_rounded),
    FoodItem(name: 'Персик', category: FoodCategory.fruits, kcalPer100g: 39, proteinPer100g: 0.9, carbsPer100g: 9.5, fatPer100g: 0.3, defaultGrams: 150, icon: Icons.eco_rounded),
    FoodItem(name: 'Слива', category: FoodCategory.fruits, kcalPer100g: 46, proteinPer100g: 0.7, carbsPer100g: 11.4, fatPer100g: 0.3, defaultGrams: 66, icon: Icons.eco_rounded),
    FoodItem(name: 'Арбуз', category: FoodCategory.fruits, kcalPer100g: 30, proteinPer100g: 0.6, carbsPer100g: 7.6, fatPer100g: 0.2, defaultGrams: 280, icon: Icons.eco_rounded),
    FoodItem(name: 'Дыня', category: FoodCategory.fruits, kcalPer100g: 34, proteinPer100g: 0.8, carbsPer100g: 8.2, fatPer100g: 0.2, defaultGrams: 200, icon: Icons.eco_rounded),
    FoodItem(name: 'Гранат', category: FoodCategory.fruits, kcalPer100g: 83, proteinPer100g: 1.7, carbsPer100g: 18.7, fatPer100g: 1.2, defaultGrams: 150, icon: Icons.eco_rounded),
    FoodItem(name: 'Мандарин', category: FoodCategory.fruits, kcalPer100g: 53, proteinPer100g: 0.8, carbsPer100g: 13.3, fatPer100g: 0.3, defaultGrams: 100, icon: Icons.eco_rounded),
    FoodItem(name: 'Хурма', category: FoodCategory.fruits, kcalPer100g: 70, proteinPer100g: 0.6, carbsPer100g: 18.6, fatPer100g: 0.2, defaultGrams: 168, icon: Icons.eco_rounded),

    FoodItem(name: 'Салат овощной', category: FoodCategory.vegetables, kcalPer100g: 36, proteinPer100g: 1.2, carbsPer100g: 4.8, fatPer100g: 1.6, defaultGrams: 250, icon: Icons.grass_rounded),
    FoodItem(name: 'Брокколи на пару', category: FoodCategory.vegetables, kcalPer100g: 35, proteinPer100g: 3, carbsPer100g: 6, fatPer100g: 0.5, defaultGrams: 200, icon: Icons.grass_rounded),
    FoodItem(name: 'Помидоры', category: FoodCategory.vegetables, kcalPer100g: 18, proteinPer100g: 0.9, carbsPer100g: 3.9, fatPer100g: 0.2, defaultGrams: 150, icon: Icons.grass_rounded),
    FoodItem(name: 'Огурцы', category: FoodCategory.vegetables, kcalPer100g: 15, proteinPer100g: 0.7, carbsPer100g: 3.6, fatPer100g: 0.1, defaultGrams: 150, icon: Icons.grass_rounded),
    FoodItem(name: 'Морковь', category: FoodCategory.vegetables, kcalPer100g: 41, proteinPer100g: 0.9, carbsPer100g: 9.6, fatPer100g: 0.2, defaultGrams: 100, icon: Icons.grass_rounded),
    FoodItem(name: 'Перец болгарский', category: FoodCategory.vegetables, kcalPer100g: 26, proteinPer100g: 1, carbsPer100g: 6, fatPer100g: 0.3, defaultGrams: 120, icon: Icons.grass_rounded),
    FoodItem(name: 'Капуста белокочанная', category: FoodCategory.vegetables, kcalPer100g: 25, proteinPer100g: 1.3, carbsPer100g: 5.8, fatPer100g: 0.1, defaultGrams: 150, icon: Icons.grass_rounded),
    FoodItem(name: 'Цветная капуста', category: FoodCategory.vegetables, kcalPer100g: 25, proteinPer100g: 1.9, carbsPer100g: 5, fatPer100g: 0.3, defaultGrams: 150, icon: Icons.grass_rounded),
    FoodItem(name: 'Шпинат', category: FoodCategory.vegetables, kcalPer100g: 23, proteinPer100g: 2.9, carbsPer100g: 3.6, fatPer100g: 0.4, defaultGrams: 100, icon: Icons.grass_rounded),
    FoodItem(name: 'Лук репчатый', category: FoodCategory.vegetables, kcalPer100g: 40, proteinPer100g: 1.1, carbsPer100g: 9.3, fatPer100g: 0.1, defaultGrams: 80, icon: Icons.grass_rounded),
    FoodItem(name: 'Кабачки', category: FoodCategory.vegetables, kcalPer100g: 17, proteinPer100g: 1.2, carbsPer100g: 3.1, fatPer100g: 0.3, defaultGrams: 200, icon: Icons.grass_rounded),
    FoodItem(name: 'Баклажаны', category: FoodCategory.vegetables, kcalPer100g: 25, proteinPer100g: 1, carbsPer100g: 5.9, fatPer100g: 0.2, defaultGrams: 200, icon: Icons.grass_rounded),
    FoodItem(name: 'Свёкла', category: FoodCategory.vegetables, kcalPer100g: 43, proteinPer100g: 1.6, carbsPer100g: 9.6, fatPer100g: 0.2, defaultGrams: 150, icon: Icons.grass_rounded),
    FoodItem(name: 'Тыква', category: FoodCategory.vegetables, kcalPer100g: 26, proteinPer100g: 1, carbsPer100g: 6.5, fatPer100g: 0.1, defaultGrams: 200, icon: Icons.grass_rounded),
    FoodItem(name: 'Спаржа', category: FoodCategory.vegetables, kcalPer100g: 20, proteinPer100g: 2.2, carbsPer100g: 3.9, fatPer100g: 0.1, defaultGrams: 150, icon: Icons.grass_rounded),
    FoodItem(name: 'Стручковая фасоль', category: FoodCategory.vegetables, kcalPer100g: 31, proteinPer100g: 1.8, carbsPer100g: 7, fatPer100g: 0.2, defaultGrams: 150, icon: Icons.grass_rounded),
    FoodItem(name: 'Кукуруза', category: FoodCategory.vegetables, kcalPer100g: 96, proteinPer100g: 3.4, carbsPer100g: 21, fatPer100g: 1.5, defaultGrams: 150, icon: Icons.grass_rounded),
    FoodItem(name: 'Грибы шампиньоны', category: FoodCategory.vegetables, kcalPer100g: 27, proteinPer100g: 4.3, carbsPer100g: 0.6, fatPer100g: 1, defaultGrams: 150, icon: Icons.grass_rounded),
    FoodItem(name: 'Чеснок', category: FoodCategory.vegetables, kcalPer100g: 149, proteinPer100g: 6.4, carbsPer100g: 33, fatPer100g: 0.5, defaultGrams: 10, icon: Icons.grass_rounded),

    FoodItem(name: 'Творог 5%', category: FoodCategory.dairy, kcalPer100g: 110, proteinPer100g: 18, carbsPer100g: 3, fatPer100g: 2.5, defaultGrams: 200, icon: Icons.icecream_rounded),
    FoodItem(name: 'Греческий йогурт', category: FoodCategory.dairy, kcalPer100g: 73, proteinPer100g: 10, carbsPer100g: 4, fatPer100g: 2, defaultGrams: 200, icon: Icons.icecream_rounded),
    FoodItem(name: 'Молоко 2.5%', category: FoodCategory.dairy, kcalPer100g: 52, proteinPer100g: 3.2, carbsPer100g: 4.8, fatPer100g: 2, defaultGrams: 250, icon: Icons.local_drink_rounded),
    FoodItem(name: 'Кефир', category: FoodCategory.dairy, kcalPer100g: 41, proteinPer100g: 3.4, carbsPer100g: 4.7, fatPer100g: 1, defaultGrams: 250, icon: Icons.local_drink_rounded),
    FoodItem(name: 'Сметана 15%', category: FoodCategory.dairy, kcalPer100g: 158, proteinPer100g: 2.6, carbsPer100g: 3.2, fatPer100g: 15, defaultGrams: 30, icon: Icons.icecream_rounded),
    FoodItem(name: 'Йогурт натуральный', category: FoodCategory.dairy, kcalPer100g: 66, proteinPer100g: 5, carbsPer100g: 3.5, fatPer100g: 3.2, defaultGrams: 200, icon: Icons.icecream_rounded),
    FoodItem(name: 'Творог обезжиренный', category: FoodCategory.dairy, kcalPer100g: 71, proteinPer100g: 16, carbsPer100g: 1.3, fatPer100g: 0.3, defaultGrams: 200, icon: Icons.icecream_rounded),
    FoodItem(name: 'Сыр рикотта', category: FoodCategory.dairy, kcalPer100g: 174, proteinPer100g: 11, carbsPer100g: 3, fatPer100g: 13, defaultGrams: 100, icon: Icons.icecream_rounded),
    FoodItem(name: 'Молоко миндальное', category: FoodCategory.dairy, kcalPer100g: 17, proteinPer100g: 0.6, carbsPer100g: 0.6, fatPer100g: 1.4, defaultGrams: 250, icon: Icons.local_drink_rounded),
    FoodItem(name: 'Сливки 10%', category: FoodCategory.dairy, kcalPer100g: 118, proteinPer100g: 3, carbsPer100g: 4, fatPer100g: 10, defaultGrams: 50, icon: Icons.local_drink_rounded),
    FoodItem(name: 'Ряженка', category: FoodCategory.dairy, kcalPer100g: 54, proteinPer100g: 2.9, carbsPer100g: 4.2, fatPer100g: 2.5, defaultGrams: 250, icon: Icons.local_drink_rounded),

    FoodItem(name: 'Орехи миндаль', category: FoodCategory.nuts, kcalPer100g: 583, proteinPer100g: 21, carbsPer100g: 22, fatPer100g: 50, defaultGrams: 30, icon: Icons.spa_rounded),
    FoodItem(name: 'Арахисовая паста', category: FoodCategory.nuts, kcalPer100g: 594, proteinPer100g: 25, carbsPer100g: 19, fatPer100g: 50, defaultGrams: 32, icon: Icons.spa_rounded),
    FoodItem(name: 'Грецкий орех', category: FoodCategory.nuts, kcalPer100g: 654, proteinPer100g: 15, carbsPer100g: 14, fatPer100g: 65, defaultGrams: 30, icon: Icons.spa_rounded),
    FoodItem(name: 'Кешью', category: FoodCategory.nuts, kcalPer100g: 553, proteinPer100g: 18, carbsPer100g: 30, fatPer100g: 44, defaultGrams: 30, icon: Icons.spa_rounded),
    FoodItem(name: 'Фисташки', category: FoodCategory.nuts, kcalPer100g: 560, proteinPer100g: 20, carbsPer100g: 28, fatPer100g: 45, defaultGrams: 30, icon: Icons.spa_rounded),
    FoodItem(name: 'Фундук', category: FoodCategory.nuts, kcalPer100g: 628, proteinPer100g: 15, carbsPer100g: 17, fatPer100g: 61, defaultGrams: 30, icon: Icons.spa_rounded),
    FoodItem(name: 'Семена чиа', category: FoodCategory.nuts, kcalPer100g: 486, proteinPer100g: 17, carbsPer100g: 42, fatPer100g: 31, defaultGrams: 15, icon: Icons.spa_rounded),
    FoodItem(name: 'Семена льна', category: FoodCategory.nuts, kcalPer100g: 534, proteinPer100g: 18, carbsPer100g: 29, fatPer100g: 42, defaultGrams: 15, icon: Icons.spa_rounded),
    FoodItem(name: 'Тыквенные семечки', category: FoodCategory.nuts, kcalPer100g: 559, proteinPer100g: 30, carbsPer100g: 11, fatPer100g: 49, defaultGrams: 30, icon: Icons.spa_rounded),
    FoodItem(name: 'Кунжут', category: FoodCategory.nuts, kcalPer100g: 573, proteinPer100g: 18, carbsPer100g: 23, fatPer100g: 50, defaultGrams: 15, icon: Icons.spa_rounded),

    FoodItem(name: 'Рис отварной', category: FoodCategory.grains, kcalPer100g: 130, proteinPer100g: 2.5, carbsPer100g: 28, fatPer100g: 0.5, defaultGrams: 200, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Овсянка', category: FoodCategory.grains, kcalPer100g: 375, proteinPer100g: 12.5, carbsPer100g: 67.5, fatPer100g: 7.5, defaultGrams: 80, icon: Icons.breakfast_dining_rounded),
    FoodItem(name: 'Гречка отварная', category: FoodCategory.grains, kcalPer100g: 123, proteinPer100g: 4, carbsPer100g: 25, fatPer100g: 1, defaultGrams: 200, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Картофель запечёный', category: FoodCategory.grains, kcalPer100g: 86, proteinPer100g: 2, carbsPer100g: 20, fatPer100g: 0, defaultGrams: 250, icon: Icons.lunch_dining_rounded),
    FoodItem(name: 'Хлеб цельнозерновой', category: FoodCategory.grains, kcalPer100g: 267, proteinPer100g: 10, carbsPer100g: 46.7, fatPer100g: 3.3, defaultGrams: 60, icon: Icons.bakery_dining_rounded),
    FoodItem(name: 'Макароны', category: FoodCategory.grains, kcalPer100g: 140, proteinPer100g: 5, carbsPer100g: 28, fatPer100g: 1, defaultGrams: 200, icon: Icons.ramen_dining_rounded),
    FoodItem(name: 'Батат', category: FoodCategory.grains, kcalPer100g: 86, proteinPer100g: 1.6, carbsPer100g: 20, fatPer100g: 0, defaultGrams: 250, icon: Icons.lunch_dining_rounded),
    FoodItem(name: 'Киноа отварная', category: FoodCategory.grains, kcalPer100g: 120, proteinPer100g: 4.4, carbsPer100g: 21.3, fatPer100g: 1.9, defaultGrams: 185, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Булгур отварной', category: FoodCategory.grains, kcalPer100g: 83, proteinPer100g: 3.1, carbsPer100g: 18.6, fatPer100g: 0.2, defaultGrams: 180, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Кускус отварной', category: FoodCategory.grains, kcalPer100g: 112, proteinPer100g: 3.8, carbsPer100g: 23.2, fatPer100g: 0.2, defaultGrams: 180, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Перловка отварная', category: FoodCategory.grains, kcalPer100g: 109, proteinPer100g: 2.3, carbsPer100g: 23.7, fatPer100g: 0.4, defaultGrams: 180, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Пшено отварное', category: FoodCategory.grains, kcalPer100g: 119, proteinPer100g: 3.5, carbsPer100g: 23.7, fatPer100g: 1, defaultGrams: 180, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Хлеб белый', category: FoodCategory.grains, kcalPer100g: 265, proteinPer100g: 9, carbsPer100g: 49, fatPer100g: 3.2, defaultGrams: 60, icon: Icons.bakery_dining_rounded),
    FoodItem(name: 'Лаваш', category: FoodCategory.grains, kcalPer100g: 274, proteinPer100g: 9, carbsPer100g: 55, fatPer100g: 1.6, defaultGrams: 60, icon: Icons.bakery_dining_rounded),
    FoodItem(name: 'Мюсли', category: FoodCategory.grains, kcalPer100g: 375, proteinPer100g: 10, carbsPer100g: 66, fatPer100g: 6, defaultGrams: 60, icon: Icons.breakfast_dining_rounded),
    FoodItem(name: 'Хлопья кукурузные', category: FoodCategory.grains, kcalPer100g: 357, proteinPer100g: 7.5, carbsPer100g: 83, fatPer100g: 0.5, defaultGrams: 40, icon: Icons.breakfast_dining_rounded),
    FoodItem(name: 'Рис бурый отварной', category: FoodCategory.grains, kcalPer100g: 111, proteinPer100g: 2.6, carbsPer100g: 23, fatPer100g: 0.9, defaultGrams: 200, icon: Icons.rice_bowl_rounded),

    FoodItem(name: 'Яйца', category: FoodCategory.other, kcalPer100g: 156, proteinPer100g: 13, carbsPer100g: 1, fatPer100g: 11, defaultGrams: 100, icon: Icons.egg_rounded),
    FoodItem(name: 'Протеиновый шейк', category: FoodCategory.other, kcalPer100g: 220, proteinPer100g: 32, carbsPer100g: 14, fatPer100g: 4, defaultGrams: 100, icon: Icons.local_cafe_rounded),
    FoodItem(name: 'Тофу', category: FoodCategory.other, kcalPer100g: 80, proteinPer100g: 8.7, carbsPer100g: 2, fatPer100g: 4.7, defaultGrams: 150, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Оливковое масло', category: FoodCategory.other, kcalPer100g: 857, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100, defaultGrams: 14, icon: Icons.opacity_rounded),
    FoodItem(name: 'Яичный белок', category: FoodCategory.other, kcalPer100g: 52, proteinPer100g: 11, carbsPer100g: 0.7, fatPer100g: 0.2, defaultGrams: 100, icon: Icons.egg_rounded),
    FoodItem(name: 'Мёд', category: FoodCategory.other, kcalPer100g: 304, proteinPer100g: 0.3, carbsPer100g: 82, fatPer100g: 0, defaultGrams: 20, icon: Icons.opacity_rounded),
    FoodItem(name: 'Хумус', category: FoodCategory.other, kcalPer100g: 166, proteinPer100g: 8, carbsPer100g: 14, fatPer100g: 9.6, defaultGrams: 100, icon: Icons.rice_bowl_rounded),
    FoodItem(name: 'Тёмный шоколад 70%', category: FoodCategory.other, kcalPer100g: 546, proteinPer100g: 7.8, carbsPer100g: 46, fatPer100g: 31, defaultGrams: 25, icon: Icons.icecream_rounded),
    FoodItem(name: 'Протеиновый батончик', category: FoodCategory.other, kcalPer100g: 380, proteinPer100g: 30, carbsPer100g: 35, fatPer100g: 12, defaultGrams: 60, icon: Icons.local_cafe_rounded),
    FoodItem(name: 'Соевый соус', category: FoodCategory.other, kcalPer100g: 53, proteinPer100g: 8, carbsPer100g: 4.9, fatPer100g: 0, defaultGrams: 15, icon: Icons.opacity_rounded),
    FoodItem(name: 'Кокосовое масло', category: FoodCategory.other, kcalPer100g: 862, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100, defaultGrams: 14, icon: Icons.opacity_rounded),
    FoodItem(name: 'Сливочное масло', category: FoodCategory.other, kcalPer100g: 748, proteinPer100g: 0.5, carbsPer100g: 0.8, fatPer100g: 82.5, defaultGrams: 15, icon: Icons.opacity_rounded),
    FoodItem(name: 'Майонез', category: FoodCategory.other, kcalPer100g: 680, proteinPer100g: 1, carbsPer100g: 2.6, fatPer100g: 75, defaultGrams: 15, icon: Icons.opacity_rounded),
    FoodItem(name: 'Кетчуп', category: FoodCategory.other, kcalPer100g: 112, proteinPer100g: 1.7, carbsPer100g: 27, fatPer100g: 0.2, defaultGrams: 20, icon: Icons.opacity_rounded),
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
