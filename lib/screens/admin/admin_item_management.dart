// FILE: lib/screens/admin/admin_item_management.dart
// ============================================================================
// ADMIN ITEM MANAGEMENT SCREEN
// ============================================================================
// Allows admins to monitor, flag, approve, or remove food listings (UC-08)
// Aligns with FYP Report: Table 11 (Food Listing), UC-08, Figure 42
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../models/food_listing_model.dart';

class AdminItemManagement extends StatefulWidget {
  const AdminItemManagement({super.key});

  @override
  State<AdminItemManagement> createState() => _AdminItemManagementState();
}

class _AdminItemManagementState extends State<AdminItemManagement> {
  @override
  void initState() {
    super.initState();
    // Load all listings when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final listings = adminProvider.listings;
    final isLoading = adminProvider.isLoading;
    final error = adminProvider.error;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text('📦 Item Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => adminProvider.loadListings(),
            tooltip: 'Refresh Listings',
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
                        ElevatedButton(onPressed: () => adminProvider.loadListings(), child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : listings.isEmpty
                  ? const Center(child: Text('No food listings found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final item = listings[index];
                        // ✅ Skip removed items in the main list (soft-deleted)
                        if (item.availabilityStatus?.toLowerCase() == 'removed') return const SizedBox.shrink();

                        return _buildListingCard(item, adminProvider);
                      },
                    ),
    );
  }

  // ==================================================================
  // ✅ LISTING CARD WIDGET - WITH FLAGGED INDICATOR
  // ==================================================================
  Widget _buildListingCard(FoodListing item, AdminProvider provider) {
    // ✅ Use correct field name from schema: availabilityStatus (maps to availability_status)
    final status = item.availabilityStatus?.toLowerCase() ?? 'available';
    final bool isFlagged = status == 'flagged';
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE HEADER
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: item.photoUrl != null
                    ? Image.network(
                        item.photoUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
              ),
              // ✅ STATUS BADGE - Shows Flagged/Available/Sold/Expired
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(status), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isFlagged) const Icon(Icons.flag, size: 12, color: Colors.white),
                      if (isFlagged) const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // DETAILS SECTION
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.foodName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Seller ID: ${item.sellerId.substring(0, 8)}...',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'RM ${item.discountedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.quantity} left',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    Text(
                      'Expires: ${dateFormat.format(item.expiryDate)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
                
                // ✅ ADD THIS: Flagged indicator row with icon + text
                if (isFlagged) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.flag, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Flagged for review',
                          style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),

                // ACTION BUTTONS
                Row(
                  children: [
                    // ✅ FLAG / APPROVE BUTTON - Changes based on status
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (isFlagged) {
                            provider.approveListing(item.id);
                          } else {
                            provider.flagListing(item.id);
                          }
                        },
                        icon: Icon(isFlagged ? Icons.check_circle : Icons.flag, size: 18),
                        label: Text(isFlagged ? 'Approve' : 'Flag'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isFlagged ? AppColors.secondaryGreen : Colors.orange[700],
                          side: BorderSide(color: isFlagged ? AppColors.secondaryGreen : Colors.orange[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // REMOVE BUTTON
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRemoveDialog(context, item, provider),
                        icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                        label: const Text('Remove'),
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
        ],
      ),
    );
  }

  // ==================================================================
  // ✅ HELPER: Get status badge color
  // ==================================================================
  Color _getStatusColor(String status) {
    switch (status) {
      case 'flagged':
        return Colors.orange;
      case 'available':
        return AppColors.secondaryGreen;
      case 'removed':
        return Colors.grey;
      case 'sold':
        return Colors.blue;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ==================================================================
  // REMOVE CONFIRMATION DIALOG
  // ==================================================================
  void _showRemoveDialog(BuildContext context, FoodListing item, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Listing?', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to remove "${item.foodName}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ This action cannot be undone. The listing will be marked as "Removed" and hidden from buyers.',
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.removeListing(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listing removed successfully'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}