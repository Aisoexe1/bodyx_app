import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';

/// Single source of truth for supported-language display names — shared by
/// the Settings language row and the sign-in screen's language picker.
const kSupportedLocaleLabels = <String, String>{
  'en': 'English (US)',
  'ru': 'Русский',
  'uk': 'Українська',
};

/// Shows the shared language-picker bottom sheet. Always sets an *explicit*
/// [Locale] — never `null` — so picking "English" truly means English
/// regardless of the device's system language. (Previously "English" mapped
/// to `null`/"follow system locale", so picking it on a Russian-system phone
/// silently kept showing Russian — see [[Bugs]].)
void showLanguagePicker(BuildContext context) {
  final appState = context.read<AppState>();
  final currentCode = appState.locale?.languageCode ?? 'en';
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: kSupportedLocaleLabels.entries.map((entry) {
          final selected = currentCode == entry.key;
          return ListTile(
            title: Text(entry.value,
                style: const TextStyle(color: AppColors.textPrimary)),
            trailing: selected
                ? const Icon(Icons.check_rounded, color: AppColors.primaryBright)
                : null,
            onTap: () {
              appState.setLocale(Locale(entry.key));
              Navigator.pop(sheetContext);
            },
          );
        }).toList(),
      ),
    ),
  );
}
