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

      final orders = (response as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => OrderModel.fromJson(json))
          .toList();

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
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final orders = (response as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => OrderModel.fromJson(json))
          .toList();

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
  // ✅ COLLECT ORDERS VIA SELLER QR SCAN (UC-04 Completion) - SECURE VERSION
  // ==================================================================
  Future<Map<String, int>> collectOrders(List<String> orderIds) async {
    int success = 0;
    int failed = 0;

    // Get current authenticated user (the seller scanning the QR)
    final currentSellerId = _client.auth.currentUser?.id;
    if (currentSellerId == null) {
      debugPrint('❌ [OrderService] collectOrders: No authenticated user');
      return {'success': 0, 'failed': orderIds.length};
    }

    debugPrint('🔐 [OrderService] collectOrders: Seller $currentSellerId attempting to collect ${orderIds.length} order(s)');

    for (final orderId in orderIds) {
      try {
        // 🔐 STEP 1: Fetch order + listing + seller info for validation
        final orderCheck = await _client
            .from('orders')
            .select('''
              id,
              status,
              buyer_id,
              listing_id,
              quantity,
              food_listings!listing_id(
                id,
                seller_id,
                quantity
              )
            ''')
            .eq('id', orderId)
            .maybeSingle();

        if (orderCheck == null) {
          debugPrint('❌ [OrderService] Order $orderId not found');
          failed++;
          continue;
        }

        final orderStatus = orderCheck['status'] as String?;
        final orderQty = orderCheck['quantity'] as int? ?? 0;
        final listingId = orderCheck['listing_id'] as String?;
        final listingData = orderCheck['food_listings'] as Map<String, dynamic>?;
        final listingSellerId = listingData?['seller_id'] as String?;
        final currentStock = listingData?['quantity'] as int? ?? 0;

        debugPrint('🔍 [OrderService] Validating order $orderId:');
        debugPrint('   - Status: $orderStatus');
        debugPrint('   - Listing seller: $listingSellerId');
        debugPrint('   - Current scanner: $currentSellerId');

        // 🔐 STEP 2: Validate order status is 'pending'
        if (orderStatus != 'pending') {
          debugPrint('❌ [OrderService] Order $orderId cannot be collected: status is "$orderStatus" (expected "pending")');
          failed++;
          continue;
        }

        // 🔐 STEP 3: Validate seller ownership (CRITICAL SECURITY CHECK)
        if (listingSellerId != currentSellerId) {
          debugPrint('❌ [OrderService] Security violation: Seller $currentSellerId attempted to collect order $orderId belonging to seller $listingSellerId');
          failed++;
          continue;
        }

        // ✅ All validations passed - proceed with collection

        // STEP 4: Update order status to 'collected'
        final orderUpdate = await _client
            .from('orders')
            .update({
              'status': 'collected',
              'collected_at': DateTime.now().toIso8601String(),
            })
            .eq('id', orderId)
            .eq('status', 'pending') // Optimistic locking: only update if still pending
            .select();

        if (orderUpdate.isEmpty) {
          debugPrint('❌ [OrderService] Order $orderId update failed (possibly already collected by another seller)');
          failed++;
          continue;
        }

        // STEP 5: Deduct quantity from food listing
        if (listingId != null && currentStock >= orderQty) {
          final newStock = currentStock - orderQty;
          await _client
              .from('food_listings')
              .update({'quantity': newStock})
              .eq('id', listingId);
          debugPrint('📦 [OrderService] Deducted $orderQty from listing $listingId. New stock: $newStock');
        }

        debugPrint('✅ [OrderService] Successfully collected order $orderId');
        success++;

      } catch (e, stack) {
        debugPrint('❌ [OrderService] Failed to collect order $orderId: $e');
        debugPrint('📋 [OrderService] Stack: $stack');
        failed++;
      }
    }

    debugPrint('📊 [OrderService] collectOrders complete: $success succeeded, $failed failed');
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