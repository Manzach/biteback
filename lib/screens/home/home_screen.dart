import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart'; // ✅ Added for cart badge
import '../../config/app_colors.dart';
import '../../core/widgets/profile_card.dart';
import '../../core/widgets/role_dashboard.dart';
import '../../core/widgets/logout_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cart = context.watch<CartProvider>(); // ✅ Watch cart for live badge

    // 🔒 Safety fallback (should never happen with proper auth guard)
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        title: const Text(
          'bite.',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          // ✅ CART ICON (Only show for buyers)
          if (user.userRole == 'buyer') // ✅ RBAC check: only buyers see cart
            Consumer<CartProvider>(
              builder: (context, cart, _) => Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/cart'), // ✅ Navigate to cart
                    tooltip: 'View Cart',
                  ),
                  // ✅ Live Badge (only shows if items in cart)
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
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // ✅ LOGOUT ICON (existing)
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
              // 👤 User Profile Card
              ProfileCard(user: user),
              const SizedBox(height: 24),
              
              // 🎯 Dashboard Title
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              // 🔄 Role-Based Content
              RoleDashboard(userRole: user.userRole),
            ],
          ),
        ),
      ),
    );
  }
}