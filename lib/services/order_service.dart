// FILE: lib/services/order_service.dart
// ============================================================================
// ORDER SERVICE
// ============================================================================
// Handles Supabase database operations for buyer orders (UC-04)
// - Create orders with QR code generation (BB-{timestamp}-{buyer_id})
// - Fetch order history grouped by date
// - Fetch active orders grouped by location for QR pickup
// - Collect orders via seller QR scan (status: 'pending' → 'collected')
// - Verify pickup AND decrement stock (new method for QR flow)
// Aligns with FYP Report: Table 12 (Order), UC-04, Figure 38
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';

class OrderService {
  final SupabaseClient _client;

  OrderService(this._client);

  // ==================================================================
  // ✅ CREATE ORDER + GENERATE QR (Buyer Checkout) - MATCHES YOUR DB
  // ==================================================================
  Future<OrderModel> createOrder({
    required String buyerId,
    required String sellerId,
    required String listingId,
    required int quantity,
    required double totalPrice,
    required String pickupLocation,
  }) async {
    try {
      debugPrint('🛒 [OrderService] Creating order for buyer $buyerId...');

      // ✅ Generate QR payload in YOUR format: BB-{timestamp}-{buyer_id}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final qrCode = 'BB-$timestamp-$buyerId';

      debugPrint('🔑 [OrderService] Generated QR: $qrCode');

      // ✅ Insert order with lowercase 'pending' status (matches orders_rows.sql)
      // Note: orders table does NOT have seller_id - ownership verified via food_listings
      final response = await _client.from('orders').insert({
        'buyer_id': buyerId,
        'listing_id': listingId,
        'quantity': quantity,
        'total_price': totalPrice,
        'status': 'pending',           // ✅ Lowercase to match your DB
        'qr_code': qrCode,             // ✅ Format: BB-{timestamp}-{buyer_id}
        'pickup_location': pickupLocation,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      debugPrint('✅ [OrderService] Order created: ${response['id']}');
      return OrderModel.fromJson(response);

    } on PostgrestException catch (e) {
      debugPrint('💥 [OrderService] PostgrestException in createOrder: ${e.message}');
      debugPrint('   - Code: ${e.code}');
      debugPrint('   - Details: ${e.details}');
      throw Exception('Failed to create order: ${e.message}');
    } catch (e, stack) {
      debugPrint('❌ [OrderService] createOrder error: $e');
      debugPrint('📋 Stack: $stack');
      throw Exception('Failed to create order');
    }
  }

  // ==================================================================
  // ✅ UPDATE ORDER STATUS (Standalone) - LOWERCASE VALUES
  // ==================================================================
  Future<bool> updateOrderStatus({
    required String orderId,
    required String newStatus,
  }) async {
    try {
      debugPrint('🔄 [OrderService] Updating order $orderId to $newStatus');
      final dbStatus = _mapStatusToDatabaseValue(newStatus);

      final response = await _client
          .from('orders')
          .update({'status': dbStatus})  // ✅ REMOVED 'updated_at' - doesn't exist in orders table
          .eq('id', orderId)
          .select();

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [OrderService] updateOrderStatus error: $e');
      return false;
    }
  }

  // ==================================================================
  // HELPER: Map status to lowercase (matches YOUR DB from orders_rows.sql)
  // ==================================================================
  String _mapStatusToDatabaseValue(String input) {
    switch (input.toLowerCase()) {
      case 'pending':
        return 'pending';
      case 'confirmed':
        return 'confirmed';
      case 'picked_up':
      case 'collected':
        return 'collected'; // ✅ Your DB uses 'collected' (lowercase)
      case 'completed':
        return 'completed';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      default:
        return input.toLowerCase();
    }
  }

  // ==================================================================
  // FETCH ORDER HISTORY (Grouped by Date) - For OrderHistoryScreen
  // ==================================================================
  Future<Map<String, List<OrderModel>>> getOrderHistory(String buyerId) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            *,
            food_listings!listing_id(
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
  // FETCH ACTIVE ORDERS BY LOCATION (For QR Pickup) - For ActiveOrderScreen
  // ==================================================================
  Future<Map<String, List<OrderModel>>> getActiveOrdersByLocation(String buyerId) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            *,
            food_listings!listing_id(
              food_name,
              photo_url,
              discounted_price,
              location
            )
          ''')
          .eq('buyer_id', buyerId)
          .eq('status', 'pending') // ✅ Lowercase to match your DB
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
  // ✅ FETCH ORDERS BY IDs (For QR Collection Flow) - FIXED .in_() ERROR
  // ==================================================================
  Future<List<OrderModel>> getOrdersByIds(List<String> orderIds) async {
    if (orderIds.isEmpty) return [];

    try {
      // ✅ FIX: Use .filter() with 'in' operator instead of .in_()
      final idsString = orderIds.map((id) => '"$id"').join(',');

      final response = await _client
          .from('orders')
          .select('''
            *,
            food_listings!listing_id(
              food_name,
              photo_url,
              discounted_price,
              location
            )
          ''')
          .filter('id', 'in', '($idsString)');

      return (response as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ OrderService.getOrdersByIds error: $e');
      return [];
    }
  }

  // ==================================================================
  // ✅ COLLECT ORDERS VIA SELLER QR SCAN (UC-04) - MATCHES YOUR DB
  // ==================================================================
  Future<Map<String, int>> collectOrders(List<String> orderIds) async {
    int success = 0, failed = 0;
    final sellerId = _client.auth.currentUser?.id;
    if (sellerId == null) return {'success': 0, 'failed': orderIds.length};

    for (final orderId in orderIds) {
      try {
        // STEP 1: Fetch order + listing for validation
        final check = await _client.from('orders')
            .select('''
              id,
              status,
              listing_id,
              quantity,
              food_listings!listing_id(
                seller_id,
                quantity
              )
            ''')
            .eq('id', orderId)
            .maybeSingle();

        if (check == null) {
          debugPrint('❌ [OrderService] Order $orderId not found');
          failed++;
          continue;
        }

        final status = check['status'] as String?;
        final qty = check['quantity'] as int? ?? 0;
        final listingId = check['listing_id'] as String?;
        final listing = check['food_listings'] as Map<String, dynamic>?;
        final listingSellerId = listing?['seller_id'] as String?;
        final stock = listing?['quantity'] as int? ?? 0;

        debugPrint('🔍 [OrderService] Validating order $orderId: status=$status, seller=$listingSellerId');

        // STEP 2: Validate status is 'pending' (lowercase to match YOUR DB)
        if (status?.toLowerCase() != 'pending') {
          debugPrint('❌ [OrderService] Order $orderId cannot be collected: status is "$status"');
          failed++;
          continue;
        }

        // STEP 3: Validate seller owns the listing (security check)
        // ⚠️ orders table does NOT have seller_id - verify via food_listings
        if (listingSellerId != sellerId) {
          debugPrint('❌ [OrderService] Security: Seller $sellerId cannot collect order from seller $listingSellerId');
          failed++;
          continue;
        }

        // STEP 4: Update order to 'collected' (lowercase) + add collected_at
        final update = await _client.from('orders')
            .update({
              'status': 'collected',           // ✅ Your DB uses 'collected' (lowercase)
              'collected_at': DateTime.now().toIso8601String(),
            })
            .eq('id', orderId)
            .eq('status', 'pending')           // ✅ Optimistic locking with lowercase
            .select();

        if (update.isEmpty) {
          debugPrint('❌ [OrderService] Order $orderId update failed or already collected');
          failed++;
          continue;
        }

        // STEP 5: Deduct stock from food listing
        if (listingId != null && stock >= qty) {
          final newStock = stock - qty;
          await _client.from('food_listings')
              .update({'quantity': newStock})  // ✅ REMOVED 'updated_at' - doesn't exist
              .eq('id', listingId);
          debugPrint('📦 [OrderService] Deducted $qty from listing $listingId. New stock: $newStock');
        }

        debugPrint('✅ [OrderService] Successfully collected order $orderId');
        success++;

      } catch (e, stack) {
        debugPrint('❌ [OrderService] Failed to collect order $orderId: $e');
        debugPrint('📋 Stack: $stack');
        failed++;
      }
    }

    debugPrint('📊 [OrderService] collectOrders complete: $success succeeded, $failed failed');
    return {'success': success, 'failed': failed};
  }

  // ==================================================================
  // ✅ FIXED: VERIFY PICKUP AND DECREMENT STOCK (For QR Scan Flow)
  // ==================================================================
  /// Verifies a single order pickup via QR scan AND decrements food listing quantity
  /// This ensures inventory stays in sync after successful pickup
  /// 
  /// ⚠️ IMPORTANT: 
  /// - orders table does NOT have seller_id column → verify via food_listings.seller_id
  /// - orders table does NOT have updated_at column → removed from update query
  /// - food_listings table does NOT have updated_at column → removed from update query
  /// 
  /// Parameters:
  ///   - orderId: ID of the order to verify
  ///   - listingId: ID of the food listing to update
  ///   - orderQuantity: Quantity ordered (to deduct from stock)
  /// 
  /// Returns:
  ///   true if both order update and stock decrement succeed, false otherwise
  // ==================================================================
  Future<bool> verifyPickupAndDecrementStock({
    required String orderId,
    required String listingId,
    required int orderQuantity,
  }) async {
    try {
      final sellerId = _client.auth.currentUser?.id;
      debugPrint('🔍 [OrderService] === START verifyPickupAndDecrementStock ===');
      debugPrint('🔍 [OrderService] orderId: $orderId');
      debugPrint('🔍 [OrderService] listingId: $listingId');
      debugPrint('🔍 [OrderService] orderQuantity: $orderQuantity');
      debugPrint('🔍 [OrderService] sellerId (auth): $sellerId');
      
      if (sellerId == null) {
        debugPrint('❌ [OrderService] FAIL: No authenticated user');
        return false;
      }

      // STEP 1: Fetch order details (NO seller_id in orders table)
      debugPrint('🔍 [OrderService] STEP 1: Fetching order details...');
      final orderCheck = await _client
          .from('orders')
          .select('id, status, listing_id, quantity')
          .eq('id', orderId)  // ✅ Safe: orderId is required String (non-nullable)
          .maybeSingle();

      if (orderCheck == null) {
        debugPrint('❌ [OrderService] FAIL: Order not found in DB');
        return false;
      }
      
      final orderStatus = orderCheck['status'] as String?;
      final orderListingId = orderCheck['listing_id'] as String?;  // ⚠️ Nullable!
      final orderQty = orderCheck['quantity'] as int? ?? 0;
      
      debugPrint('📦 [OrderService] Order found:');
      debugPrint('   - status: "$orderStatus"');
      debugPrint('   - listing_id: "$orderListingId"');
      debugPrint('   - quantity: $orderQty');

      // ✅ FIX: Null-check listing_id before using it in queries
      if (orderListingId == null || orderListingId.isEmpty) {
        debugPrint('❌ [OrderService] FAIL: listing_id is null or empty');
        return false;
      }

      // STEP 2: Verify seller owns the LISTING (not the order)
      debugPrint('🔍 [OrderService] STEP 2: Verifying listing ownership...');
      final listingCheck = await _client
          .from('food_listings')
          .select('seller_id, quantity, availability_status')
          .eq('id', orderListingId)  // ✅ Now safe: orderListingId is null-checked above
          .maybeSingle();

      if (listingCheck == null) {
        debugPrint('❌ [OrderService] FAIL: Listing not found');
        return false;
      }

      final listingSellerId = listingCheck['seller_id'] as String?;
      final currentQty = listingCheck['quantity'] as int? ?? 0;
      final currentStatus = listingCheck['availability_status'] as String?;

      if (listingSellerId != sellerId) {
        debugPrint('❌ [OrderService] FAIL: Seller mismatch. Order belongs to seller: $listingSellerId');
        return false;
      }
      debugPrint('✅ [OrderService] Listing ownership verified');

      // STEP 3: Check order status is 'pending'
      if (orderStatus?.toLowerCase() != 'pending') {
        debugPrint('❌ [OrderService] FAIL: Order status is "$orderStatus", expected "pending"');
        return false;
      }

      // STEP 4: Update order status to 'collected'
      debugPrint('✅ [OrderService] STEP 4: Updating order status to "collected"...');
      final orderUpdate = await _client
          .from('orders')
          .update({
            'status': 'collected',
            'collected_at': DateTime.now().toIso8601String(),
            // ❌ REMOVED: 'updated_at' doesn't exist in orders table (PGRST204 error)
          })
          .eq('id', orderId)  // ✅ Safe: orderId is required String
          .eq('status', 'pending')  // Optimistic locking
          .select();

      if (orderUpdate.isEmpty) {
        debugPrint('❌ [OrderService] FAIL: Order update returned empty (already collected)');
        return false;
      }
      debugPrint('✅ [OrderService] Order status updated successfully');

      // STEP 5: Decrement stock
      if (orderQty <= 0) {
        debugPrint('⚠️ [OrderService] Order quantity is 0, skipping stock decrement');
      } else {
        final newQty = currentQty - orderQty;
        debugPrint('📦 [OrderService] STEP 5: Updating quantity: $currentQty → $newQty');

        final Map<String, dynamic> listingUpdates = {
          'quantity': newQty < 0 ? 0 : newQty,
          // ❌ REMOVED: 'updated_at' doesn't exist in food_listings table (PGRST204 error)
        };
        
        if (newQty <= 0) {
          listingUpdates['availability_status'] = 'sold';
          debugPrint('📦 [OrderService] Setting availability_status to "sold"');
        }

        final listingUpdate = await _client
            .from('food_listings')
            .update(listingUpdates)
            .eq('id', orderListingId)  // ✅ Safe: already null-checked
            .select();

        if (listingUpdate.isEmpty) {
          debugPrint('❌ [OrderService] FAIL: Listing update returned empty');
          return false;
        }
        debugPrint('✅ [OrderService] Listing quantity updated successfully');
      }

      debugPrint('✅ [OrderService] === SUCCESS: Pickup verified & stock updated ===');
      return true;

    } catch (e, stack) {
      debugPrint('❌ [OrderService] === EXCEPTION in verifyPickupAndDecrementStock ===');
      debugPrint('❌ [OrderService] Error: $e');
      debugPrint('❌ [OrderService] Stack: $stack');
      return false;
    }
  }

  // ==================================================================
  // HELPER: Format month number to 3-letter name
  // ==================================================================
  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}