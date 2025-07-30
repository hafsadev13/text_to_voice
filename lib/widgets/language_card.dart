import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class LanguageCard extends StatelessWidget {
  final String selectedLanguage;
  final Map<String, String> languages;
  final Function(String?) onLanguageChanged;

  const LanguageCard({
    super.key,
    required this.selectedLanguage,
    required this.languages,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      gradient: AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.language,
                color: AppColors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Select Language',
                style: AppTextStyles.titleMedium(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: DropdownButton<String>(
              value: selectedLanguage,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down),
              items: languages.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: AppTextStyles.bodyMedium(context),
                  ),
                );
              }).toList(),
              onChanged: onLanguageChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, required Gradient gradient}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}