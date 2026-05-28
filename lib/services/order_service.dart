// FILE: lib/services/order_service.dart
// ============================================================================
// ORDER SERVICE
// ============================================================================
// Handles Supabase database operations for buyer orders
// - Fetch order history (grouped by date)
// - Fetch active orders grouped by location (for QR pickup verification)
// - Collect orders via seller QR scan (UC-04 completion)
// Aligns with FYP Report: Table 12 (Order table), UC-04, Figure 38
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';

class OrderService {
  final SupabaseClient _client;

  OrderService(this._client);

  // ==================================================================
  // FETCH ORDER HISTORY (Grouped by Date)
  // ==================================================================
  /// Retrieves all orders for a specific buyer, grouped by formatted date
  /// Used by OrderHistoryScreen to display past purchases
  // ==================================================================
  Future<Map<String, List<OrderModel>>> getOrderHistory(String buyerId) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            *,
            food_listings!listing_id (
              food_name,
              photo_url,
              discounted_price,
              location
            )
          ''')
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false);

      // Parse response into OrderModel list
      final orders = (response as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => OrderModel.fromJson(json))
          .toList();

      // Group orders by formatted date for UI display
      final grouped = <String, List<OrderModel>>{};
      for (final order in orders) {
        final dateKey = '${order.createdAt.day} ${_monthName(order.createdAt.month)} ${order.createdAt.year}';
        grouped.putIfAbsent(dateKey, () => []).add(order);
      }

      return grouped;
    } catch (e) {
      debugPrint('❌ OrderService.getOrderHistory error: $e');
      throw Exception('Failed to load order history');
    }
  }

  // ==================================================================
  // ✅ FETCH ACTIVE ORDERS BY LOCATION (For QR Pickup Verification)
  // ==================================================================
  /// Retrieves only PENDING orders for a buyer, grouped by pickup location
  /// Used by ActiveOrderScreen to display QR codes for orders still to collect
  /// 
  /// NOTE: Orders with status 'collected' or 'cancelled' are EXCLUDED
  /// to keep the UI clean and prevent confusion.
  // ==================================================================
  Future<Map<String, List<OrderModel>>> getActiveOrdersByLocation(String buyerId) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            *,
            food_listings!listing_id (
              food_name,
              photo_url,
              discounted_price,
              location
            )
          ''')
          .eq('buyer_id', buyerId)
          .eq('status', 'pending') // ✅ CHANGED: Only show pending orders
          .order('created_at', ascending: false);

      final orders = (response as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => OrderModel.fromJson(json))
          .toList();

      // Group orders by pickup location
      final grouped = <String, List<OrderModel>>{};
      for (final order in orders) {
        final location = order.pickupLocation ?? 'Unknown Location';
        grouped.putIfAbsent(location, () => []).add(order);
      }

      return grouped;
    } catch (e) {
      debugPrint('❌ OrderService.getActiveOrdersByLocation error: $e');
      return {};
    }
  }

  // ==================================================================
  // ✅ COLLECT ORDERS VIA SELLER QR SCAN (UC-04 Completion)
  // ==================================================================
  /// Updates order status to 'collected' and deducts listing quantity
  /// Called when seller scans buyer's QR code at pickup
  /// 
  /// Parameters:
  ///   - orderIds: List of order IDs to collect (from QR payload)
  /// 
  /// Returns:
  ///   Map with 'success' and 'failed' counts for partial success handling
  // ==================================================================
  Future<Map<String, int>> collectOrders(List<String> orderIds) async {
    int success = 0;
    int failed = 0;

    for (final orderId in orderIds) {
      try {
        // 1️⃣ Fetch order + listing details in one query
        final response = await _client
            .from('orders')
            .select('''
              quantity,
              listing_id,
              food_listings!listing_id(quantity)
            ''')
            .eq('id', orderId)
            .single();

        final orderQty = response['quantity'] as int;
        final listingId = response['listing_id'] as String;
        final currentStock = (response['food_listings'] as Map)['quantity'] as int;

        // 2️⃣ Update order status to collected
        await _client
            .from('orders')
            .update({
              'status': 'collected',
              'collected_at': DateTime.now().toIso8601String(),
            })
            .eq('id', orderId);

        // 3️⃣ Deduct quantity from food listing
        final newStock = currentStock - orderQty;
        await _client
            .from('food_listings')
            .update({'quantity': newStock})
            .eq('id', listingId);

        success++;
      } catch (e) {
        debugPrint('❌ Failed to collect order $orderId: $e');
        failed++;
      }
    }

    return {'success': success, 'failed': failed};
  }

  // ==================================================================
  // HELPER: Format month number to 3-letter name
  // ==================================================================
  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}