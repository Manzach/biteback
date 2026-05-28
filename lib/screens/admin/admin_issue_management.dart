// FILE: lib/screens/admin/admin_issue_management.dart
// ============================================================================
// ADMIN ISSUE MANAGEMENT SCREEN
// ============================================================================
// Allows admins to view, resolve, or dismiss user-submitted reports (UC-08)
// Uses ReportProvider to fetch reports and perform moderation actions.
// Aligns with FYP Report: Table 14 (Admin Log), UC-08, Figure 42
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/report_provider.dart';

class AdminIssueManagement extends StatefulWidget {
  const AdminIssueManagement({super.key});

  @override
  State<AdminIssueManagement> createState() => _AdminIssueManagementState();
}

class _AdminIssueManagementState extends State<AdminIssueManagement> {
  @override
  void initState() {
    super.initState();
    // ✅ Load pending reports when screen opens using ReportProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadPendingReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Watch ReportProvider for changes
    final reportProvider = context.watch<ReportProvider>();
    final reports = reportProvider.pendingReports;
    final isLoading = reportProvider.isLoading;
    final error = reportProvider.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text('⚠️ Issue Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => reportProvider.loadPendingReports(),
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
                        ElevatedButton(
                          onPressed: () => reportProvider.loadPendingReports(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : reports.isEmpty
                  ? const Center(child: Text('No pending reports found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return _buildReportCard(report, reportProvider);
                      },
                    ),
    );
  }

  // ==================================================================
  // REPORT CARD WIDGET - Handles Raw Data (No Profiles Join)
  // ==================================================================
  Widget _buildReportCard(Map<String, dynamic> report, ReportProvider provider) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final status = report['status'] as String? ?? 'Pending';
    final reportType = report['report_type'] as String? ?? 'Unknown';
    final targetId = report['target_id'] as String? ?? 'N/A';
    final title = report['title'] as String? ?? 'Untitled Report';
    final description = report['description'] as String?;
    final reportedBy = report['reported_by'] as String? ?? 'Unknown'; // UUID
    final reason = report['reason'] as String? ?? 'Unspecified';
    final createdAt = report['created_at'] as String?;

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
                    title,
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

            // REPORT TYPE & REASON BADGES
            Row(
              children: [
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Reason: ${reason.replaceAll('_', ' ')}',
                    style: TextStyle(fontSize: 11, color: AppColors.primaryOrange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // DESCRIPTION BOX (if available)
            if (description != null && description.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            const SizedBox(height: 12),

            // REPORTER INFO (UUID) + TARGET ID + DATE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'By: ${_formatUserId(reportedBy)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (createdAt != null)
                  Text(
                    '📅 ${dateFormat.format(DateTime.parse(createdAt))}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Target ID: ${_formatTargetId(targetId)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),

            // ACTION BUTTONS (Only show for Pending reports)
            if (status == 'Pending')
              Row(
                children: [
                  // RESOLVE BUTTON
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showResolveDialog(context, report['id'], provider),
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

                  // DISMISS BUTTON
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDismissDialog(context, report['id'], provider),
                      icon: const Icon(Icons.close, size: 18, color: Colors.white),
                      label: const Text('Dismiss'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
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
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // ==================================================================
  // FORMAT UUID FOR DISPLAY (Show first 8 chars)
  // ==================================================================
  String _formatUserId(String? userId) {
    if (userId == null || userId.isEmpty) return 'Unknown';
    return userId.length > 8 ? '${userId.substring(0, 8)}...' : userId;
  }

  // ==================================================================
  // FORMAT TARGET ID FOR DISPLAY
  // ==================================================================
  String _formatTargetId(String? targetId) {
    if (targetId == null || targetId.isEmpty) return 'N/A';
    return targetId.length > 8 ? '${targetId.substring(0, 8)}...' : targetId;
  }

  // ==================================================================
  // RESOLVE CONFIRMATION DIALOG
  // ==================================================================
  void _showResolveDialog(BuildContext context, String reportId, ReportProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resolve Report?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mark this report as resolved?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✅ The reporter will be notified that their concern has been addressed.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await provider.resolveReport(reportId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '✅ Report resolved' : '❌ Failed to resolve'),
                    backgroundColor: success ? AppColors.secondaryGreen : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Resolve', style: TextStyle(color: AppColors.secondaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // DISMISS CONFIRMATION DIALOG
  // ==================================================================
  void _showDismissDialog(BuildContext context, String reportId, ReportProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Dismiss Report?', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to dismiss this report?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ The report will be marked as dismissed and removed from the pending list.',
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await provider.dismissReport(reportId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '✅ Report dismissed' : '❌ Failed to dismiss'),
                    backgroundColor: success ? Colors.grey[600] : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Dismiss', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}