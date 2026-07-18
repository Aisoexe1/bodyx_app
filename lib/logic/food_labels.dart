import 'package:flutter/widgets.dart';

import '../data/food_database.dart';
import '../l10n/gen/app_localizations.dart';

/// [FoodCategory] has no inherent display text of its own — this maps each
/// value to a localized label, the same pattern as [goalLabel] for
/// [UserProfile.goal].
String foodCategoryLabel(BuildContext context, FoodCategory category) {
  final l10n = AppLocalizations.of(context)!;
  switch (category) {
    case FoodCategory.meat:
      return l10n.foodCategoryMeat;
    case FoodCategory.cheese:
      return l10n.foodCategoryCheese;
    case FoodCategory.fruits:
      return l10n.foodCategoryFruits;
    case FoodCategory.vegetables:
      return l10n.foodCategoryVegetables;
    case FoodCategory.dairy:
      return l10n.foodCategoryDairy;
    case FoodCategory.nuts:
      return l10n.foodCategoryNuts;
    case FoodCategory.grains:
      return l10n.foodCategoryGrains;
    case FoodCategory.other:
      return l10n.foodCategoryOther;
  }
}
