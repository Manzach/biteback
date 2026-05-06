import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class RoleBadge extends StatelessWidget {
  final String role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final colorConfig = _getRoleConfig(role);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorConfig.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorConfig.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            colorConfig.icon,
            size: 12,
            color: colorConfig.color,
          ),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              color: colorConfig.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Role styling config - easy to update in one place
  ({Color color, IconData icon}) _getRoleConfig(String role) {
    return switch (role.toLowerCase()) {
      'buyer'  => (color: AppColors.primaryOrange, icon: Icons.shopping_bag_outlined),
      'seller' => (color: AppColors.secondaryGreen, icon: Icons.storefront_outlined),
      'donor'  => (color: Colors.blueAccent, icon: Icons.volunteer_activism_outlined),
      'admin'  => (color: Colors.purple, icon: Icons.admin_panel_settings_outlined),
      _        => (color: Colors.grey, icon: Icons.person_outlined),
    };
  }
}