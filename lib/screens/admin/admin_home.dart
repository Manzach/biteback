// FILE: lib/screens/admin/admin_home.dart
// ============================================================================
// ADMIN HOME DASHBOARD (Cleaned & Exam-Ready)
// ============================================================================
// Main admin dashboard matching prototype Figure 42
// - Displays real-time platform statistics (Users, Listings, Donations, Orders)
// - Navigation cards for User, Item, Ads, and Issue management (UC-08)
// - Uses AdminProvider for state & data loading
// - Charts/metrics removed per FYP scope (planned for Phase 2)
// Aligns with FYP Report: UC-08, Section 4.3.1, Figure 42
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ For debugPrint
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

// Forward declarations for navigation
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
      debugPrint('🔍 [AdminHome] initState: Loading dashboard stats...');
      context.read<AdminProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final isLoading = adminProvider.isLoading;
    final error = adminProvider.error;

    debugPrint('🔄 [AdminHome] build() called - isLoading: $isLoading, error: $error');

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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              debugPrint('🔄 [AdminHome] Manual refresh triggered by user');
              await adminProvider.loadDashboard();
              debugPrint('✅ [AdminHome] Manual refresh complete');
            },
            tooltip: 'Refresh Stats',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorState(error, () => adminProvider.loadDashboard())
              : RefreshIndicator(
                  onRefresh: () async {
                    debugPrint('🔄 [AdminHome] Pull-to-refresh triggered');
                    await adminProvider.loadDashboard();
                    debugPrint('✅ [AdminHome] Pull-to-refresh complete');
                  },
                  color: AppColors.primaryOrange,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 SECTION 1: REAL-TIME PLATFORM STATS
                        const Text(
                          'Platform Overview',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        
                        // ✅ WRAP STATS GRID IN Consumer TO ISOLATE REBUILDS
                        Consumer<AdminProvider>(
                          builder: (context, provider, child) {
                            final stats = provider.stats;
                            debugPrint('📊 [AdminHome] Consumer rebuild - Stats: $stats');
                            
                            return GridView.count(
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
                            );
                          },
                        ),
                        
                        const SizedBox(height: 24),

                        // 🔹 SECTION 2: MANAGEMENT NAVIGATION (Core UC-08)
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

                        // 🔹 Admin Guidelines
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
                ),
    );
  }

  // ==================================================================
  // HELPER WIDGETS
  // ==================================================================
  Widget _buildStatCard(String title, int count, Color color) {
    debugPrint('🎨 [AdminHome] Building stat card: $title = $count');
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

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[600])),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // ✅ LOGOUT DIALOG
  // ==================================================================
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}