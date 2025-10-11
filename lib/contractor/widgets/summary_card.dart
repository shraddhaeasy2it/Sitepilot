import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final Color cardColor;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.cardColor = AppColors.cardBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}