import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'order_history_screen.dart';
import 'active_order_screen.dart';
import 'update_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  Profile Header
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primaryOrange.withOpacity(0.1),
                            child: Text(
                              user.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName ?? 'User',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '@${user.fullName?.replaceAll(' ', '').toLowerCase() ?? 'user'}',
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  //  Contact Details
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.email_outlined, user.email),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.phone_outlined, user.phoneNumber ?? 'Not provided'),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.location_on_outlined, 'IIUM Campus, Gombak'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  //  Menu Items
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    title: 'Order History',
                    subtitle: 'View your past purchases',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    context,
                    icon: Icons.qr_code_2,
                    title: 'Active Orders',
                    subtitle: 'Scan QR for pickup',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveOrderScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    context,
                    icon: Icons.edit_outlined,
                    title: 'Update Profile',
                    subtitle: 'Edit your personal details',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateProfileScreen())),
                  ),
                  const SizedBox(height: 24),

                  // ℹ️ App Version
                  Center(
                    child: Text(
                      'BiteBack v0.1.0',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String? text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text ?? 'N/A',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryOrange, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}