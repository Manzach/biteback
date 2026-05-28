// FILE: lib/screens/seller/order_collection_screen.dart
// ============================================================================
// ORDER COLLECTION SCREEN (SELLER QR SCANNER)
// ============================================================================
// Allows sellers to scan buyer QR codes to verify pickup
// - Parses QR payload: BB-LOC-{safe_location}-{uuid1,uuid2,uuid3}
// - Displays order details for confirmation
// - Updates order status to 'collected' + deducts listing quantity
// Aligns with FYP Report: UC-04, Figure 38, Table 12
// ============================================================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

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
        title: const Text('Scan Order QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              final String? qrValue = capture.barcodes.first.rawValue;
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
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
  // ✅ PROCESS SCANNED QR CODE (FIXED PARSING LOGIC)
  // ==================================================================
  Future<void> _processQR(BuildContext context, String qrPayload) async {
    setState(() {
      _isProcessing = true;
      _scanError = null;
    });
    
    // Pause scanning while processing
    await _controller.stop();

    try {
      // ✅ Parse format: BB-LOC-{safe_location}-{uuid1,uuid2,uuid3}
      // Example: BB-LOC-Mahallah_As_Siddiq-4c8b5734-ac84-4400-9b91-cb4f35698a7e,b602574f-8ec6-40d2-bca9-4a42214c1098
      
      // 1. Validate prefix
      if (!qrPayload.startsWith('BB-LOC-')) {
        throw Exception('Invalid QR format: missing BB-LOC- prefix');
      }
      
      // 2. Remove prefix
      final withoutPrefix = qrPayload.substring(7); // Remove 'BB-LOC-'
      
      // 3. Find the LAST dash to separate location from order IDs
      // (Location may contain underscores, but order IDs are UUIDs with dashes)
      final lastDashIndex = withoutPrefix.lastIndexOf('-');
      
      if (lastDashIndex == -1 || lastDashIndex == withoutPrefix.length - 1) {
        throw Exception('Invalid QR structure: cannot separate location from order IDs');
      }
      
      // 4. Extract location (replace underscores back to spaces for display)
      final location = withoutPrefix.substring(0, lastDashIndex).replaceAll('_', ' ');
      
      // 5. Extract order IDs (comma-separated full UUIDs)
      final orderIdsRaw = withoutPrefix.substring(lastDashIndex + 1);
      final orderIds = orderIdsRaw.split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();
      
      if (orderIds.isEmpty) {
        throw Exception('No valid order IDs found in QR code');
      }
      
      // ✅ Validate UUID format (optional but helpful for debugging)
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
      final invalidIds = orderIds.where((id) => !uuidRegex.hasMatch(id)).toList();
      if (invalidIds.isNotEmpty) {
        debugPrint('⚠️ [OrderCollection] Warning: Invalid UUID format in: $invalidIds');
        // Continue anyway - Supabase will reject invalid IDs
      }

      debugPrint('🔍 [OrderCollection] Parsed QR:');
      debugPrint('   - Location: $location');
      debugPrint('   - Order IDs: $orderIds');

      // ✅ Show confirmation dialog with order details
      final confirm = await _showConfirmationDialog(context, orderIds, location);
      if (!confirm || !mounted) {
        _resumeScanning();
        return;
      }

      // ✅ Process collection via Provider
      final orderProvider = context.read<OrderProvider>();
      final result = await orderProvider.collectOrders(orderIds);

      if (!mounted) return;
      
      if (result['success']! > 0) {
        _showSuccessDialog(context, result['success']!, result['failed']!);
      } else {
        setState(() => _scanError = 'Failed to update orders. Try again.');
        _resumeScanning();
      }
      
    } catch (e) {
      debugPrint('❌ [OrderCollection] QR processing error: $e');
      if (!mounted) return;
      setState(() => _scanError = 'Invalid or expired QR code');
      _resumeScanning();
    }
  }

  void _resumeScanning() {
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      _controller.start();
    }
  }

  // ==================================================================
  // CONFIRMATION DIALOG (Show Order Details Before Collecting)
  // ==================================================================
  Future<bool> _showConfirmationDialog(
    BuildContext context, 
    List<String> orderIds,
    String location,
  ) async {
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
            Text('📍 Location: $location'),
            const SizedBox(height: 8),
            Text('This QR contains ${orderIds.length} order(s).'),
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
                  Text('⚠️ Payment Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
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