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

// ============================================================================
// BUYER HOME SCREEN
// ============================================================================
// Main dashboard for buyers (students/staff) to:
// - Browse discounted near-expiry food (UC-04)
// - View donation advertisements (UC-07)
// - Access cart & checkout flow
// Aligns with FYP Report: Figures 38, 41 & Table 5 (UC-04, UC-07)
// ============================================================================

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================
  // Loads data after widget is built to avoid build-time setState errors
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load food listings (UC-04: Purchase Near-Expiry Food)
      context.read<BuyerProvider>().loadListings();
      // Load donation ads (UC-07: View Donation Advertisements)
      context.read<BuyerProvider>().loadDonations();
    });
  }

  // ==========================================================================
  // MAIN BUILD METHOD
  // ==========================================================================
  // Constructs the entire UI using CustomScrollView with slivers for
  // efficient scrolling and performance on mobile devices
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    // Watch providers to rebuild UI when data changes
    final provider = context.watch<BuyerProvider>(); // Food listings + donations
    final cart = context.watch<CartProvider>(); // Cart state for badge

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ==================================================================
          // APP BAR WITH CART ICON & BADGE
          // ==================================================================
          // Floating AppBar with logo, menu/profile icons, and cart with live badge
          // Matches prototype Figure 38 (Buyer Dashboard)
          // ==================================================================
          SliverAppBar(
            backgroundColor: AppColors.primaryOrange,
            floating: true, // AppBar hides/shows on scroll for more content space
            pinned: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Menu & Profile Icons (Left side - TODO: Implement navigation)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        // TODO: Open side drawer menu
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Menu coming soon!')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_outline, color: Colors.white),
                      onPressed: () {
                        // TODO: Navigate to user profile
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
                
                // App Logo (Center) - Matches FYP branding
                const Text(
                  'bite.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins', // Use your custom font if added
                  ),
                ),
                
                // Cart Icon with Live Badge (Right side)
                // Uses Consumer to rebuild only badge when cart changes
                Consumer<CartProvider>(
                  builder: (context, cart, _) => Stack(
                    children: [
                      // Cart button - navigates to cart screen
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: () => Navigator.pushNamed(context, '/cart'),
                        tooltip: 'View Cart',
                      ),
                      // Badge showing number of items in cart (only if > 0)
                      if (cart.itemCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red, // High-contrast badge color
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
          // Visual category icons for quick browsing (Bread, Milk, Eggs, etc.)
          // These are placeholders - can be made clickable for filtering later
          // Matches prototype Figure 38 category section
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
                  // Row of 5 category icons with labels
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
          
          // Orange divider line - matches FYP design system
          const SliverToBoxAdapter(
            child: Divider(color: AppColors.primaryOrange, thickness: 2),
          ),
          
          // ==================================================================
          // PROMO ITEMS SECTION (UC-04: Purchase Near-Expiry Food)
          // ==================================================================
          // Displays discounted food listings from sellers
          // Horizontal scrollable cards with image, price, location
          // Aligns with FYP Report: UC-04, Figure 38, Table 5
          // ==================================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  const Text(
                    'Promo Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // -----------------------------------------------------------
                  // LOADING STATE: Shows while fetching food listings
                  // -----------------------------------------------------------
                  if (provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  
                  // -----------------------------------------------------------
                  // ERROR STATE: Shows if API/database call fails
                  // -----------------------------------------------------------
                  else if (provider.errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: provider.loadListings,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  
                  // -----------------------------------------------------------
                  // EMPTY STATE: Shows when no food listings available
                  // -----------------------------------------------------------
                  else if (provider.listings.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'No promo items right now. 🍽️\nCheck back soon!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  
                  // -----------------------------------------------------------
                  // SUCCESS STATE: Horizontal scrollable list of promo items
                  // Shows first 4 items to encourage browsing
                  // -----------------------------------------------------------
                  else
                    SizedBox(
                      height: 280, // Fixed height for horizontal scroll
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.listings.length > 4 
                            ? 4 
                            : provider.listings.length,
                        itemBuilder: (context, index) {
                          final item = provider.listings[index];
                          return _buildPromoCard(item);
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  // Tagline explaining the promo section
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
          // Displays food donation advertisements posted by donors
          // Buyers can browse and view details about free food availability
          // Aligns with FYP Report: UC-07, Figure 41, Table 8
          // ==================================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header with "View All" button
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
                      // View All Button (placeholder for full donation list)
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to full donation listings page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Full donation list coming soon!')),
                          );
                        },
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
                  
                  // -----------------------------------------------------------
                  // LOADING STATE: Shows while fetching donations
                  // -----------------------------------------------------------
                  if (provider.isLoadingDonations == true)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ))
                  
                  // -----------------------------------------------------------
                  // ERROR STATE: Shows if donation fetch fails
                  // -----------------------------------------------------------
                  else if (provider.donationErrorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
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
                  
                  // -----------------------------------------------------------
                  // EMPTY STATE: Shows when no donations available
                  // -----------------------------------------------------------
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
                  
                  // -----------------------------------------------------------
                  // SUCCESS STATE: Vertical list of donation cards
                  // Shows first 3 donations to encourage browsing
                  // -----------------------------------------------------------
                  else
                    ListView.separated(
                      shrinkWrap: true, // Allows ListView inside Column
                      physics: const NeverScrollableScrollPhysics(), // Parent handles scroll
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
                  // Tagline for donation section
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
          
          // Bottom padding for better scrolling experience
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // CATEGORY ITEM BUILDER
  // ==================================================================
  // Creates a category icon with label (e.g., "Bread" with bakery icon)
  // Used in the "Popular Product" section for visual browsing
  // Parameters:
  //   - label: Category name (e.g., "Bread", "Milk")
  //   - icon: Material icon to display
  //   - color: Color for the icon and background accent
  // ==================================================================
  Widget _buildCategoryItem(String label, IconData icon, Color color) {
    return Column(
      children: [
        // Icon container with rounded background
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), // Light transparent background
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        // Category label text
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
  // Displays food listing card with image, price, and location
  // Tapping navigates to listing detail screen for purchase
  // Parameters:
  //   - item: FoodListing model containing food data from Supabase
  // ==================================================================
  Widget _buildPromoCard(FoodListing item) {
    return Container(
      width: 180, // Fixed width for horizontal scroll
      margin: const EdgeInsets.only(right: 12), // Spacing between cards
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
          // ---------------------------------------------------------------
          // FOOD IMAGE
          // ---------------------------------------------------------------
          // Displays food photo from URL or placeholder icon if no image
          // Uses null-safe check: item.photoUrl?.isNotEmpty == true
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
          
          // ---------------------------------------------------------------
          // FOOD DETAILS
          // ---------------------------------------------------------------
          // Shows food name, discounted price, original price (strikethrough),
          // and pickup location
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name (truncated if too long)
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
                  // Price row: Discounted price (orange) + Original price (grey)
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
                  // Pickup location (truncated if too long)
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
          
          // ---------------------------------------------------------------
          // VIEW BUTTON
          // ---------------------------------------------------------------
          // Navigates to listing detail screen when tapped
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ElevatedButton(
              onPressed: () {
                // Navigate to detail screen with selected food item
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
  // Displays donation advertisement card posted by donors
  // Shows donation title, description, location, date posted, and availability
  // Tapping navigates to donation detail screen for more information
  // Parameters:
  //   - donation: DonationModel containing donation data from Supabase
  // ==================================================================
  Widget _buildDonationCard(DonationModel donation) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to donation detail screen with typed donation model
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
              // 🖼️ Donation Image/Icon (Left side)
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
              
              // 📋 Donation Details (Center - Expanded)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Donation Title (bold, truncated)
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
                    
                    // Pickup Location with icon
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            donation.pickupLocation,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Date Posted with icon
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${donation.datePosted.day}/${donation.datePosted.month}/${donation.datePosted.year}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    
                    // Quantity (if available) - helps buyers plan pickup
                    if (donation.quantity != null && donation.quantity! > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.inventory_2, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${donation.quantity} pack${donation.quantity! > 1 ? 's' : ''} available',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // 🏷️ Availability Badge (Right side)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  // HELPER: Donation Placeholder Icon (when no photo)
  // ==================================================================
  // Reusable widget for donation cards without images
  // Matches secondary green color from AppColors design system
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