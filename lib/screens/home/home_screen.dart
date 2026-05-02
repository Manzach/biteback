import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_colors.dart';
import '../../models/user_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

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
        title: const Text('bite.', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () => _showLogoutDialog(context),
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
              _buildProfileCard(user),
              const SizedBox(height: 24),
              
              // 🎯 Role-Based Dashboard Content
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildRoleDashboard(user.userRole),
            ],
          ),
        ),
      ),
    );
  }

  // 🧑‍💼 Profile Card
  Widget _buildProfileCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grayBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryOrange.withOpacity(0.2),
            child: Text(
              user.fullName?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 24, color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user.email, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 6),
                _buildRoleBadge(user.userRole),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ Role Badge
  Widget _buildRoleBadge(String role) {
    final color = switch (role) {
      'buyer' => AppColors.primaryOrange,
      'seller' => AppColors.secondaryGreen,
      'donor' => Colors.blueAccent,
      'admin' => Colors.purple,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 🔄 Role-Based Content Switcher
  Widget _buildRoleDashboard(String role) {
    return switch (role) {
      'buyer' => _buildSection('🛒 Browse Rescued Food', 'Find discounted near-expiry items around campus.', Icons.restaurant_menu),
      'seller' => _buildSection('🏪 Manage Listings', 'Post surplus food & track your sales.', Icons.storefront),
      'donor' => _buildSection('🎁 Post Donations', 'Share food with those in need & track impact.', Icons.volunteer_activism),
      'admin' => _buildSection('⚙️ Platform Controls', 'Moderate content, manage users & view analytics.', Icons.admin_panel_settings),
      _ => const Center(child: Text('Unknown role')),
    };
  }

  // 📦 Reusable Section Card
  Widget _buildSection(String title, String desc, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.primaryOrange),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {}, // Day 3: Add navigation to feature screens
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text('Get Started', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // 🔚 Logout Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}