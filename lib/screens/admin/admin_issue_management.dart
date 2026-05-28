// FILE: lib/screens/admin/admin_issue_management.dart
// ============================================================================
// ADMIN ISSUE MANAGEMENT SCREEN
// ============================================================================
// Allows admins to view, resolve, or delete user-submitted reports (UC-08)
// Uses AdminProvider to fetch reports and perform moderation actions.
// Aligns with FYP Report: Table 14 (Admin Log), UC-08, Figure 42
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/admin_provider.dart';

class AdminIssueManagement extends StatefulWidget {
  const AdminIssueManagement({super.key});

  @override
  State<AdminIssueManagement> createState() => _AdminIssueManagementState();
}

class _AdminIssueManagementState extends State<AdminIssueManagement> {
  @override
  void initState() {
    super.initState();
    // Load reports when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final reports = adminProvider.reports;
    final isLoading = adminProvider.isLoading;
    final error = adminProvider.error;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text('⚠️ Issue Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => adminProvider.loadReports(),
            tooltip: 'Refresh Reports',
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
                        ElevatedButton(onPressed: () => adminProvider.loadReports(), child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : reports.isEmpty
                  ? const Center(child: Text('No reports found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        // Skip already resolved/deleted reports (optional)
                        if (report['status'] == 'Deleted') return const SizedBox.shrink();

                        return _buildReportCard(report, adminProvider);
                      },
                    ),
    );
  }

  // ==================================================================
  // REPORT CARD WIDGET
  // ==================================================================
  Widget _buildReportCard(Map<String, dynamic> report, AdminProvider provider) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final status = report['status'] as String? ?? 'Pending';
    final reportType = report['report_type'] as String? ?? 'listing';
    final isPending = status == 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER: Title + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report['title'] ?? 'Untitled Report',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // REPORT TYPE BADGE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Type: ${reportType.toUpperCase()}',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 12),

            // DESCRIPTION BOX
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                report['description'] ?? 'No description provided',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),

            // REPORTER INFO + DATE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reported by: ${_formatUserId(report['reported_by'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '📅 ${dateFormat.format(DateTime.parse(report['created_at']))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ACTION BUTTONS (Only show for Pending reports)
            if (isPending)
              Row(
                children: [
                  // RESOLVE BUTTON
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showResolveDialog(context, report, provider),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Resolve'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondaryGreen,
                        side: BorderSide(color: AppColors.secondaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // DELETE BUTTON
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDeleteDialog(context, report, provider),
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // STATUS COLOR HELPER
  // ==================================================================
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return AppColors.secondaryGreen;
      case 'deleted':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // ==================================================================
  // FORMAT USER ID FOR DISPLAY
  // ==================================================================
  String _formatUserId(String? userId) {
    if (userId == null || userId.isEmpty) return 'Unknown';
    return userId.length > 8 ? '${userId.substring(0, 8)}...' : userId;
  }

  // ==================================================================
  // RESOLVE CONFIRMATION DIALOG
  // ==================================================================
  void _showResolveDialog(BuildContext context, Map<String, dynamic> report, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resolve Report?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mark "${report['title']}" as resolved?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✅ This report will be marked as resolved and removed from the pending list.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.resolveReport(report['id']);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report resolved successfully'), backgroundColor: AppColors.secondaryGreen),
              );
            },
            child: const Text('Resolve', style: TextStyle(color: AppColors.secondaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // DELETE CONFIRMATION DIALOG
  // ==================================================================
  void _showDeleteDialog(BuildContext context, Map<String, dynamic> report, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Report?', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${report['title']}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ This action cannot be undone. The report will be permanently deleted.',
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteReport(report['id']);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report deleted successfully'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}