import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_listing.dart'; // ✅ Fixed: matches your actual filename
import '../../providers/buyer_provider.dart';
import '../../config/app_colors.dart';
import '../../core/widgets/loading_button.dart';
import 'order_success_screen.dart';

class ListingDetailScreen extends StatelessWidget {
  final FoodListing listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuyerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Food Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Food Image (null-safe)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildFoodImage(listing.photoUrl),
            ),
            const SizedBox(height: 16),

            // 🍽️ Food Name & Price
            Text(
              listing.foodName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'RM${listing.discountedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'RM${listing.originalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 📝 Description
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(listing.description, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 16),

            // ⏰ Expiry & 📍 Location
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Expires: ${_formatExpiry(listing.expiryDate)}', 
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text(listing.location, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 32),

            // 🛒 Order Button
            LoadingButton(
              text: 'Order Now',
              isLoading: provider.isLoading,
              onPressed: () async {
                final order = await provider.placeOrder(listingId: listing.id);
                if (order != null && context.mounted) {
                  // Navigate to QR success screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderSuccessScreen(order: order),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Helper method: safely handles nullable photoUrl
  Widget _buildFoodImage(String? url) {
    if (url?.isNotEmpty == true) {
      // Has valid image URL → show it
      return Image.network(
        url!, // Safe to use ! because we checked above
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
        ),
      );
    } else {
      // No image → show placeholder
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
      );
    }
  }

  String _formatExpiry(DateTime expiry) {
    final diff = expiry.difference(DateTime.now());
    if (diff.inHours < 1) return 'Expires soon';
    if (diff.inDays == 0) return 'Today';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} left';
  }
}