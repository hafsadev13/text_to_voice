import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class TextInputCard extends StatelessWidget {
  final TextEditingController controller;

  const TextInputCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Enter Text to Speak',
                style: AppTextStyles.bodyMedium(context)?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              hintText: 'Type your sentence here...',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}