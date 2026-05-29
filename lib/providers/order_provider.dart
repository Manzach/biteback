// FILE: lib/providers/order_provider.dart
// ============================================================================
// ORDER PROVIDER
// ============================================================================
// State management for buyer orders (UC-04: Purchase Near-Expiry Food)
// - Fetches order history (grouped by date for OrderHistoryScreen)
// - Fetches active orders grouped by location (for multi-location QR pickup)
// - Collects orders via seller QR scan (UC-04 completion)
// - Handles loading, error, and refresh states
// Aligns with FYP Report: Table 12 (Order), UC-04, Figure 38
// ============================================================================

import 'package:flutter/foundation.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _service;
  
  // State variables (private)
  Map<String, List<OrderModel>> _ordersByDate = {};
  Map<String, List<OrderModel>> _activeOrdersByLocation = {};
  bool _isLoading = false;
  String? _error;

  OrderProvider(this._service);

  // ==================================================================
  // GETTERS (Public, read-only for UI)
  // ==================================================================
  Map<String, List<OrderModel>> get ordersByDate => Map.unmodifiable(_ordersByDate);
  Map<String, List<OrderModel>> get activeOrdersByLocation => Map.unmodifiable(_activeOrdersByLocation);
  
  // Backward compatible: return first active order if needed
  OrderModel? get activeOrder => _activeOrdersByLocation.values
      .expand((orders) => orders)
      .firstOrNull;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================================================================
  // LOAD ORDER HISTORY (Grouped by Date)
  // ==================================================================
  Future<void> loadOrderHistory(String buyerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ordersByDate = await _service.getOrderHistory(buyerId);
    } catch (e) {
      _error = 'Failed to load order history: ${e.toString().replaceAll('Exception: ', '')}';
      debugPrint('❌ OrderProvider.loadOrderHistory error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // LOAD ACTIVE ORDERS BY LOCATION (For Multi-Location QR Pickup)
  // ==================================================================
  Future<void> loadActiveOrdersByLocation(String buyerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _activeOrdersByLocation = await _service.getActiveOrdersByLocation(buyerId);
    } catch (e) {
      debugPrint('❌ OrderProvider.loadActiveOrdersByLocation error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // BACKWARD COMPATIBLE: Load single active order
  // ==================================================================
  Future<void> loadActiveOrder(String buyerId) async {
    await loadActiveOrdersByLocation(buyerId);
  }

  // ==================================================================
  // ✅ NEW: FETCH PENDING ORDERS FOR BUYER (QR Collection Flow)
  // ==================================================================
  /// Fetches all pending orders for a specific buyer
  /// Used by OrderCollectionScreen when seller scans buyer's QR code
  /// 
  /// Parameters:
  ///   - buyerId: The UUID of the buyer whose orders to fetch
  /// 
  /// Returns:
  ///   List of pending OrderModel objects (flattened from location groups)
  // ==================================================================
  Future<List<OrderModel>> getPendingOrdersForBuyer(String buyerId) async {
    try {
      debugPrint('🔍 [OrderProvider] Fetching pending orders for buyer $buyerId');
      
      // ✅ Fetch active orders grouped by location from service
      final grouped = await _service.getActiveOrdersByLocation(buyerId);
      
      // ✅ Flatten the grouped map to a single list of pending orders
      final pending = grouped.values.expand((list) => list).toList();
      
      debugPrint('✅ [OrderProvider] Found ${pending.length} pending orders for buyer $buyerId');
      return pending;
      
    } catch (e, stack) {
      debugPrint('❌ [OrderProvider] getPendingOrdersForBuyer error: $e');
      debugPrint('📋 Stack: $stack');
      return [];
    }
  }

  // ==================================================================
  // ✅ FETCH ORDERS BY IDs (For QR Collection Flow)
  // ==================================================================
  /// Fetches specific orders by their IDs
  /// Used when seller scans QR and needs to validate order details
  /// 
  /// Parameters:
  ///   - orderIds: List of order UUIDs to fetch
  /// 
  /// Returns:
  ///   List of OrderModel objects matching the provided IDs
  // ==================================================================
  Future<List<OrderModel>> getOrdersByIds(List<String> orderIds) async {
    try {
      if (orderIds.isEmpty) return [];
      
      debugPrint('🔍 [OrderProvider] Fetching orders for IDs: $orderIds');
      return await _service.getOrdersByIds(orderIds);
    } catch (e, stack) {
      debugPrint('❌ [OrderProvider] getOrdersByIds error: $e');
      debugPrint('📋 Stack: $stack');
      return [];
    }
  }

  // ==================================================================
  // ✅ COLLECT ORDERS VIA SELLER QR SCAN (UC-04 Completion)
  // ==================================================================
  /// Updates order status to 'collected' and deducts listing quantity
  /// Called when seller scans buyer's QR code at pickup
  /// 
  /// Parameters:
  ///   - orderIds: List of order IDs to collect (parsed from QR payload)
  /// 
  /// Returns:
  ///   Map with 'success' and 'failed' counts for partial success handling
  // ==================================================================
  Future<Map<String, int>> collectOrders(List<String> orderIds) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      debugPrint('🔄 [OrderProvider] Collecting ${orderIds.length} order(s)');
      final result = await _service.collectOrders(orderIds);
      debugPrint('📊 [OrderProvider] Collection result: success=${result['success']}, failed=${result['failed']}');
      return result;
    } catch (e, stack) {
      debugPrint('❌ OrderProvider.collectOrders error: $e');
      debugPrint('📋 Stack: $stack');
      return {'success': 0, 'failed': orderIds.length};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // REFRESH ORDERS (After new purchase or collection)
  // ==================================================================
  Future<void> refreshOrders(String buyerId) async {
    await Future.wait([
      loadOrderHistory(buyerId),
      loadActiveOrdersByLocation(buyerId),
    ]);
  }

  // ==================================================================
  // UTILITY METHODS
  // ==================================================================
  void clearError() {
    _error = null;
    notifyListeners();
  }

  double get totalSpent {
    return _ordersByDate.values
        .expand((orders) => orders)
        .fold(0.0, (sum, order) => sum + ((order.price ?? 0) * order.quantity));
  }

  int get collectedCount {
    return _ordersByDate.values
        .expand((orders) => orders)
        .where((order) => order.status == 'collected')
        .length;
  }

  int get pendingCount {
    return _activeOrdersByLocation.values
        .expand((orders) => orders)
        .where((order) => order.status == 'pending')
        .length;
  }

  List<String> get activePickupLocations => _activeOrdersByLocation.keys.toList();
}