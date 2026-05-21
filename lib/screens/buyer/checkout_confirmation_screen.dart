import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../config/app_colors.dart';
import '../../core/widgets/loading_button.dart';
import 'order_success_screen.dart';

class CheckoutConfirmationScreen extends StatelessWidget {
  const CheckoutConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final grouped = <String, List<dynamic>>{};
    for (final item in cart.items) {
      grouped.putIfAbsent(item.listing.location, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Order')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📦 Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: grouped.entries.map((entry) {
                  final location = entry.key;
                  final items = entry.value as List<dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📍 $location', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          ...items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('• ${item.listing.foodName} x${item.quantity}'),
                          )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text('Total: RM${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
            const SizedBox(height: 16),
            LoadingButton(
              text: 'Confirm & Checkout',
              isLoading: false,
              onPressed: () async {
                final groupedOrders = await cart.checkout();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => OrderSuccessScreen(groupedOrders: groupedOrders)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}