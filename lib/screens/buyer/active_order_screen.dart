import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class ActiveOrderScreen extends StatefulWidget {
  const ActiveOrderScreen({super.key});

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  @override
  void initState() {
    super.initState();
    // Load active orders AFTER first frame to avoid build-time async calls
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final buyerId = context.read<AuthProvider>().currentUser?.id;
      if (buyerId != null) {
        // ✅ Load ALL active orders grouped by location (not just one)
        context.read<OrderProvider>().loadActiveOrdersByLocation(buyerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final activeOrders = orderProvider.activeOrdersByLocation;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text('Active Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeOrders.isEmpty
              ? _buildNoActiveOrders()
              : ListView.builder(  // ✅ Changed to ListView for multiple locations
                  padding: const EdgeInsets.all(16),
                  itemCount: activeOrders.length,
                  itemBuilder: (context, index) {
                    final location = activeOrders.keys.elementAt(index);
                    final orders = activeOrders[location]!;
                    return _buildLocationGroup(location, orders);
                  },
                ),
    );
  }

  // ==================================================================
  // ✅ NEW: Build Location Group Card (Multiple Orders per Location)
  // ==================================================================
  Widget _buildLocationGroup(String location, List<OrderModel> orders) {
    // Calculate total for this location
    final total = orders.fold<double>(
      0.0,
      (sum, order) => sum + ((order.price ?? 0) * order.quantity),
    );

    // Generate QR payload: unique per location + all order IDs
    final orderIds = orders.map((o) => o.id).join(',');
    final qrPayload = 'BB-LOC-${location.replaceAll(' ', '_')}_$orderIds';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📍 Location Header
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primaryOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${orders.length} item${orders.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 📋 Order Items at This Location
            ...orders.map((order) => _buildOrderItem(order)),

            // 💰 Location Total
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Location Total', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    'RM ${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange, fontSize: 16),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1),

            // 🎫 QR Code for This Location (Single QR for all orders at this location)
            Center(
              child: Column(
                children: [
                  const Text('Scan at Pickup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  QrImageView(
                    data: qrPayload, // Unique payload per location
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Orders: ${orders.length}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // 📌 Pickup Instructions
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📌 Instructions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    SizedBox(height: 6),
                    Text(
                      '1. Show this QR code to staff at this location\n2. Staff will verify your order\n3. Collect all items listed above',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // Helper: Build Individual Order Item Row
  // ==================================================================
  Widget _buildOrderItem(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Photo/Placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: order.foodPhotoUrl?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order.foodPhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.restaurant, color: Colors.grey[400], size: 24),
                    ),
                  )
                : Icon(Icons.restaurant, color: Colors.grey[400], size: 24),
          ),
          const SizedBox(width: 12),
          // Order Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.foodName ?? 'Food Item',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Qty: ${order.quantity}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(order.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Price
          Text(
            'RM ${((order.price ?? 0) * order.quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // Helper: Get Status Color
  // ==================================================================
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[700]!;
      case 'collected':
        return Colors.green[700]!;
      case 'cancelled':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  // ==================================================================
  // Helper: Empty State
  // ==================================================================
  Widget _buildNoActiveOrders() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No active orders', style: TextStyle(color: Colors.grey, fontSize: 14)),
          Text('Place an order to see your QR code here', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}