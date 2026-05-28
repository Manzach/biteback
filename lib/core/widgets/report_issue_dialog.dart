// FILE: lib/core/widgets/report_issue_dialog.dart
// ============================================================================
// REPORT ISSUE DIALOG
// ============================================================================
// Reusable dialog for buyers/sellers/donors to report listings, donations, or users
// Aligns with FYP Report: UC-08 (Admin Monitor System), Section 4.4.1
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';

class ReportIssueDialog extends StatefulWidget {
  final String targetType; // 'listing', 'donation', 'user'
  final String targetId;   // UUID of the reported entity

  const ReportIssueDialog({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  @override
  State<ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends State<ReportIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedReason = 'inappropriate_content';
  bool _isSubmitting = false;

  final List<Map<String, String>> _reasons = [
    {'value': 'inappropriate_content', 'label': 'Inappropriate Content'},
    {'value': 'wrong_item', 'label': 'Wrong/Misleading Item'},
    {'value': 'scam', 'label': 'Suspected Scam'},
    {'value': 'spam', 'label': 'Spam/Repeated Posts'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.flag_outlined, color: AppColors.primaryOrange, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'Report Issue',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Help us keep BiteBack safe and reliable.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Reason Dropdown
              const Text('Reason for Report *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                items: _reasons.map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason['value'],
                    child: Text(reason['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedReason = value!);
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              const Text('Additional Details (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Provide more context if needed...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================================
  // SUBMIT REPORT LOGIC
  // ==================================================================
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final reporterId = authProvider.currentUser?.id;

    if (reporterId == null) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to report an issue'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final reportProvider = context.read<ReportProvider>();
    final success = await reportProvider.submitReport(
      reporterId: reporterId,
      targetType: widget.targetType,
      targetId: widget.targetId,
      reason: _selectedReason,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Report submitted successfully. Admin will review it shortly.'),
          backgroundColor: AppColors.secondaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reportProvider.errorMessage ?? 'Failed to submit report. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}