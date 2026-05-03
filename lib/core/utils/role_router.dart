// lib/app/role_router.dart

import 'package:flutter/material.dart';
import '../../screens/buyer/buyer_home.dart';
import '../../screens/seller/seller_home.dart';
import '../../screens/donor/donor_home.dart';
import '../../screens/admin/admin_home.dart';

/// Routes users to their role-specific home screen.
class RoleRouter {
  /// Returns the correct home screen for the user's role.
  static Widget getHomeScreen(String role) {
    return switch (role.toLowerCase()) {
      'buyer' => const BuyerHome(),
      'seller' => const SellerHome(),
      'donor' => const DonorHome(),
      'admin' => const AdminHome(),
      _ => const _UnknownRoleScreen(),
    };
  }

  /// Optional: Check if role can access a route (for guards)
  static bool canAccess(String role, String route) {
    final allowed = {
      'buyer': ['/browse', '/cart', '/profile'],
      'seller': ['/listings', '/orders', '/profile'],
      'donor': ['/donations', '/profile'],
      'admin': ['/moderation', '/analytics', '/users'],
    };
    return allowed[role]?.contains(route) ?? true; // default: allow
  }
}

/// Fallback screen for unknown/invalid roles
class _UnknownRoleScreen extends StatelessWidget {
  const _UnknownRoleScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Role not configured',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please contact support to update your account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}