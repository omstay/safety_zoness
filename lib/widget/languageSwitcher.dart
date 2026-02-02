import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../lib/l10n/language_provider.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEnglish = languageProvider.locale.languageCode == 'en';

    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final newLocale = isEnglish ? const Locale('ta') : const Locale('en');
            languageProvider.setLocale(newLocale);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.language,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isEnglish ? 'த' : 'EN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Alternative: Popup Menu Style
class LanguageSwitcherMenu extends StatelessWidget {
  const LanguageSwitcherMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      onSelected: (String languageCode) {
        languageProvider.setLocale(Locale(languageCode));
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'en',
          child: Row(
            children: [
              Icon(
                Icons.check,
                color: languageProvider.locale.languageCode == 'en'
                    ? Colors.blue
                    : Colors.transparent,
              ),
              const SizedBox(width: 8),
              const Text('English'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'ta',
          child: Row(
            children: [
              Icon(
                Icons.check,
                color: languageProvider.locale.languageCode == 'ta'
                    ? Colors.blue
                    : Colors.transparent,
              ),
              const SizedBox(width: 8),
              const Text('தமிழ் (Tamil)'),
            ],
          ),
        ),
      ],
    );
  }
}