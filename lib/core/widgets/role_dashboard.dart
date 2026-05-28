// FILE: lib/core/widgets/role_dashboard.dart
// ============================================================================
// ROLE DASHBOARD WIDGET
// ============================================================================
// Displays role-specific dashboard content based on user.userRole
// Aligns with FYP Report: Figure 27 (Role Router), Section 3.4.1b
// ============================================================================

import 'package:flutter/material.dart';
import '../../screens/buyer/buyer_home.dart';
import '../../screens/seller/seller_home.dart';
import '../../screens/donor/donor_home.dart';
import '../../screens/admin/admin_home.dart';
import 'dashboard_section.dart';

class RoleDashboard extends StatelessWidget {
  // ✅ Make userRole nullable to handle null/unknown roles safely
  final String? userRole;

  const RoleDashboard({super.key, this.userRole});

  @override
  Widget build(BuildContext context) {
    // ✅ Handle null role gracefully
    final role = userRole?.toLowerCase() ?? 'buyer';
    final config = _getRoleConfig(role, context);
    
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
  }) _getRoleConfig(String role, BuildContext context) {
    return switch (role) {
      // ✅ BUYER: Browse food + donations
      'buyer' => (
          title: '🛒 Browse Rescued Food & Donations',
          description: 'Find discounted & free near-expiry food around campus.',
          icon: Icons.restaurant_menu_outlined,
          buttonText: 'Explore Items',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BuyerHome()),
            );
          },
          accentColor: Colors.orange,
        ),

      // ✅ SELLER: Manage listings
      'seller' => (
          title: '🏪 Manage Listings',
          description: 'Post surplus food & track your sales.',
          icon: Icons.storefront_outlined,
          buttonText: 'View My Listings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SellerHome()),
            );
          },
          accentColor: Colors.green,
        ),

      // ✅ DONOR: Post donations
      'donor' => (
          title: '🎁 Post Donations',
          description: 'Share food with those in need & track impact.',
          icon: Icons.volunteer_activism_outlined,
          buttonText: 'Post Donation',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DonorHome()),
            );
          },
          accentColor: Colors.blue,
        ),

      // ✅ ADMIN: Platform controls (FIXED: Was TODO, now navigates!)
      'admin' => (
          title: '🛡️ Platform Controls',
          description: 'Moderate content, manage users & view analytics.',
          icon: Icons.admin_panel_settings_outlined,
          buttonText: 'Open Dashboard',
          onPressed: () {
            // ✅ ACTUAL NAVIGATION TO ADMIN HOME
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminHome()),
            );
          },
          accentColor: Colors.purple,
        ),

      // ✅ DEFAULT: Fallback for unknown/null roles
      _ => (
          title: '👋 Welcome!',
          description: 'Select your role in settings to get started.',
          icon: Icons.info_outline,
          buttonText: 'Update Profile',
          onPressed: () {
            // Optional: Navigate to profile edit if implemented
            // Navigator.pushNamed(context, '/profile/edit');
          },
          accentColor: Colors.grey,
        ),
    };
  }
}