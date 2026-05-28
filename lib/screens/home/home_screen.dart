// FILE: lib/screens/home/home_screen.dart
// ============================================================================
// HOME SCREEN - Role-Based Dashboard (Original Flow)
// ============================================================================
// All users go to /home after login, then RoleDashboard displays 
// role-specific content based on user.userRole
// Aligns with FYP Report: Figure 27 (Role Router), Section 3.4.1b
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ For debugPrint
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../config/app_colors.dart';
import '../../core/widgets/profile_card.dart';
import '../../core/widgets/role_dashboard.dart'; // ✅ Import RoleDashboard
import '../../core/widgets/logout_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cart = context.watch<CartProvider>();

    // ✅ Show loading while checking auth state
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Debug logging to trace role detection
    debugPrint('🏠 [HomeScreen] User loaded: ${user.email}');
    debugPrint('🏠 [HomeScreen] User role: "${user.userRole}"');
    debugPrint('🏠 [HomeScreen] isAdmin: ${user.isAdmin}');

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        title: Image.asset(
          'assets/logo_black.png',
          height: 120,
          fit: BoxFit.contain,
        ),
        actions: [
          // ✅ Only show cart icon for buyers
          if (user.userRole == 'buyer')
            Consumer<CartProvider>(
              builder: (context, cart, _) => Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                    tooltip: 'View Cart',
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '${cart.itemCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // ✅ Logout button for all roles
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => showLogoutDialog(context),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ User profile card
              ProfileCard(user: user),
              const SizedBox(height: 24),
              
              // ✅ Dashboard header
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              // ✅ ROLE DASHBOARD - Handles all role-specific content
              // This widget switches UI based on user.userRole
              RoleDashboard(userRole: user.userRole),
            ],
          ),
        ),
      ),
    );
  }
}