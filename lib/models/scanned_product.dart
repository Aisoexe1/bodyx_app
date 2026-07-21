/// Open Food Facts' A–E quality grade — combines nutrition (sugar, salt,
/// saturated fat, fiber, protein) into one letter; A is the best score, E
/// the worst. `null` means the product doesn't have one computed.
enum NutriScoreGrade { a, b, c, d, e }

/// A product looked up by barcode — never persisted on its own; logging it
/// converts the chosen gram amount straight into a [MealEntry].
class ScannedProduct {
  const ScannedProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.nutriScore,
    this.novaGroup,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.servingGrams,
  });

  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final NutriScoreGrade? nutriScore;

  /// Open Food Facts' 1–4 processing-level classification (NOVA); 1 is
  /// unprocessed/minimally processed, 4 is ultra-processed. `null` means
  /// the product doesn't have one computed.
  final int? novaGroup;

  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  /// The product's own labeled serving size in grams, if it has one —
  /// used to seed the grams picker with a realistic amount instead of a
  /// flat 100g default.
  final int? servingGrams;

  int kcalFor(int grams) => (kcalPer100g * grams / 100).round();
  int proteinFor(int grams) => (proteinPer100g * grams / 100).round();
  int carbsFor(int grams) => (carbsPer100g * grams / 100).round();
  int fatFor(int grams) => (fatPer100g * grams / 100).round();
}
