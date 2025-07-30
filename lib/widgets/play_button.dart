import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class PlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isInitialized;
  final VoidCallback onPressed;
  final Animation<double> pulseAnimation;

  const PlayButton({
    super.key,
    required this.isPlaying,
    required this.isInitialized,
    required this.onPressed,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isPlaying ? pulseAnimation.value : 1.0,
          child: Container(
            width: 200,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: isPlaying
                    ? [
                  AppColors.red.shade400,
                  AppColors.red.shade600,
                ]
                    : [
                  AppColors.primary,
                  AppColors.secondary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isPlaying ? AppColors.red : AppColors.primary)
                      .withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isInitialized ? onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.transparent,
                shadowColor: AppColors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 24,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPlaying ? 'Stop' : 'Play',
                    style: AppTextStyles.button(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}