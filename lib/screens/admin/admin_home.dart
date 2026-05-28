// FILE: lib/screens/admin/admin_home.dart
// ============================================================================
// ADMIN HOME DASHBOARD
// ============================================================================
// Main admin dashboard matching prototype Figure 42
// - Displays platform statistics (Users, Listings, Donations, Orders)
// - Navigation cards for User, Item, Ads, and Issue management
// - Uses AdminProvider for state & data loading
// Aligns with FYP Report: UC-08, Section 4.3.1, Figure 42
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart'; // ✅ ADD THIS for logout

// Forward declarations for navigation (placeholder screens created below)
import 'admin_user_management.dart';
import 'admin_item_management.dart';
import 'admin_ads_management.dart';
import 'admin_issue_management.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  @override
  void initState() {
    super.initState();
    // Load dashboard stats after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final stats = adminProvider.stats;
    final isLoading = adminProvider.isLoading;
    final error = adminProvider.error;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text(
          '🛡️ Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // ✅ ADD THIS: Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => adminProvider.loadDashboard(),
            tooltip: 'Refresh Stats',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[600])),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => adminProvider.loadDashboard(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 SECTION 1: PLATFORM OVERVIEW (Stats Grid)
                      const Text(
                        'Platform Overview',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _buildStatCard('👥 Users', stats['users'] ?? 0, Colors.blue),
                          _buildStatCard('📦 Listings', stats['listings'] ?? 0, AppColors.primaryOrange),
                          _buildStatCard('🎁 Donations', stats['donations'] ?? 0, AppColors.secondaryGreen),
                          _buildStatCard('🧾 Orders', stats['orders'] ?? 0, Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 🔹 SECTION 2: MANAGEMENT NAVIGATION (4 Cards)
                      const Text(
                        'Management',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildManagementCard(
                        context,
                        '👥 User Management',
                        'Monitor and manage all users',
                        Icons.people,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUserManagement())),
                      ),
                      const SizedBox(height: 12),
                      _buildManagementCard(
                        context,
                        '📦 Item Management',
                        'Monitor food listings',
                        Icons.inventory,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminItemManagement())),
                      ),
                      const SizedBox(height: 12),
                      _buildManagementCard(
                        context,
                        '📢 Ads Management',
                        'Monitor donation ads',
                        Icons.campaign,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAdsManagement())),
                      ),
                      const SizedBox(height: 12),
                      _buildManagementCard(
                        context,
                        '⚠️ Issue Management',
                        'Handle flagged content',
                        Icons.report_problem,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminIssueManagement())),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 🔹 SECTION 3: Admin Notes (Optional)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📌 Admin Guidelines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 8),
                            Text(
                              '• Review flagged content within 24 hours\n• Deactivate users violating community guidelines\n• Remove inappropriate listings/donations promptly',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ==================================================================
  // ✅ LOGOUT DIALOG METHOD
  // ==================================================================
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog first
              
              // Use AuthProvider to sign out
              final authProvider = context.read<AuthProvider>();
              await authProvider.signOut();
              
              // Navigate to login screen and remove all previous routes
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false, // Remove all previous routes
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // STAT CARD WIDGET (Matches Prototype Design)
  // ==================================================================
  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // MANAGEMENT NAVIGATION CARD WIDGET (Matches Prototype)
  // ==================================================================
  Widget _buildManagementCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 24, color: AppColors.primaryOrange),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}