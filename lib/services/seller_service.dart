// FILE: lib/services/seller_service.dart
// ============================================================================
// SELLER SERVICE
// ============================================================================
// Handles Supabase database operations for seller features
// - Upload food listing photos to storage
// - Create, read, update, delete food listings
// - Toggle listing visibility (hide/show from buyers)
// - Mark listings as sold
// Aligns with FYP Report: Table 11 (Food Listing), UC-05
// ============================================================================

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // ✅ For debugPrint
import '../models/food_listing_model.dart';
import '../config/supabase_config.dart';

class SellerService {
  final _supabase = SupabaseConfig.client;

  // ==================================================================
  // UPLOAD LISTING PHOTO TO SUPABASE STORAGE
  // ==================================================================
  Future<String?> uploadListingPhoto(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final storagePath = 'listings/$userId/$fileName';

      await _supabase.storage
          .from('food-listings')
          .upload(storagePath, file, fileOptions: const FileOptions(cacheControl: '3600', upsert: false));

      final publicUrl = _supabase.storage
          .from('food-listings')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      debugPrint('❌ SellerService.uploadListingPhoto error: $e');
      return null;
    }
  }

  // ==================================================================
  // CREATE NEW FOOD LISTING
  // ==================================================================
  Future<FoodListing?> createListing({
    required String foodName,
    required String description,
    required double originalPrice,
    required double discountedPrice,
    required int quantity,
    required DateTime expiryDate,
    required String location,
    required String? photoUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final data = {
        'seller_id': userId,
        'food_name': foodName,
        'description': description,
        'original_price': originalPrice,
        'discounted_price': discountedPrice,
        'quantity': quantity,
        'expiry_date': expiryDate.toIso8601String(),
        'location': location,
        'photo_url': photoUrl,
        'created_at': DateTime.now().toIso8601String(),
        // ✅ Use availability_status per Table 11 (not is_deleted)
        'availability_status': 'Available',
        'is_sold': false,
        'is_hidden': false,
      };

      final response = await _supabase
          .from('food_listings')
          .insert(data)
          .select()
          .single();

      return FoodListing.fromJson(response);
    } catch (e) {
      debugPrint('❌ SellerService.createListing error: $e');
      return null;
    }
  }

  // ==================================================================
  // ✅ FETCH SELLER'S LISTINGS - EXCLUDES ADMIN-DELETED ITEMS ✅
  // ==================================================================
  Future<List<FoodListing>> getSellerListings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // ✅ Filter: Only this seller's listings + exclude admin-deleted ('Removed')
      final response = await _supabase
          .from('food_listings')
          .select()
          .eq('seller_id', userId)
          .neq('availability_status', 'Removed') // ✅ Exclude admin-soft-deleted listings
          .order('created_at', ascending: false);

      final listings = (response as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => FoodListing.fromJson(item))
          .toList();

      debugPrint('📦 [SellerService] Fetched ${listings.length} listings (excluding Removed)');
      return listings;
    } catch (e) {
      debugPrint('❌ SellerService.getSellerListings error: $e');
      return [];
    }
  }

  // ==================================================================
  // UPDATE EXISTING LISTING
  // ==================================================================
  Future<FoodListing?> updateListing({
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
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final Map<String, dynamic> updates = {
        'food_name': foodName,
        'description': description,
        'original_price': originalPrice,
        'discounted_price': discountedPrice,
        'quantity': quantity,
        'expiry_date': expiryDate.toIso8601String(),
        'location': location,
      };

      if (photoUrl != null && photoUrl.isNotEmpty) {
        updates['photo_url'] = photoUrl;
      }

      final response = await _supabase
          .from('food_listings')
          .update(updates)
          .eq('id', listingId)
          .eq('seller_id', userId)
          .select()
          .single();

      return FoodListing.fromJson(response);
    } catch (e) {
      debugPrint('❌ SellerService.updateListing error: $e');
      return null;
    }
  }

  // ==================================================================
  // ✅ SOFT DELETE LISTING - USES availability_status FIELD ✅
  // ==================================================================
  /// Marks a listing as removed instead of physically deleting it.
  /// This preserves foreign key integrity with the orders table,
  /// allowing buyers to still view their past orders.
  /// 
  /// Uses availability_status = 'Removed' per Table 11 (Food Listing)
  /// 
  /// Parameters:
  ///   - listingId: ID of the listing to soft-delete
  /// 
  /// Returns:
  ///   true if update successful, false on failure
  // ==================================================================
  Future<bool> deleteListing(String listingId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      debugPrint('🗑️ [SellerService] Soft-delete requested');
      debugPrint('🗑️ [SellerService] listingId: $listingId');
      debugPrint('🗑️ [SellerService] userId: $userId');
      
      if (userId == null) {
        debugPrint('❌ [SellerService] No authenticated user - aborting');
        return false;
      }

      // ✅ SOFT DELETE: Update availability_status to 'Removed' per Table 11
      // This aligns with admin moderation and buyer filtering logic
      debugPrint('🗑️ [SellerService] Executing soft-delete update...');
      
      await _supabase
          .from('food_listings')
          .update({'availability_status': 'Removed'})
          .eq('id', listingId)
          .eq('seller_id', userId);

      debugPrint('✅ [SellerService] Listing marked as Removed (availability_status=Removed)');
      return true;
      
    } catch (e, stack) {
      debugPrint('❌ [SellerService] deleteListing ERROR: $e');
      debugPrint('❌ [SellerService] Stack trace: $stack');
      return false;
    }
  }

  // ==================================================================
  // MARK LISTING AS SOLD
  // ==================================================================
  Future<bool> markAsSold(String listingId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('food_listings')
          .update({
            'availability_status': 'Sold', // ✅ Use status field per Table 11
            'is_sold': true,
          })
          .eq('id', listingId)
          .eq('seller_id', userId);

      return true;
    } catch (e) {
      debugPrint('❌ SellerService.markAsSold error: $e');
      return false;
    }
  }

  // ==================================================================
  // TOGGLE LISTING VISIBILITY
  // ==================================================================
  Future<bool> toggleListingVisibility(String listingId, bool isHidden) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('food_listings')
          .update({'is_hidden': isHidden})
          .eq('id', listingId)
          .eq('seller_id', userId);

      return true;
    } catch (e) {
      debugPrint('❌ SellerService.toggleListingVisibility error: $e');
      return false;
    }
  }
}