// FILE: lib/screens/buyer/listing_detail_screen.dart
// ============================================================================
// LISTING DETAIL SCREEN - WITH REPORT FUNCTIONALITY
// ============================================================================
// Displays food listing details and allows buyers to report inappropriate content
// Aligns with FYP Report: UC-04 (Purchase Food), UC-08 (Admin Moderation)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_listing_model.dart';
import '../../providers/cart_provider.dart';
import '../../config/app_colors.dart';
import '../../core/widgets/loading_button.dart';
import '../../core/widgets/report_issue_dialog.dart'; // ✅ ADD THIS IMPORT
import 'cart_screen.dart';

class ListingDetailScreen extends StatelessWidget {
  final FoodListing listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final inCart = cart.getQuantityInCart(listing.id);
    final remaining = listing.quantity - inCart;
    final isAtLimit = remaining <= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Details'),
        actions: [
          // ✅ ADD THIS: Report Issue Button
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.redAccent),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => ReportIssueDialog(
                targetType: 'listing', // ✅ Correct type for food listings
                targetId: listing.id,  // ✅ Pass the listing UUID
              ),
            ),
            tooltip: 'Report this listing',
          ),
          const SizedBox(width: 8),
          
          // Cart Icon (existing)
          Consumer<CartProvider>(
            builder: (context, cart, _) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primaryOrange),
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Food Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: listing.photoUrl?.isNotEmpty == true
                  ? Image.network(
                      listing.photoUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                      ),
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 16),
            
            // 📝 Food Name & Price
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
            
            // 📋 Description & Details
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(listing.description, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 12),
            Text('📍 ${listing.location}', style: const TextStyle(color: Colors.grey)),
            Text(
              '⏰ Expires: ${listing.expiryDate.day}/${listing.expiryDate.month}/${listing.expiryDate.year}',
              style: const TextStyle(color: Colors.grey),
            ),
            
            // ✅ STOCK STATUS
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isAtLimit ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isAtLimit ? Colors.red : Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAtLimit ? Icons.error_outline : Icons.check_circle_outline,
                    size: 16,
                    color: isAtLimit ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAtLimit ? 'Sold out' : '$remaining left in stock',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isAtLimit ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // ✅ ADD TO CART BUTTON
            LoadingButton(
              text: isAtLimit ? 'Sold Out' : 'Add to Cart',
              isLoading: false,
              onPressed: isAtLimit ? null : () {
                final cart = context.read<CartProvider>();
                
                // Double-check limit before adding
                final currentInCart = cart.getQuantityInCart(listing.id);
                if (currentInCart >= listing.quantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Max quantity (${listing.quantity}) already in cart'),
                      backgroundColor: Colors.orange[700],
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                cart.addItem(listing);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Added to cart 🛒'),
                    action: SnackBarAction(
                      label: 'VIEW CART',
                      textColor: Colors.white,
                      onPressed: () => Navigator.pushNamed(context, '/cart'),
                    ),
                  ),
                );
              },
            ),
            
            // ✅ Helper text when at limit
            if (isAtLimit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'This item has reached its stock limit.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}