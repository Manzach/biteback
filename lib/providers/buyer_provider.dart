import 'package:flutter/foundation.dart';
import '../models/food_listing_model.dart';
import '../models/order_model.dart';
import '../services/buyer_service.dart';

class BuyerProvider with ChangeNotifier {
  final BuyerService _service = BuyerService();

  List<FoodListing> _listings = [];
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters (read-only for UI)
  List<FoodListing> get listings => _listings;
  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load active food listings from Supabase
  Future<void> loadListings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _listings = await _service.fetchActiveListings();
    } catch (e) {
      _errorMessage = 'Failed to load food items. Please check your connection.';
      debugPrint('Load listings error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Place an order for a food listing
  Future<OrderModel?> placeOrder({
    required String listingId,
    int quantity = 1,
  }) async {
    try {
      final order = await _service.createOrder(
        listingId: listingId,
        quantity: quantity,
      );
      _orders.insert(0, order); // Add to top of history
      notifyListeners();
      return order;
    } catch (e) {
      _errorMessage = 'Could not place order: ${e.toString()}';
      debugPrint('Place order error: $e');
      notifyListeners();
      return null;
    }
  }

  /// Load buyer's order history
  Future<void> loadOrders() async {
    try {
      _orders = await _service.getBuyerOrders();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load order history.';
      debugPrint('Load orders error: $e');
    }
  }

  /// Clear error message (call after showing snackbar)
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}