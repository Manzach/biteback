import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/buyer_provider.dart';
import '../../models/food_listing_model.dart'; // ✅ Make sure this matches your actual filename
import '../../config/app_colors.dart';
import '../../screens/buyer/listing_detail_screen.dart';

class BuyerDashboardContent extends StatefulWidget {
  const BuyerDashboardContent({super.key});

  @override
  State<BuyerDashboardContent> createState() => _BuyerDashboardContentState();
}

class _BuyerDashboardContentState extends State<BuyerDashboardContent> {
  @override
  void initState() {
    super.initState();
    // Fetch listings after widget is built (prevents build-time setState errors)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BuyerProvider>().loadListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuyerProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Near You',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 🟡 LOADING STATE
        if (provider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          )

        // 🔴 ERROR STATE
        else if (provider.errorMessage != null)
          _buildErrorState(provider)

        // ⚪ EMPTY STATE
        else if (provider.listings.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No active listings right now. 🍽️\nCheck back soon!',
                textAlign: TextAlign.center,
              ),
            ),
          )

        // 🟢 DATA STATE: List of food cards
        else
          ListView.builder(
            shrinkWrap: true, // Allows ListView inside Column
            physics: const NeverScrollableScrollPhysics(), // Parent handles scroll
            itemCount: provider.listings.length,
            itemBuilder: (context, index) {
              final item = provider.listings[index];
              return _buildFoodCard(item);
            },
          ),
      ],
    );
  }

  Widget _buildErrorState(BuyerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                provider.loadListings();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(FoodListing item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImage(item.photoUrl), // ✅ Extracted to helper method
        ),
        title: Text(
          item.foodName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.location, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'RM${item.discountedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'RM${item.originalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Expires: ${_formatExpiry(item.expiryDate)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to detail screen with selected item
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

  // ✅ Helper method: safely handles nullable photoUrl
  Widget _buildImage(String? url) {
    if (url?.isNotEmpty == true) {
      return Image.network(
        url!, // Safe to use ! because we checked above
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

  String _formatExpiry(DateTime expiry) {
    final diff = expiry.difference(DateTime.now());
    if (diff.inHours < 1) return 'Expires soon';
    if (diff.inDays == 0) return 'Today';
    return '${diff.inDays}d left';
  }
}