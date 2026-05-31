// FILE: lib/providers/cart_provider.dart
// ============================================================================
// CART PROVIDER
// ============================================================================
// Manages shopping cart state and checkout flow for buyers
// Handles stock limits, quantity adjustments, and order creation
// Aligns with FYP Report: UC-04 (Purchase Near-Expiry Food)
// ============================================================================

import 'package:flutter/foundation.dart';
import '../models/food_listing_model.dart';
import '../models/order_model.dart';
import '../services/buyer_service.dart';

// ==================================================================
// ✅ CART ITEM MODEL (Helper class for cart state)
// ==================================================================
class CartItem {
  final FoodListing listing;
  int quantity;
  
  CartItem({required this.listing, this.quantity = 1});
  
  double get subtotal => listing.discountedPrice * quantity;
}

// ==================================================================
// ✅ CART PROVIDER (Main state manager for cart)
// ==================================================================
class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final BuyerService _service = BuyerService();

  // ==================================================================
  // GETTERS (Read-only for UI)
  // ==================================================================
  
  /// ✅ Read-only list for UI
  List<CartItem> get items => List.unmodifiable(_items);
  
  /// ✅ Calculate cart total
  double get total => _items.fold(
        0,
        (sum, item) => sum + (item.listing.discountedPrice * item.quantity),
      );

  /// ✅ Total item count (for badge)
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// ✅ Check if cart is empty
  bool get isEmpty => _items.isEmpty;

  // ==================================================================
  // CART MANAGEMENT METHODS
  // ==================================================================

  /// ✅ Add item with STOCK LIMIT check
  void addItem(FoodListing listing, {int requestedQty = 1}) {
    final existingIndex = _items.indexWhere((i) => i.listing.id == listing.id);
    final currentQty = existingIndex != -1 ? _items[existingIndex].quantity : 0;
    final maxAllowed = listing.quantity;

    if (currentQty >= maxAllowed) return;

    final newQty = currentQty + requestedQty;
    final finalQty = newQty > maxAllowed ? maxAllowed : newQty;

    if (existingIndex != -1) {
      _items[existingIndex].quantity = finalQty;
    } else {
      _items.add(CartItem(listing: listing, quantity: finalQty));
    }
    notifyListeners();
  }

  /// ✅ Safely increase quantity
  void increaseQuantity(String listingId) {
    final index = _items.indexWhere((i) => i.listing.id == listingId);
    if (index != -1) {
      final item = _items[index];
      if (item.quantity < item.listing.quantity) {
        item.quantity++;
        notifyListeners();
      }
    }
  }

  /// ✅ Safely decrease quantity or remove if 1
  void decreaseQuantity(String listingId) {
    final index = _items.indexWhere((i) => i.listing.id == listingId);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        notifyListeners();
      } else {
        removeItem(listingId);
      }
    }
  }

  void removeItem(String listingId) {
    _items.removeWhere((item) => item.listing.id == listingId);
    notifyListeners();
  }

  /// ✅ Clear entire cart (after successful checkout)
  void clearCart() {
    if (_items.isNotEmpty) {
      _items.clear();
      notifyListeners();
    }
  }

  // ==================================================================
  // CART HELPER METHODS
  // ==================================================================

  int getQuantityInCart(String listingId) {
    for (final item in _items) {
      if (item.listing.id == listingId) {
        return item.quantity;
      }
    }
    return 0;
  }

  bool isAtStockLimit(String listingId) {
    for (final item in _items) {
      if (item.listing.id == listingId) {
        return item.quantity >= item.listing.quantity;
      }
    }
    return false;
  }

  bool isInCart(String listingId) {
    return _items.any((item) => item.listing.id == listingId);
  }

  // ==================================================================
  // ✅ CHECKOUT FLOW - DENORMALIZED ORDER CREATION ✅
  // ==================================================================
  /// Creates 1 order per cart item, groups them by pickup location
  /// 
  /// DENORMALIZATION: Extracts foodName and unitPrice from each listing
  /// and passes them to createOrder() so historical orders show correct
  /// data even if the original listing is modified or deleted later.
  /// 
  /// Returns:
  ///   Map<String, List<OrderModel>> grouped by pickup location
  // ==================================================================
  Future<Map<String, List<OrderModel>>> checkout() async {
    final groupedOrders = <String, List<OrderModel>>{};
    
    for (final cartItem in _items) {
      // ✅ Extract denormalized data for historical accuracy
      final foodName = cartItem.listing.foodName;
      final unitPrice = cartItem.listing.discountedPrice;
      final quantity = cartItem.quantity;
      final listingId = cartItem.listing.id;
      
      try {
        // ✅ Pass ALL required parameters to createOrder()
        final order = await _service.createOrder(
          listingId: listingId,
          foodName: foodName,           // ✅ Required: snapshot of food name
          unitPrice: unitPrice,         // ✅ Required: price per unit at purchase
          quantity: quantity,
        );
        
        // Group orders by pickup location for OrderSuccessScreen display
        groupedOrders
            .putIfAbsent(cartItem.listing.location, () => [])
            .add(order);
            
      } catch (e) {
        debugPrint('❌ [CartProvider] Failed to create order for $foodName: $e');
        // Continue with other items instead of failing entire checkout
      }
    }
    
    // ✅ FIX: Call clearCart() as standalone statement (it returns void)
    // ❌ WRONG: return clearCart();  // Error: clearCart() returns void
    // ✅ CORRECT:
    clearCart();  // ✅ Just call it - don't try to use its result
    
    // ✅ Return the actual data (NOT the result of clearCart())
    return groupedOrders;  // ✅ This returns Map<String, List<OrderModel>>
  }

  // ==================================================================
  // UTILITY: Reset cart state
  // ==================================================================
  void reset() {
    _items.clear();
    notifyListeners();
  }
}