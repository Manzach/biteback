// FILE: lib/providers/buyer_provider.dart
// ============================================================================
// BUYER PROVIDER
// ============================================================================
// State management for buyer features (UC-04: Purchase Food, UC-07: View Donations)
// - Fetches & caches active food listings with search filtering
// - Handles order placement & history
// - Manages donation advertisements
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
  /// (category removed - not in FoodListing model)
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
               // ❌ REMOVED: listing.category (doesn't exist in FoodListing model)
               listing.location.toLowerCase().contains(query);
      }).toList();
    }
    
    return results;
  }

  // ==================================================================
  // 🍽️ FOOD LISTINGS METHODS
  // ==================================================================

  /// Load active, unsold, non-expired food listings from Supabase
  /// 
  /// Note: For search, use client-side filtering via `availableListings` getter
  /// Backend search via `searchQuery` parameter is optional for large datasets
  Future<void> loadListings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load ALL active listings (service handles is_deleted, is_sold, expiry filters)
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