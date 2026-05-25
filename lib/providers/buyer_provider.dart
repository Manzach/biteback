import 'package:flutter/foundation.dart';
import '../models/food_listing_model.dart';
import '../models/order_model.dart';
import '../models/donation_model.dart'; // ✅ ADD THIS for donation support
import '../services/buyer_service.dart';

class BuyerProvider with ChangeNotifier {
  final BuyerService _service = BuyerService();

  // ==================================================================
  // 🍽️ FOOD LISTINGS STATE (UC-04: Purchase Near-Expiry Food)
  // ==================================================================
  List<FoodListing> _listings = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ==================================================================
  // 🛒 ORDERS STATE (UC-04: Order History)
  // ==================================================================
  List<OrderModel> _orders = [];

  // ==================================================================
  // 🎁 DONATIONS STATE (UC-07: View Donation Advertisements)
  // ==================================================================
  List<DonationModel> _donations = [];
  bool? _isLoadingDonations;
  String? _donationErrorMessage;

  // ==================================================================
  // GETTERS (Read-only for UI)
  // ==================================================================
  
  // Food Listings
  List<FoodListing> get listings => List.unmodifiable(_listings);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Orders
  List<OrderModel> get orders => List.unmodifiable(_orders);

  // ✅ Donations
  List<DonationModel> get donations => List.unmodifiable(_donations);
  bool? get isLoadingDonations => _isLoadingDonations;
  String? get donationErrorMessage => _donationErrorMessage;

  // ==================================================================
  // 🍽️ FOOD LISTINGS METHODS
  // ==================================================================

  /// Load active, unsold, non-expired food listings from Supabase
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

  // ==================================================================
  // 🛒 ORDER METHODS
  // ==================================================================

  /// Place an order for a food listing and generate QR code
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

  /// Load buyer's order history from Supabase
  Future<void> loadOrders() async {
    try {
      _orders = await _service.getBuyerOrders();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load order history.';
      debugPrint('Load orders error: $e');
    }
  }

  // ==================================================================
  // 🎁 DONATION METHODS (UC-07: View Donation Advertisements)
  // ==================================================================

  /// Load all AVAILABLE donation advertisements from Supabase
  /// Only shows donations with status 'Available' for buyers to view
  Future<void> loadDonations() async {
    _isLoadingDonations = true;
    _donationErrorMessage = null;
    notifyListeners();

    try {
      _donations = await _service.fetchDonations();
    } catch (e) {
      _donationErrorMessage = 'Failed to load donations. Please try again.';
      debugPrint('Load donations error: $e');
    } finally {
      _isLoadingDonations = false;
      notifyListeners();
    }
  }

  /// Refresh donations (useful for pull-to-refresh)
  Future<void> refreshDonations() async {
    await loadDonations();
  }

  /// Fetch a single donation by ID (for detail screen)
  Future<DonationModel?> getDonationById(String donationId) async {
    try {
      return await _service.getDonationById(donationId);
    } catch (e) {
      debugPrint('Get donation error: $e');
      return null;
    }
  }

  // ==================================================================
  // UTILITY METHODS
  // ==================================================================

  /// Clear error message (call after showing snackbar)
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear donation error message
  void clearDonationError() {
    _donationErrorMessage = null;
    notifyListeners();
  }

  /// Filter listings by search query (optional enhancement)
  List<FoodListing> searchListings(String query) {
    if (query.isEmpty) return _listings;
    final lowerQuery = query.toLowerCase();
    return _listings.where((item) =>
      item.foodName.toLowerCase().contains(lowerQuery) ||
      item.location.toLowerCase().contains(lowerQuery) ||
      item.description.toLowerCase().contains(lowerQuery),
    ).toList();
  }
}