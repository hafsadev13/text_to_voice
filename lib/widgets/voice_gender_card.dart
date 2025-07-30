import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class VoiceGenderCard extends StatelessWidget {
  final bool isMaleVoice;
  final VoidCallback onToggle;

  const VoiceGenderCard({
    super.key,
    required this.isMaleVoice,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      gradient: AppColors.secondaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.voice_over_off,
                color: AppColors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Voice Gender',
                style: AppTextStyles.titleMedium(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Male Voice Button
              Expanded(
                child: GestureDetector(
                  onTap: isMaleVoice ? null : onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isMaleVoice ? AppColors.white : AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isMaleVoice ? Colors.transparent : AppColors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.man,
                          color: isMaleVoice ? AppColors.secondary : AppColors.white,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Male',
                          style: TextStyle(
                            color: isMaleVoice ? AppColors.secondary : AppColors.white,
                            fontSize: 14,
                            fontWeight: isMaleVoice ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Female Voice Button
              Expanded(
                child: GestureDetector(
                  onTap: !isMaleVoice ? null : onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: !isMaleVoice ? AppColors.white : AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: !isMaleVoice ? Colors.transparent : AppColors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.woman,
                          color: !isMaleVoice ? AppColors.secondary : AppColors.white,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Female',
                          style: TextStyle(
                            color: !isMaleVoice ? AppColors.secondary : AppColors.white,
                            fontSize: 14,
                            fontWeight: !isMaleVoice ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Choose your preferred voice type',
            style: TextStyle(
              color: AppColors.white.withOpacity(0.8),
              fontSize: 12,
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