// FILE: lib/screens/admin/admin_user_management.dart
// ============================================================================
// ADMIN USER MANAGEMENT SCREEN
// ============================================================================
// Lists all users and allows activating/deactivating accounts (UC-08)
// Uses AdminProvider to fetch and update user status.
// Aligns with FYP Report: Table 10 (User), UC-08, Figure 42
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';

class AdminUserManagement extends StatefulWidget {
  const AdminUserManagement({super.key});

  @override
  State<AdminUserManagement> createState() => _AdminUserManagementState();
}

class _AdminUserManagementState extends State<AdminUserManagement> {
  @override
  void initState() {
    super.initState();
    // Load users when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final users = adminProvider.users;
    final isLoading = adminProvider.isLoading;
    final error = adminProvider.error;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text('👥 User Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => adminProvider.loadUsers(),
            tooltip: 'Refresh Users',
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
                          onPressed: () => adminProvider.loadUsers(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : users.isEmpty
                  ? const Center(child: Text('No users found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isActive = user.accountStatus == 'active';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryOrange,
                              child: Text(
                                (user.fullName ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              user.fullName ?? 'Unknown User',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.email, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Role Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user.userRole).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        user.userRole.toUpperCase(),
                                        style: TextStyle(
                                          color: _getRoleColor(user.userRole),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isActive ? AppColors.secondaryGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          color: isActive ? AppColors.secondaryGreen : Colors.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'toggle') {
                                  // Toggle status
                                  final newStatus = isActive ? 'inactive' : 'active';
                                  _showConfirmationDialog(context, user, newStatus, adminProvider);
                                } else if (value == 'delete') {
                                  _showDeleteDialog(context, user, adminProvider);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isActive ? Icons.block : Icons.check_circle,
                                        color: isActive ? Colors.red : AppColors.secondaryGreen,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(isActive ? 'Deactivate' : 'Activate'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text('Delete Account'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            tileColor: isActive ? Colors.transparent : Colors.grey[100],
                          ),
                        );
                      },
                    ),
    );
  }

  // ==================================================================
  // ROLE COLOR HELPER
  // ==================================================================
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'seller':
        return AppColors.primaryOrange;
      case 'donor':
        return AppColors.secondaryGreen;
      case 'buyer':
      default:
        return Colors.blue;
    }
  }

  // ==================================================================
  // CONFIRMATION DIALOG FOR TOGGLE STATUS
  // ==================================================================
  void _showConfirmationDialog(BuildContext context, UserModel user, String newStatus, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${newStatus == 'active' ? 'Activate' : 'Deactivate'} User?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to ${newStatus == 'active' ? 'activate' : 'deactivate'} "${user.fullName}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: newStatus == 'active' ? AppColors.secondaryGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                newStatus == 'active'
                    ? '✅ User will be able to log in and use the app.'
                    : '⚠️ User will be unable to access the app until reactivated.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.updateUserStatus(user.id, newStatus);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User ${newStatus == 'active' ? 'activated' : 'deactivated'} successfully'),
                  backgroundColor: AppColors.secondaryGreen,
                ),
              );
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // DELETE CONFIRMATION DIALOG
  // ==================================================================
  void _showDeleteDialog(BuildContext context, UserModel user, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${user.fullName}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ This action cannot be undone. All user data, orders, and listings will be permanently removed.',
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteUser(user.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User account deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}