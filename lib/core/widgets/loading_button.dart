import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class LoadingButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color color;

  const LoadingButton({
    super.key,
    required this.text,
    required this.isLoading,
    this.onPressed,
    this.color = AppColors.primaryOrange,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25), // Figma spec
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}