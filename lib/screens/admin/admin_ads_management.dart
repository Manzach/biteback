// FILE: lib/screens/admin/admin_ads_management.dart
// ============================================================================
// ADMIN ADS MANAGEMENT SCREEN
// ============================================================================
// Allows admins to monitor donation ads and remove inappropriate content (UC-08)
// Uses AdminProvider to fetch donations and perform moderation actions.
// Aligns with FYP Report: Table 13 (Donation), UC-08, Figure 42
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ ADD THIS for debugPrint
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../models/donation_model.dart';

class AdminAdsManagement extends StatefulWidget {
  const AdminAdsManagement({super.key});

  @override
  State<AdminAdsManagement> createState() => _AdminAdsManagementState();
}

class _AdminAdsManagementState extends State<AdminAdsManagement> {
  @override
  void initState() {
    super.initState();
    // Load donations when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDonations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final donations = adminProvider.donations;
    final isLoading = adminProvider.isLoading;
    final error = adminProvider.error;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text('📢 Ads Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => adminProvider.loadDonations(),
            tooltip: 'Refresh Donations',
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
                        ElevatedButton(onPressed: () => adminProvider.loadDonations(), child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : donations.isEmpty
                  ? const Center(child: Text('No donation ads found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: donations.length,
                      itemBuilder: (context, index) {
                        final donation = donations[index];
                        // ✅ Skip removed ads (soft-deleted) - use lowercase for consistency
                        if (donation.availabilityStatus?.toLowerCase() == 'removed') return const SizedBox.shrink();

                        return _buildDonationCard(donation, adminProvider);
                      },
                    ),
    );
  }

  // ==================================================================
  // ✅ DONATION CARD WIDGET - WITH STATUS INDICATORS
  // ==================================================================
  Widget _buildDonationCard(DonationModel donation, AdminProvider provider) {
    final status = donation.availabilityStatus?.toLowerCase() ?? 'available';
    final dateFormat = DateFormat('MMM dd, yyyy');

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
                    donation.donationTitle ?? 'Food Donation',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                // ✅ STATUS BADGE - Shows Available/Claimed/Removed
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(status), width: 1),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // DONOR INFO
            Text(
              'Posted by Donor ID: ${donation.donorId.substring(0, 8)}...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                donation.donationDescription ?? 'No description provided',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),

            // DETAILS ROW (Location + Date)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📍 ${donation.pickupLocation ?? 'Campus Location'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                Text(
                  '📅 ${dateFormat.format(donation.datePosted ?? DateTime.now())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            
            // ✅ ADD THIS: Quantity info if available
            if (donation.quantity != null && donation.quantity! > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${donation.quantity} pack(s) available',
                style: TextStyle(fontSize: 12, color: AppColors.secondaryGreen, fontWeight: FontWeight.w500),
              ),
            ],
            
            const SizedBox(height: 16),

            // ACTION BUTTON - Only show Remove for available donations
            if (status == 'available')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showRemoveDialog(context, donation, provider),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove Ad'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              )
            else
              // Show disabled state for claimed/removed ads
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: Text(status == 'claimed' ? 'Claimed' : 'Removed'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // ✅ HELPER: Get status badge color
  // ==================================================================
  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return AppColors.secondaryGreen;
      case 'claimed':
        return Colors.blue;
      case 'removed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // ==================================================================
  // ✅ REMOVE CONFIRMATION DIALOG - FIXED WITH ASYNC/AWAIT ✅
  // ==================================================================
  void _showRemoveDialog(BuildContext context, DonationModel donation, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Ad?', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to remove "${donation.donationTitle}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ This action cannot be undone. The donation ad will be marked as "Removed" and hidden from buyers.',
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            // ✅ FIXED: Make callback async and await the provider call
            onPressed: () async {
              // ✅ ADD DEBUG LOGGING TO TRACE THE FLOW
              debugPrint('🗑️ [UI] Remove button pressed for donation: "${donation.donationTitle}"');
              debugPrint('🗑️ [UI] Donation ID being passed: "${donation.donationId}"');
              debugPrint('🗑️ [UI] Donor ID: "${donation.donorId}"');
              debugPrint('🗑️ [UI] Current status: "${donation.availabilityStatus}"');
              
              // ✅ VALIDATE ID IS NOT EMPTY
              if (donation.donationId.isEmpty) {
                debugPrint('❌ [UI] ERROR: donationId is empty! Check DonationModel.fromMap parsing');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error: Invalid donation ID'), backgroundColor: Colors.red),
                );
                Navigator.pop(ctx);
                return;
              }
              
              // ✅ CALL PROVIDER TO REMOVE DONATION - AWAIT THE RESULT
              debugPrint('🔄 [UI] Calling provider.removeDonation("${donation.donationId}")...');
              final success = await provider.removeDonation(donation.donationId);
              
              // ✅ CLOSE DIALOG FIRST
              Navigator.pop(ctx);
              
              // ✅ ONLY SHOW SUCCESS IF BACKEND ACTUALLY SUCCEEDED
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Donation ad removed successfully'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to remove donation. Check admin permissions.'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}