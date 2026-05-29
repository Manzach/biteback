// FILE: lib/screens/seller/order_collection_screen.dart
// ============================================================================
// ORDER COLLECTION SCREEN (SELLER QR SCANNER)
// ============================================================================
// Allows sellers to scan buyer QR codes to verify food pickup
// - Parses QR payloads for buyer pickup verification
//   Supported formats:
//     • BB-{timestamp}-{buyer_id} (legacy - from orders_rows.sql)
//     • BB-LOC-{safe_location}-{order_id1,order_id2,...} (new)
// - Fetches pending orders for the buyer or the scanned order IDs
// - Updates order status to 'collected' + deducts listing quantity
// - ✅ Refreshes SellerProvider to show updated quantities immediately
// Aligns with FYP Report: UC-04, Figure 38, Table 12
// ============================================================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/supabase_config.dart'; // ✅ For SupabaseConfig.client
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/seller_provider.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class OrderCollectionScreen extends StatefulWidget {
  const OrderCollectionScreen({super.key});

  @override
  State<OrderCollectionScreen> createState() => _OrderCollectionScreenState();
}

class _OrderCollectionScreenState extends State<OrderCollectionScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  String? _scanError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text(
          'Scan Order QR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle Flashlight',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              final qrValue = capture.barcodes.first.rawValue;
              if (qrValue != null) _processQR(context, qrValue);
            },
          ),

          // Scanning guide overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Instructions at bottom
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Text(
              'Align QR code within the frame',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Error message overlay
          if (_scanError != null)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _scanError!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => setState(() => _scanError = null),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================================================================
  // ✅ PROCESS QR: With Seller UI Refresh After Success
  // ==================================================================
  Future<void> _processQR(BuildContext context, String qrPayload) async {
    setState(() {
      _isProcessing = true;
      _scanError = null;
    });
    await _controller.stop();

    try {
      // ✅ Trim and validate QR payload
      final cleanPayload = qrPayload.trim();
      debugPrint('🔍 [OrderCollection] Raw QR: "$cleanPayload"');

      if (!cleanPayload.startsWith('BB-')) {
        throw Exception('Invalid QR format (missing BB- prefix)');
      }

      final orderProvider = context.read<OrderProvider>();
      List<OrderModel> orders = [];

      // ✅ Handle NEW format: BB-LOC-{safe_location}-{order_id1,order_id2,...}
      if (cleanPayload.startsWith('BB-LOC-')) {
        final withoutPrefix = cleanPayload.substring(7); // Remove 'BB-LOC-'
        final firstDashIndex = withoutPrefix.indexOf('-');

        if (firstDashIndex == -1) {
          throw Exception('Invalid QR structure: expected BB-LOC-location-orderIds');
        }

        final orderIdsCsv = withoutPrefix.substring(firstDashIndex + 1).trim();
        if (orderIdsCsv.isEmpty) {
          throw Exception('Invalid QR structure: no order IDs found');
        }

        final orderIds = orderIdsCsv
            .split(',')
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toList();

        if (orderIds.isEmpty) {
          throw Exception('Invalid QR structure: no valid order IDs');
        }

        debugPrint('🔍 [OrderCollection] Extracted order IDs: $orderIds');
        orders = await orderProvider.getOrdersByIds(orderIds);
        debugPrint('📦 [OrderCollection] Found ${orders.length} orders from QR payload');

      } 
      // ✅ Handle LEGACY format: BB-{timestamp}-{buyer_id} (from orders_rows.sql)
      else {
        // Example: BB-1780059107094-4c8b5734-ac84-4400-9b91-cb4f35698a7e
        final withoutPrefix = cleanPayload.substring(3); // Remove 'BB-'
        final firstDashIndex = withoutPrefix.indexOf('-');

        if (firstDashIndex == -1) {
          throw Exception('Invalid QR structure: expected BB-timestamp-buyer_id');
        }

        // ✅ Extract buyer_id: everything after the FIRST dash
        final buyerId = withoutPrefix.substring(firstDashIndex + 1).trim();
        debugPrint('🔍 [OrderCollection] Extracted buyer ID: "$buyerId"');

        // ✅ Validate UUID format (case-insensitive)
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        );

        if (!uuidRegex.hasMatch(buyerId)) {
          debugPrint('❌ [OrderCollection] UUID validation failed for: "$buyerId"');
          throw Exception('Invalid buyer ID format');
        }

        debugPrint('✅ [OrderCollection] Valid buyer ID: $buyerId');

        // ✅ Fetch pending orders for this buyer
        orders = await orderProvider.getPendingOrdersForBuyer(buyerId);
        debugPrint('📦 [OrderCollection] Found ${orders.length} pending orders');
      }

      if (orders.isEmpty) {
        throw Exception('No pending orders found for this QR scan');
      }

      // ✅ Show confirmation dialog
      final confirm = await _showConfirmationDialog(context, orders);
      if (!confirm || !mounted) {
        _resumeScanning();
        return;
      }

      // ✅ Process collection for EACH order individually (to decrement stock)
      int successCount = 0;
      int failCount = 0;

      for (final order in orders) {
        try {
          // ✅ FIXED: Use SupabaseConfig.client directly
          final orderService = OrderService(SupabaseConfig.client);
          
          // ✅ CORRECT FIELD NAMES (matching OrderModel and DB schema):
          // - order.id: Order ID (UUID)
          // - order.listingId: Food listing ID (UUID) ← This is the critical field
          // - order.quantity: Quantity ordered (int)
          final result = await orderService.verifyPickupAndDecrementStock(
            orderId: order.id,           // ✅ Order ID
            listingId: order.listingId,  // ✅ Food listing ID (matches DB column: listing_id)
            orderQuantity: order.quantity, // ✅ Quantity to deduct
          );

          if (result) {
            successCount++;
            debugPrint('✅ [OrderCollection] Order ${order.id} collected & stock updated');
          } else {
            failCount++;
            debugPrint('❌ [OrderCollection] Order ${order.id} failed to collect');
          }
        } catch (e) {
          failCount++;
          debugPrint('❌ [OrderCollection] Error processing order ${order.id}: $e');
        }
      }

      if (!mounted) return;

      // ✅ CRITICAL: Refresh seller listings to show updated quantities
      if (successCount > 0) {
        debugPrint('🔄 [OrderCollection] Refreshing seller listings...');
        await context.read<SellerProvider>().loadListings();
        debugPrint('✅ [OrderCollection] Seller UI refreshed with updated quantities');
      }

      // ✅ Show result dialog
      if (successCount > 0) {
        _showSuccessDialog(context, successCount, failCount);
      } else {
        setState(() => _scanError = 'Failed to update orders');
        debugPrint('❌ [OrderCollection] All collections failed');
        _resumeScanning();
      }

    } catch (e) {
      debugPrint('❌ [OrderCollection] Error: $e');
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() => _scanError = msg);
      _resumeScanning();
    }
  }

  void _resumeScanning() {
    if (mounted) {
      setState(() => _isProcessing = false);
      _controller.start();
    }
  }

  // ==================================================================
  // CONFIRMATION DIALOG - FIXED FIELD NAMES (Matches OrderModel)
  // ==================================================================
  Future<bool> _showConfirmationDialog(
    BuildContext context,
    List<OrderModel> orders,
  ) async {
    // ✅ Calculate total using CORRECT field names from OrderModel:
    // - order.price: joined from food_listings.discounted_price (nullable)
    // - order.quantity: from orders.quantity
    final total = orders.fold<double>(
      0.0,
      (sum, order) {
        final unitPrice = order.price ?? 0; // ✅ Use order.price (not discountedPrice)
        return sum + (unitPrice * order.quantity);
      },
    );

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Pickup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📦 ${orders.length} order(s) to collect:'),
            const SizedBox(height: 8),
            // Show first 3 order items as preview
            ...orders.take(3).map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  // ✅ Use order.foodName (joined from food_listings.food_name)
                  // Fallback to listingId substring if foodName is null
                  '• ${order.foodName ?? 'Item'} x${order.quantity}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            if (orders.length > 3)
              Text(
                '... and ${orders.length - 3} more',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            const SizedBox(height: 12),
            Text(
              'Total: RM ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Payment Reminder',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ensure payment has been settled manually (cash/external QR) before confirming collection.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Collection'),
          ),
        ],
      ),
    ) ?? false;
  }

  // ==================================================================
  // SUCCESS DIALOG
  // ==================================================================
  void _showSuccessDialog(BuildContext context, int success, int failed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 28),
            const SizedBox(width: 8),
            const Text('Pickup Verified!'),
          ],
        ),
        content: Text(
          '$success order(s) marked as collected.${failed > 0 ? '\n$failed failed to update.' : ''}',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Return to seller dashboard
            },
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}