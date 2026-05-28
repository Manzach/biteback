// FILE: lib/providers/seller_provider.dart
// ============================================================================
// SELLER PROVIDER
// ============================================================================
// State management for seller features (UC-05: Manage Food Listing)
// - Fetches & caches seller's food listings
// - Toggles listing visibility (hide/show from buyers)
// - Handles loading, error, and refresh states
// Aligns with FYP Report: Table 11, UC-05, Provider Architecture
// ============================================================================

import 'package:flutter/foundation.dart';
import '../services/seller_service.dart';
import '../models/food_listing_model.dart';

class SellerProvider with ChangeNotifier {
  final SellerService _service;
  
  List<FoodListing> _listings = [];
  bool _isLoading = false;
  String? _error;

  SellerProvider(this._service);

  // ==================================================================
  // GETTERS
  // ==================================================================
  List<FoodListing> get listings => List.unmodifiable(_listings);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================================================================
  // LOAD LISTINGS
  // ==================================================================
  Future<void> loadListings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _listings = await _service.getSellerListings();
    } catch (e) {
      _error = 'Failed to load listings: ${e.toString().replaceAll('Exception: ', '')}';
      debugPrint('❌ SellerProvider.loadListings error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // TOGGLE VISIBILITY (Hide/Show Listing)
  // ==================================================================
  Future<bool> toggleVisibility(String listingId, bool isHidden) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.toggleListingVisibility(listingId, isHidden);
      if (success) await loadListings(); // Refresh to guarantee DB sync
      return success;
    } catch (e) {
      _error = 'Failed to update visibility';
      debugPrint('❌ SellerProvider.toggleVisibility error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // DELETE LISTING
  // ==================================================================
  Future<bool> deleteListing(String listingId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.deleteListing(listingId);
      if (success) await loadListings();
      return success;
    } catch (e) {
      _error = 'Failed to delete listing';
      debugPrint('❌ SellerProvider.deleteListing error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // UTILITY
  // ==================================================================
  void clearError() {
    _error = null;
    notifyListeners();
  }
}