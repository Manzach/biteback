import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load data after first frame to avoid build-time async calls
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final buyerId = context.read<AuthProvider>().currentUser?.id;
      if (buyerId != null) {
        context.read<OrderProvider>().loadOrderHistory(buyerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text('Order History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderProvider.error != null
              ? _buildErrorState(orderProvider)
              : orderProvider.ordersByDate.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orderProvider.ordersByDate.length,
                      itemBuilder: (context, index) {
                        final date = orderProvider.ordersByDate.keys.elementAt(index);
                        final orders = orderProvider.ordersByDate[date]!;
                        return _buildDateGroup(date, orders);
                      },
                    ),
    );
  }

  Widget _buildDateGroup(String date, List<OrderModel> orders) {
    double dailyTotal = orders.fold(0.0, (sum, o) => sum + ((o.price ?? 0) * o.quantity));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        ...orders.map((order) => _buildOrderItem(order)),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Total', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('RM ${dailyTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
            ],
          ),
        ),
        const Divider(thickness: 1),
      ],
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
            child: order.foodPhotoUrl?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(order.foodPhotoUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.restaurant, color: Colors.grey[400])),
                  )
                : Icon(Icons.restaurant, color: Colors.grey[400]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.foodName ?? 'Food Item', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text('Qty: ${order.quantity} • ${order.status.toUpperCase()}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Text('RM ${((order.price ?? 0) * order.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorState(OrderProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(provider.error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadOrderHistory(context.read<AuthProvider>().currentUser?.id ?? ''),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No orders yet', style: TextStyle(color: Colors.grey, fontSize: 14)),
          Text('Your purchase history will appear here', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}