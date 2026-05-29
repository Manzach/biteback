// FILE: lib/screens/buyer/buyer_home.dart
// ============================================================================
// BUYER HOME SCREEN
// ============================================================================
// Main dashboard for buyers (students/staff) to:
// - Browse discounted near-expiry food (UC-04)
// - View donation advertisements (UC-07)
// - Access cart & checkout flow
// - ✅ Pull-to-refresh for real-time data sync
// Aligns with FYP Report: Figures 38, 41 & Table 5 (UC-04, UC-07)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/food_listing_model.dart';
import '../../models/donation_model.dart';
import 'listing_detail_screen.dart';
import 'cart_screen.dart';
import 'donation_detail_screen.dart';
import 'profile_screen.dart';
import 'all_listings_screen.dart';
import 'all_donation_screen.dart';

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BuyerProvider>().loadListings();
      context.read<BuyerProvider>().loadDonations();
    });
  }

  // ==========================================================================
  // 🔍 SEARCH CONTROLLER (Client-side filtering)
  // ==========================================================================
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // MAIN BUILD METHOD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuyerProvider>();
    final cart = context.watch<CartProvider>();
    
    // ✅ Use FILTERED listings (client-side search)
    final filteredListings = provider.availableListings;

    return Scaffold(
      backgroundColor: Colors.white,
      // ✅ PULL-TO-REFRESH WRAPPER
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh both listings & donations in parallel
          await Future.wait([
            context.read<BuyerProvider>().refreshListings(),
            context.read<BuyerProvider>().refreshDonations(),
          ]);
        },
        color: AppColors.primaryOrange,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          // ✅ AlwaysScrollableScrollPhysics ensures pull-to-refresh works 
          // even when content is shorter than the screen height
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ==================================================================
            // APP BAR WITH CART ICON & BADGE
            // ==================================================================
            SliverAppBar(
              backgroundColor: AppColors.primaryOrange,
              floating: true,
              pinned: true,
              toolbarHeight: 56,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Image.asset(
                      'assets/logo_black.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Consumer<CartProvider>(
                    builder: (context, cart, _) => Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart, color: Colors.white),
                          onPressed: () => Navigator.pushNamed(context, '/cart'),
                          tooltip: 'View Cart',
                        ),
                        if (cart.itemCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${cart.itemCount}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================================
            // POPULAR PRODUCT CATEGORIES
            // ==================================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'POPULAR PRODUCT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCategoryItem('Bread', Icons.bakery_dining, Colors.orange),
                        _buildCategoryItem('Milk', Icons.local_drink, Colors.blue),
                        _buildCategoryItem('Eggs', Icons.egg, Colors.yellow[700]!),
                        _buildCategoryItem('Chocolates', Icons.cake, Colors.brown),
                        _buildCategoryItem('Biscuit', Icons.cookie, Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================================
            // 🔍 SEARCH BAR - CLIENT-SIDE FILTERING (Instant Results)
            // ==================================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  // ✅ Instant client-side filtering via provider setter
                  onChanged: (value) => context.read<BuyerProvider>().setSearchQuery = value,
                  decoration: InputDecoration(
                    hintText: 'Search food, category, location...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    // ✅ Clear button appears when search has text
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Orange divider line
            const SliverToBoxAdapter(
              child: Divider(color: AppColors.primaryOrange, thickness: 2),
            ),

            // ==================================================================
            // PROMO ITEMS SECTION (UC-04: Purchase Near-Expiry Food)
            // ==================================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header with View All Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Promo Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllListingsScreen(),
                            ),
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Loading / Error / Empty / Success States
                    if (provider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (provider.errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                provider.errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.read<BuyerProvider>().refreshListings(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (filteredListings.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            provider.searchQuery.isEmpty
                                ? 'No promo items right now. 🍽️\nCheck back soon!'
                                : 'No results for "${provider.searchQuery}"',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      // ✅ Use FILTERED listings for instant search results
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredListings.length > 4 
                              ? 4 
                              : filteredListings.length,
                          itemBuilder: (context, index) {
                            return _buildPromoCard(filteredListings[index]);
                          },
                        ),
                      ),

                    const SizedBox(height: 8),
                    const Text(
                      '"Fresh Deals Before Expiry — Delicious Food at Lower Prices."',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Orange divider line
            const SliverToBoxAdapter(
              child: Divider(color: AppColors.primaryOrange, thickness: 2),
            ),

            // ==================================================================
            // 🎁 FREE FOOD DONATION ADS SECTION (UC-07: View Donation Ads)
            // ==================================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Free Food',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllDonationsScreen(),
                            ),
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (provider.isLoadingDonations == true)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ))
                    else if (provider.donationErrorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                provider.donationErrorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (provider.donations.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            'No donation ads available. 🎁\nCheck back soon!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.donations.length > 3
                            ? 3 
                            : provider.donations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final donation = provider.donations[index];
                          return _buildDonationCard(donation);
                        },
                      ),

                    const SizedBox(height: 8),
                    const Text(
                      '"Yes, It\'s Free! Get Your Food Before It Runs Out."',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Orange divider line
            const SliverToBoxAdapter(
              child: Divider(color: AppColors.primaryOrange, thickness: 2),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // CATEGORY ITEM BUILDER
  // ==================================================================
  Widget _buildCategoryItem(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ==================================================================
  // PROMO CARD BUILDER (UC-04: Discounted Food from Sellers)
  // ==================================================================
  Widget _buildPromoCard(FoodListing item) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
              child: item.photoUrl?.isNotEmpty == true
                  ? Image.network(
                      item.photoUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.restaurant,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.foodName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'RM${item.discountedPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'RM${item.originalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '📍 ${item.location}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListingDetailScreen(listing: item),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                minimumSize: const Size(double.infinity, 28),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'View',
                style: TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // 🎁 DONATION CARD BUILDER (UC-07: View Donation Ads)
  // ==================================================================
  Widget _buildDonationCard(DonationModel donation) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DonationDetailScreen(donation: donation),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: donation.photoUrl?.isNotEmpty == true
                    ? Image.network(
                        donation.photoUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDonationPlaceholder(),
                      )
                    : _buildDonationPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.donationTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            donation.pickupLocation,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${donation.datePosted.day}/${donation.datePosted.month}/${donation.datePosted.year}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (donation.quantity != null && donation.quantity! > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.inventory_2,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${donation.quantity} pack${donation.quantity! > 1 ? 's' : ''} available',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: donation.isAvailable
                      ? Colors.green[100]
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  donation.isAvailable ? '✓ Available' : '✗ Unavailable',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: donation.isAvailable
                        ? Colors.green[800]
                        : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================================
  // HELPER: Donation Placeholder Icon
  // ==================================================================
  Widget _buildDonationPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.secondaryGreen.withOpacity(0.1),
      child: const Icon(
        Icons.volunteer_activism,
        color: AppColors.secondaryGreen,
        size: 30,
      ),
    );
  }
}