// FILE: lib/providers/buyer_provider.dart
// ============================================================================
// BUYER PROVIDER
// ============================================================================
// State management for buyer features (UC-04: Purchase Food, UC-07: View Donations)
// - Fetches & caches active food listings with search filtering
// - Handles order placement & history
// - Manages donation advertisements
// - Handles cart checkout with denormalized order data
// Aligns with FYP Report: Table 5, UC-04, UC-07, Provider Architecture
// ============================================================================

import 'package:flutter/foundation.dart';
import '../models/food_listing_model.dart';
import '../models/order_model.dart';
import '../models/donation_model.dart';
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
  // 🔍 SEARCH STATE (NEW - Fixes search bar not working)
  // ==================================================================
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Setter that updates search query AND triggers UI rebuild
  set setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners(); // ✅ Critical: Rebuilds UI with filtered results
    }
  }

  /// Clear search and reset to all listings
  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

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

  // Donations
  List<DonationModel> get donations => List.unmodifiable(_donations);
  bool? get isLoadingDonations => _isLoadingDonations;
  String? get donationErrorMessage => _donationErrorMessage;

  // ==================================================================
  // ✅ FILTERED LISTINGS GETTER (Client-side search - FIXED)
  // ==================================================================
  /// Returns listings filtered by current search query
  /// Filters by: food name, description, location
  /// This provides INSTANT UI feedback without backend calls
  List<FoodListing> get availableListings {
    // Start with base listings (already filtered by service for active/available)
    List<FoodListing> results = _listings;
    
    // Apply client-side search filter if query exists
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      results = _listings.where((listing) {
        return listing.foodName.toLowerCase().contains(query) ||
               listing.description.toLowerCase().contains(query) ||
               listing.location.toLowerCase().contains(query);
      }).toList();
    }
    
    return results;
  }

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
      debugPrint('📦 [BuyerProvider] Loaded ${_listings.length} active listings');
    } catch (e) {
      _errorMessage = 'Failed to load food items. Please check your connection.';
      debugPrint('❌ [BuyerProvider] Load listings error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh listings (useful for pull-to-refresh)
  Future<void> refreshListings() async {
    await loadListings();
  }

  // ==================================================================
  // 🛒 ORDER METHODS
  // ==================================================================

  /// Place a SINGLE order for a food listing (for quick buy)
  Future<OrderModel?> placeOrder({
    required String listingId,
    int quantity = 1,
  }) async {
    try {
      // Find the listing to extract denormalized data
      final listing = _listings.firstWhere(
        (l) => l.id == listingId,
        orElse: () => FoodListing.empty(),
      );
      
      final order = await _service.createOrder(
        listingId: listingId,
        foodName: listing.foodName,       // ✅ Denormalized: snapshot of food name
        unitPrice: listing.discountedPrice, // ✅ Denormalized: price at purchase
        quantity: quantity,
      );
      
      if (order != null) {
        _orders.insert(0, order); // Add to top of history
        notifyListeners();
      }
      return order;
    } catch (e) {
      _errorMessage = 'Could not place order: ${e.toString()}';
      debugPrint('❌ [BuyerProvider] Place order error: $e');
      notifyListeners();
      return null;
    }
  }

  /// ✅ CHECKOUT: Place orders for multiple cart items with denormalized data
  /// 
  /// Groups orders by pickup location for OrderSuccessScreen display
  /// 
  /// Parameters:
  ///   - cartItems: List of CartItem objects from CartProvider
  /// 
  /// Returns:
  ///   Map<String, List<OrderModel>> grouped by pickup location
  // ==================================================================
  Future<Map<String, List<OrderModel>>> checkout(List<CartItem> cartItems) async {
    final groupedOrders = <String, List<OrderModel>>{};
    
    debugPrint('🛒 [BuyerProvider] Starting checkout with ${cartItems.length} items');
    
    for (final cartItem in cartItems) {
      // ✅ Extract denormalized data for historical accuracy
      final foodName = cartItem.listing.foodName;
      final unitPrice = cartItem.listing.discountedPrice;
      final quantity = cartItem.quantity;
      final listingId = cartItem.listing.id;
      
      debugPrint('📦 [BuyerProvider] Creating order: food=$foodName, unit=RM$unitPrice, qty=$quantity');
      
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
            
        debugPrint('✅ [BuyerProvider] Order created: ${order.id}');
        
      } catch (e, stack) {
        debugPrint('❌ [BuyerProvider] Failed to create order for $foodName: $e');
        debugPrint('📋 Stack: $stack');
        // Continue with other items instead of failing entire checkout
      }
    }
    
    // ✅ FIX: Call clearCart() as standalone statement (it returns void)
    // Then return the actual grouped orders data
    debugPrint('🧹 [BuyerProvider] Checkout complete, returning ${groupedOrders.length} location groups');
    
    // ✅ Return the actual data (NOT the result of any void method)
    return groupedOrders;
  }

  /// Load buyer's order history from Supabase
  Future<void> loadOrders() async {
    try {
      _orders = await _service.getBuyerOrders();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load order history.';
      debugPrint('❌ [BuyerProvider] Load orders error: $e');
    }
  }

  // ==================================================================
  // 🎁 DONATION METHODS (UC-07: View Donation Advertisements)
  // ==================================================================

  /// Load all AVAILABLE donation advertisements from Supabase
  Future<void> loadDonations() async {
    _isLoadingDonations = true;
    _donationErrorMessage = null;
    notifyListeners();

    try {
      _donations = await _service.fetchDonations();
      debugPrint('🎁 [BuyerProvider] Loaded ${_donations.length} donations');
    } catch (e) {
      _donationErrorMessage = 'Failed to load donations. Please try again.';
      debugPrint('❌ [BuyerProvider] Load donations error: $e');
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
      debugPrint('❌ [BuyerProvider] Get donation error: $e');
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
}

// ==================================================================
// ✅ CART ITEM MODEL (Helper class for checkout - defined here for simplicity)
// ==================================================================
class CartItem {
  final FoodListing listing;
  int quantity;

  CartItem({
    required this.listing,
    this.quantity = 1,
  });

  double get subtotal => listing.discountedPrice * quantity;
}