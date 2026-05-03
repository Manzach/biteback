import 'package:flutter/material.dart';
import 'dashboard_section.dart';

class RoleDashboard extends StatelessWidget {
  final String userRole;

  const RoleDashboard({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final config = _getRoleConfig(userRole);
    
    return DashboardSection(
      title: config.title,
      description: config.description,
      icon: config.icon,
      buttonText: config.buttonText,
      onPressed: config.onPressed,
      accentColor: config.accentColor,
    );
  }

  // 🎯 Role-based content config - single source of truth
  ({
    String title,
    String description,
    IconData icon,
    String buttonText,
    VoidCallback? onPressed,
    Color accentColor,
  }) _getRoleConfig(String role) {
    return switch (role.toLowerCase()) {
      'buyer' => (
          title: '🛒 Browse Rescued Food',
          description: 'Find discounted near-expiry items around campus.',
          icon: Icons.restaurant_menu_outlined,
          buttonText: 'Explore Items',
          onPressed: () {/* TODO: Navigate to buyer feed */},
          accentColor: Colors.orange,
        ),
      'seller' => (
          title: '🏪 Manage Listings',
          description: 'Post surplus food & track your sales.',
          icon: Icons.storefront_outlined,
          buttonText: 'Create Listing',
          onPressed: () {/* TODO: Navigate to seller dashboard */},
          accentColor: Colors.green,
        ),
      'donor' => (
          title: '🎁 Post Donations',
          description: 'Share food with those in need & track impact.',
          icon: Icons.volunteer_activism_outlined,
          buttonText: 'Post Donation',
          onPressed: () {/* TODO: Navigate to donation form */},
          accentColor: Colors.blue,
        ),
      'admin' => (
          title: '⚙️ Platform Controls',
          description: 'Moderate content, manage users & view analytics.',
          icon: Icons.admin_panel_settings_outlined,
          buttonText: 'Open Dashboard',
          onPressed: () {/* TODO: Navigate to admin panel */},
          accentColor: Colors.purple,
        ),
      _ => (
          title: 'Welcome!',
          description: 'Select your role in settings to get started.',
          icon: Icons.info_outline,
          buttonText: 'Update Profile',
          onPressed: () {/* TODO: Navigate to profile edit */},
          accentColor: Colors.grey,
        ),
    };
  }
}