// FILE: lib/screens/buyer/all_listings_screen.dart
// ============================================================================
// ALL LISTINGS SCREEN
// ============================================================================
// Displays all active food listings with search & filter capabilities
// Uses client-side filtering via BuyerProvider.availableListings
// Aligns with FYP Report: UC-04, Figure 38
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/buyer_provider.dart';
import '../../models/food_listing_model.dart';
import 'listing_detail_screen.dart';

class AllListingsScreen extends StatefulWidget {
  const AllListingsScreen({super.key});

  @override
  State<AllListingsScreen> createState() => _AllListingsScreenState();
}

class _AllListingsScreenState extends State<AllListingsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // ✅ Load listings WITHOUT searchQuery parameter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BuyerProvider>().loadListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuyerProvider>();
    // ✅ Use FILTERED listings (client-side search)
    final filteredListings = provider.availableListings;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text(
          'All Listings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              // ✅ Instant client-side filtering via provider setter
              onChanged: (value) => context.read<BuyerProvider>().setSearchQuery = value,
              decoration: InputDecoration(
                hintText: 'Search food, category, location...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: provider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          context.read<BuyerProvider>().clearSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ✅ Listing Count Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredListings.length} item${filteredListings.length != 1 ? 's' : ''} found',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                if (provider.searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      context.read<BuyerProvider>().clearSearch();
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),

          // ✅ Listings Grid
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredListings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              provider.searchQuery.isEmpty
                                  ? 'No listings available'
                                  : 'No results for "${provider.searchQuery}"',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                            if (provider.searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<BuyerProvider>().clearSearch();
                                },
                                child: const Text('Clear search'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<BuyerProvider>().refreshListings(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredListings.length,
                          itemBuilder: (context, index) {
                            final listing = filteredListings[index];
                            return _buildListingCard(listing);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // LISTING CARD BUILDER
  // ==================================================================
  Widget _buildListingCard(FoodListing listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailScreen(listing: listing),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: listing.photoUrl?.isNotEmpty == true
                    ? Image.network(
                        listing.photoUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.foodName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.description,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'RM${listing.discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'RM${listing.originalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
}