// FILE: lib/providers/seller_provider.dart
// ============================================================================
// SELLER PROVIDER
// ============================================================================
// State management for seller features (UC-05: Manage Food Listing)
// - Fetches & caches seller's food listings
// - Toggles listing visibility (hide/show from buyers)
// - Handles loading, error, and refresh states
// - ✅ Ensures UI rebuilds after QR pickup verification
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
  // GETTERS (Read-only for UI)
  // ==================================================================
  List<FoodListing> get listings => List.unmodifiable(_listings);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================================================================
  // LOAD LISTINGS (With Guaranteed UI Rebuild)
  // ==================================================================
  Future<void> loadListings() async {
    debugPrint('📦 [SellerProvider] loadListings() called');
    
    _isLoading = true;
    _error = null;
    notifyListeners(); // ✅ Notify UI of loading state FIRST

    try {
      // Fetch fresh data from Supabase
      _listings = await _service.getSellerListings();
      debugPrint('📦 [SellerProvider] Loaded ${_listings.length} listings from DB');
      
      // ✅ Force UI rebuild with fresh data
      notifyListeners();
      
    } catch (e, stack) {
      _error = 'Failed to load listings: ${e.toString().replaceAll('Exception: ', '')}';
      debugPrint('❌ [SellerProvider] loadListings error: $e');
      debugPrint('❌ [SellerProvider] Stack: $stack');
      notifyListeners(); // ✅ Notify UI of error state
    } finally {
      _isLoading = false;
      debugPrint('📦 [SellerProvider] loadListings() completed, isLoading: $_isLoading');
      // ✅ Final notify to ensure UI reflects ready state
      notifyListeners();
    }
  }

  // ==================================================================
  // TOGGLE VISIBILITY (Hide/Show Listing)
  // ==================================================================
  Future<bool> toggleVisibility(String listingId, bool isHidden) async {
    debugPrint('👁️ [SellerProvider] toggleVisibility() called: $listingId -> $isHidden');
    
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.toggleListingVisibility(listingId, isHidden);
      debugPrint('👁️ [SellerProvider] Service returned: $success');
      
      if (success) {
        // ✅ Reload to ensure DB sync
        await loadListings();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to update visibility';
      debugPrint('❌ [SellerProvider] toggleVisibility error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // DELETE LISTING (Soft Delete + UI Refresh)
  // ==================================================================
  Future<bool> deleteListing(String listingId) async {
    debugPrint('🗑️ [SellerProvider] deleteListing() called: $listingId');
    debugPrint('🗑️ [SellerProvider] Current listings count: ${_listings.length}');
    
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🗑️ [SellerProvider] Calling _service.deleteListing()...');
      final success = await _service.deleteListing(listingId);
      
      debugPrint('🗑️ [SellerProvider] Service returned: $success');
      
      if (success) {
        // ✅ Remove from local state for instant UI feedback
        debugPrint('🗑️ [SellerProvider] Removing listing from local state...');
        final beforeCount = _listings.length;
        _listings.removeWhere((l) => l.id == listingId);
        final afterCount = _listings.length;
        debugPrint('🗑️ [SellerProvider] Local state: $beforeCount → $afterCount listings');
        
        // ✅ CRITICAL: Reload from DB to ensure complete sync
        await loadListings();
        debugPrint('🗑️ [SellerProvider] Listings reloaded after delete');
        return true;
      } else {
        debugPrint('⚠️ [SellerProvider] Delete failed at service layer');
        return false;
      }
    } catch (e, stack) {
      _error = 'Failed to delete listing: ${e.toString().replaceAll('Exception: ', '')}';
      debugPrint('❌ [SellerProvider] deleteListing ERROR: $e');
      debugPrint('❌ [SellerProvider] Stack: $stack');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); // ✅ Ensure UI reflects final state
      debugPrint('🗑️ [SellerProvider] deleteListing() completed');
    }
  }

  // ==================================================================
  // UPDATE LISTING (With Local State Sync)
  // ==================================================================
  Future<bool> updateListing({
    required String listingId,
    required String foodName,
    required String description,
    required double originalPrice,
    required double discountedPrice,
    required int quantity,
    required DateTime expiryDate,
    required String location,
    String? photoUrl,
  }) async {
    debugPrint('✏️ [SellerProvider] updateListing() called: $listingId');
    
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _service.updateListing(
        listingId: listingId,
        foodName: foodName,
        description: description,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        quantity: quantity,
        expiryDate: expiryDate,
        location: location,
        photoUrl: photoUrl,
      );
      
      debugPrint('✏️ [SellerProvider] Service returned: ${updated != null}');
      
      if (updated != null) {
        // ✅ Update local state for instant UI feedback
        final index = _listings.indexWhere((l) => l.id == listingId);
        if (index != -1) {
          debugPrint('✏️ [SellerProvider] Updating local listing at index $index');
          _listings[index] = updated;
          notifyListeners(); // ✅ Immediate UI update
        }
        return true;
      }
      return false;
    } catch (e, stack) {
      _error = 'Failed to update listing: ${e.toString().replaceAll('Exception: ', '')}';
      debugPrint('❌ [SellerProvider] updateListing error: $e');
      debugPrint('❌ [SellerProvider] Stack: $stack');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners(); // ✅ Ensure UI reflects final state
    }
  }

  // ==================================================================
  // REFRESH LISTINGS (Explicit Refresh for QR Flow)
  // ==================================================================
  /// Explicitly refresh listings after external changes (e.g., QR pickup)
  /// This ensures the UI shows the latest data from Supabase
  Future<void> refreshAfterExternalChange() async {
    debugPrint('🔄 [SellerProvider] refreshAfterExternalChange() called');
    await loadListings();
  }

  // ==================================================================
  // UTILITY
  // ==================================================================
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Get listing by ID (for debugging/testing)
  FoodListing? getListingById(String id) {
    return _listings.firstWhere((l) => l.id == id, orElse: () => null as FoodListing);
  }
}