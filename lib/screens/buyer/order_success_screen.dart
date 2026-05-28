// FILE: lib/screens/buyer/order_success_screen.dart
// ============================================================================
// ORDER SUCCESS SCREEN - QR CODE GENERATION
// ============================================================================
// Displays QR codes for pickup verification after successful order
// Format: BB-LOC-{safe_location}-{uuid1,uuid2,uuid3}
// Aligns with FYP Report: UC-04, Figure 38, Table 12
// ============================================================================

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/order_model.dart';
import '../../config/app_colors.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, List<OrderModel>> groupedOrders;
  const OrderSuccessScreen({super.key, required this.groupedOrders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmed')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.secondaryGreen),
            const SizedBox(height: 12),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Show each QR code at its respective pickup location.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // ✅ LIST OF QR CODES GROUPED BY LOCATION
            Expanded(
              child: ListView.builder(
                itemCount: groupedOrders.length,
                itemBuilder: (_, i) {
                  final entry = groupedOrders.entries.elementAt(i);
                  final location = entry.key;
                  final orders = entry.value;
                  
                  // ✅ Calculate total items for this location
                  final totalQuantity = orders.fold<int>(
                    0,
                    (sum, order) => sum + order.quantity,
                  );
                  
                  // ✅ FIX: Generate standardized QR payload
                  // Format: BB-LOC-{safe_location}-{uuid1,uuid2,uuid3}
                  // - Uses FULL UUIDs (not truncated) for reliable lookup
                  // - Uses comma ',' separator (not dash) for easy parsing
                  // - Sanitizes location to alphanumeric + underscore only
                  final orderIds = orders.map((o) => o.id).join(',');
                  final safeLocation = location.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
                  final qrPayload = 'BB-LOC-$safeLocation-$orderIds';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // 📍 Location Header
                          Text(
                            '📍 $location',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          
                          // 📦 Total Items Text
                          Text(
                            '$totalQuantity item${totalQuantity > 1 ? 's' : ''} to collect',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          
                          // 📋 List of Items with Quantities
                          ...orders.map((order) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '• Item #${order.listingId.substring(0, 6)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  'x${order.quantity}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          )),
                          
                          const SizedBox(height: 12),
                          
                          // 🎫 QR Code
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
                              ],
                            ),
                            child: QrImageView(
                              data: qrPayload,
                              size: 180,
                              version: QrVersions.auto,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // 🔤 QR Code Reference Text
                          Text(
                            'Scan at: $location',
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // 🔘 Back to Home Button
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
          ],
        ),
      ),
    );
  }
}