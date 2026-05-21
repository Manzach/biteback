import 'package:flutter/foundation.dart';
import '../models/food_listing_model.dart';
import '../models/order_model.dart';
import '../services/buyer_service.dart';

class CartItem {
  final FoodListing listing;
  int quantity;
  CartItem({required this.listing, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final BuyerService _service = BuyerService();

  // ✅ Read-only list for UI
  List<CartItem> get items => List.unmodifiable(_items);
  
  // ✅ Calculate cart total
  double get total => _items.fold(
        0,
        (sum, item) => sum + (item.listing.discountedPrice * item.quantity),
      );

  // ✅ Total item count (for badge)
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// ✅ Add item with STOCK LIMIT check
  void addItem(FoodListing listing, {int requestedQty = 1}) {
    final existingIndex = _items.indexWhere((i) => i.listing.id == listing.id);
    final currentQty = existingIndex != -1 ? _items[existingIndex].quantity : 0;
    final maxAllowed = listing.quantity; // Stock limit from database

    // Already at max → do nothing
    if (currentQty >= maxAllowed) return;

    // Cap requested quantity to available stock
    final newQty = currentQty + requestedQty;
    final finalQty = newQty > maxAllowed ? maxAllowed : newQty;

    if (existingIndex != -1) {
      _items[existingIndex].quantity = finalQty;
    } else {
      _items.add(CartItem(listing: listing, quantity: finalQty));
    }
    notifyListeners();
  }

  /// ✅ Safely increase quantity (respects listing.quantity limit)
  void increaseQuantity(String listingId) {
    final index = _items.indexWhere((i) => i.listing.id == listingId);
    if (index != -1) {
      final item = _items[index];
      // Only increase if below stock limit
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

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// ✅ Helper: Check how many of this listing are already in cart (SIMPLE VERSION)
  int getQuantityInCart(String listingId) {
    for (final item in _items) {
      if (item.listing.id == listingId) {
        return item.quantity;
      }
    }
    return 0; // Not found → 0 in cart
  }

  /// ✅ Helper: Check if item has reached stock limit (SIMPLE VERSION)
  bool isAtStockLimit(String listingId) {
    for (final item in _items) {
      if (item.listing.id == listingId) {
        return item.quantity >= item.listing.quantity;
      }
    }
    return false; // Not in cart → not at limit
  }

  /// Creates 1 order per cart item, groups them by pickup location
  Future<Map<String, List<OrderModel>>> checkout() async {
    final groupedOrders = <String, List<OrderModel>>{};
    
    for (final cartItem in _items) {
      final order = await _service.createOrder(
        listingId: cartItem.listing.id,
        quantity: cartItem.quantity,
      );
      groupedOrders.putIfAbsent(cartItem.listing.location, () => []).add(order);
    }
    
    clearCart();
    return groupedOrders;
  }
}