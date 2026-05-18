import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Add to pubspec.yaml: qr_flutter: ^4.1.0
import '../../models/order_model.dart';
import '../../config/app_colors.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;
  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmed')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.secondaryGreen),
            const SizedBox(height: 16),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // 🎫 QR Code for Pickup Verification
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
                ],
              ),
              child: QrImageView(
                data: order.qrCode,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Show this QR code to the seller when picking up your food.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            // 📋 Order Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _summaryRow('Order ID', order.id.substring(0, 8)),
                    _summaryRow('Status', order.status.toUpperCase()),
                    _summaryRow('Placed At', _formatTime(order.createdAt)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            
            // 🔘 Navigation Buttons
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, 
                '/home', 
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Back to Home', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // TODO: Navigate to order history (create later)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order history coming soon!')),
                );
              },
              child: const Text('View My Orders'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}