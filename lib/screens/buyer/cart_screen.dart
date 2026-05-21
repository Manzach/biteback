import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../config/app_colors.dart';
import 'checkout_confirmation_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cart.items.isEmpty
          ? const Center(child: Text('Your cart is empty 🛒', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      final isAtLimit = item.quantity >= item.listing.quantity;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(item.listing.foodName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('📍 ${item.listing.location} • RM${item.listing.discountedPrice.toStringAsFixed(2)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ➖ MINUS BUTTON (uses safe provider method)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => cart.decreaseQuantity(item.listing.id),
                              ),
                              
                              // 📊 QUANTITY DISPLAY (current/max)
                              Text(
                                '${item.quantity}/${item.listing.quantity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isAtLimit ? Colors.orange : null,
                                ),
                              ),
                              
                              // ➕ PLUS BUTTON (disabled when at stock limit)
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: isAtLimit ? Colors.grey : null,
                                ),
                                onPressed: isAtLimit 
                                    ? null 
                                    : () => cart.increaseQuantity(item.listing.id),
                              ),
                              
                              // 🗑️ DELETE BUTTON
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => cart.removeItem(item.listing.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('RM${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                      ]),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutConfirmationScreen())),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange, minimumSize: const Size(double.infinity, 48)),
                        child: const Text('Proceed to Checkout', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}