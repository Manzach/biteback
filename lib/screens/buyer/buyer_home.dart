import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/cart_provider.dart'; // ✅ ADD THIS for cart badge
import '../../models/food_listing_model.dart';
import 'listing_detail_screen.dart';
import 'cart_screen.dart'; // ✅ ADD THIS for cart navigation

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  @override
  void initState() {
    super.initState();
    // Fetch listings when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BuyerProvider>().loadListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuyerProvider>();
    final cart = context.watch<CartProvider>(); // ✅ Watch cart for live badge

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          // ✅ App Bar with Cart Icon + Live Badge
          SliverAppBar(
            backgroundColor: AppColors.primaryOrange,
            title: const Text('🛒 Browse Food', style: TextStyle(color: Colors.white)),
            floating: true,
            actions: [
              Consumer<CartProvider>( // ✅ Live badge updates automatically
                builder: (context, cart, _) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                      onPressed: () => Navigator.pushNamed(context, '/cart'), // ✅ Navigate to cart
                    ),
                    // ✅ Badge shows item count (only if > 0)
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red, // High-contrast badge color
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            '${cart.itemCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // Loading State
          if (provider.isLoading)
            const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )),
            ),
          
          // Error State
          if (provider.errorMessage != null)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                        onPressed: () => provider.loadListings(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Content (only show if not loading and no error)
          if (!provider.isLoading && provider.errorMessage == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Near You',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Empty State
                    if (provider.listings.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            'No active listings right now. 🍽️\nCheck back soon!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    else
                      // Dynamic List of Real Listings
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.listings.length,
                        itemBuilder: (context, index) {
                          final item = provider.listings[index];
                          return _buildFoodCard(item);
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

  // Card builder for FoodListing data
  Widget _buildFoodCard(FoodListing item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImage(item.photoUrl),
        ),
        title: Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.location, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'RM${item.discountedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  'RM${item.originalPrice.toStringAsFixed(2)}',
                  style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to detail screen with the selected item
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailScreen(listing: item),
            ),
          );
        },
      ),
    );
  }

  // Helper method: safely handles nullable photoUrl
  Widget _buildImage(String? url) {
    if (url?.isNotEmpty == true) {
      return Image.network(
        url!,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 50,
          height: 50,
          color: Colors.grey[200],
          child: const Icon(Icons.restaurant, color: Colors.grey),
        ),
      );
    } else {
      return Container(
        width: 50,
        height: 50,
        color: Colors.grey[200],
        child: const Icon(Icons.restaurant, color: Colors.grey),
      );
    }
  }
}