// FILE: lib/screens/seller/seller_home.dart
// ============================================================================
// SELLER HOME SCREEN
// ============================================================================
// Main dashboard for sellers to manage food listings (UC-05)
// - View all listings with hide/show toggle
// - Create/Edit/Delete listings
// - Scan QR codes for order collection
// Uses SellerProvider for state management (Provider pattern)
// Aligns with FYP Report: Table 11, UC-05, Figure 39
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/food_listing_model.dart';
import '../../providers/seller_provider.dart';
import 'create_listing_screen.dart';
import 'order_collection_screen.dart';

class SellerHome extends StatefulWidget {
  const SellerHome({super.key});

  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerProvider>().loadListings();
    });
  }

  // ==================================================================
  // OPEN CREATE LISTING SCREEN (Create Mode)
  // ==================================================================
  Future<void> _openCreateListing() async {
    final result = await Navigator.push<FoodListing?>(
      context,
      MaterialPageRoute(builder: (context) => const CreateListingScreen()),
    );
    if (result != null && mounted) {
      context.read<SellerProvider>().loadListings();
    }
  }

  // ==================================================================
  // ✅ OPEN EDIT LISTING SCREEN (Edit Mode) - NEW METHOD
  // ==================================================================
  Future<void> _openEditListing(FoodListing listing) async {
    final result = await Navigator.push<FoodListing?>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateListingScreen(listing: listing), // ✅ Pass existing listing
      ),
    );
    if (result != null && mounted) {
      context.read<SellerProvider>().loadListings();
    }
  }

  // ==================================================================
  // DELETE LISTING
  // ==================================================================
  Future<void> _deleteListing(String listingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<SellerProvider>().deleteListing(listingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Listing deleted' : 'Error deleting listing'),
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
    }
  }

  // ==================================================================
  // TOGGLE LISTING VISIBILITY
  // ==================================================================
  Future<void> _toggleVisibility(String listingId, bool isHidden) async {
    final success = await context.read<SellerProvider>().toggleVisibility(listingId, isHidden);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHidden ? 'Listing hidden from buyers' : 'Listing visible to buyers'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ==================================================================
  // OPEN QR SCANNER FOR ORDER COLLECTION
  // ==================================================================
  void _openOrderScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrderCollectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sellerProvider = context.watch<SellerProvider>();
    final listings = sellerProvider.listings;
    final isLoading = sellerProvider.isLoading;
    final error = sellerProvider.error;

    return Scaffold(
      backgroundColor: AppColors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateListing,
        backgroundColor: AppColors.secondaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Post New Listing',
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.secondaryGreen,
            title: const Text(
              '🏪 My Listings',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                onPressed: _openOrderScanner,
                tooltip: 'Scan to Collect Orders',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => sellerProvider.loadListings(),
                tooltip: 'Refresh Listings',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Listings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (error != null)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                          const SizedBox(height: 16),
                          Text(
                            error,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red[600], fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => sellerProvider.loadListings(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (listings.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No listings yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + button to create one',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final listing = listings[index];
                        return _buildListingCard(
                          listing: listing,
                          onDelete: () => _deleteListing(listing.id),
                          onEdit: () => _openEditListing(listing), // ✅ Pass edit callback
                          onToggleVisibility: () => _toggleVisibility(
                            listing.id,
                            !listing.isHidden,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // BUILD LISTING CARD (With Edit/Delete/Hide Actions)
  // ==================================================================
  Widget _buildListingCard({
    required FoodListing listing,
    required VoidCallback onDelete,
    required VoidCallback onEdit, // ✅ NEW: Edit callback
    required VoidCallback onToggleVisibility,
  }) {
    final discount = listing.discountPercentage.toStringAsFixed(0);
    final hoursLeft = listing.hoursUntilExpiry;
    final isHidden = listing.isHidden;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isHidden ? Colors.grey[50] : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              if (listing.photoUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      isHidden ? Colors.grey.withOpacity(0.4) : Colors.transparent,
                      BlendMode.saturation,
                    ),
                    child: Image.network(
                      listing.photoUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$discount% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (isHidden)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'HIDDEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.foodName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isHidden ? Colors.grey[600] : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${listing.quantity} available',
                          style: TextStyle(
                            fontSize: 14,
                            color: isHidden ? Colors.grey[500] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RM ${listing.discountedPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isHidden ? Colors.grey[400] : AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      hoursLeft > 0
                          ? 'Expires in ${hoursLeft}h'
                          : 'Expired',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isHidden 
                            ? Colors.grey 
                            : (hoursLeft > 0 ? Colors.orange : Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      listing.location,
                      style: TextStyle(
                        fontSize: 12,
                        color: isHidden ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Hide/Show Toggle
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onToggleVisibility,
                        icon: Icon(
                          isHidden ? Icons.visibility_off : Icons.visibility,
                          size: 16,
                          color: isHidden ? Colors.grey : AppColors.secondaryGreen,
                        ),
                        label: Text(
                          isHidden ? 'Show' : 'Hide',
                          style: TextStyle(color: isHidden ? Colors.grey : AppColors.secondaryGreen),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isHidden ? Colors.grey : AppColors.secondaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ✅ Edit Button - NOW WORKS!
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isHidden ? null : onEdit, // ✅ Calls _openEditListing
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outlined, size: 16, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
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
}