import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.purple,
            title: const Text('⚙️ Admin Panel', style: TextStyle(color: Colors.white)),
            floating: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Platform Controls',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildAdminOption('👥 Manage Users', Icons.people, () {}),
                  _buildAdminOption('🛡️ Moderate Content', Icons.shield, () {}),
                  _buildAdminOption('📊 View Analytics', Icons.analytics, () {}),
                  _buildAdminOption('⚙️ App Settings', Icons.settings, () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminOption(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}