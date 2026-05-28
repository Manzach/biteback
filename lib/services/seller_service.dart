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
  /// Uploads a food listing photo to Supabase Storage
  /// 
  /// Parameters:
  ///   - filePath: Local path to the image file
  ///   - fileName: Desired filename (e.g., 'sandwich_123.jpg')
  /// 
  /// Returns:
  ///   Public URL of the uploaded image, or null if upload fails
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
  /// Creates a new food listing in the database
  /// 
  /// Parameters:
  ///   - All required listing fields + optional photoUrl
  /// 
  /// Returns:
  ///   FoodListing object if successful, null on failure
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
        'is_sold': false,
        'is_hidden': false, // ✅ Default: visible to buyers
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
  // FETCH SELLER'S LISTINGS
  // ==================================================================
  /// Retrieves all food listings created by the current seller
  /// Returns listings ordered by creation date (newest first)
  // ==================================================================
  Future<List<FoodListing>> getSellerListings() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('food_listings')
          .select()
          .eq('seller_id', userId)
          .order('created_at', ascending: false);

      final listings = (response as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => FoodListing.fromJson(item))
          .toList();

      return listings;
    } catch (e) {
      debugPrint('❌ SellerService.getSellerListings error: $e');
      return [];
    }
  }

  // ==================================================================
  // UPDATE EXISTING LISTING
  // ==================================================================
  /// Updates an existing food listing (seller can only update their own)
  /// 
  /// Parameters:
  ///   - listingId: ID of the listing to update
  ///   - All fields to update (excluding seller_id for security)
  /// 
  /// Returns:
  ///   Updated FoodListing object if successful, null on failure
  // ==================================================================
  Future<FoodListing?> updateListing({
    required String listingId,
    required String foodName,
    required String description,
    required double discountedPrice,
    required int quantity,
    required DateTime expiryDate,
    required String location,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('food_listings')
          .update({
            'food_name': foodName,
            'description': description,
            'discounted_price': discountedPrice,
            'quantity': quantity,
            'expiry_date': expiryDate.toIso8601String(),
            'location': location,
          })
          .eq('id', listingId)
          .eq('seller_id', userId) // ✅ Security: only update own listings
          .select()
          .single();

      return FoodListing.fromJson(response);
    } catch (e) {
      debugPrint('❌ SellerService.updateListing error: $e');
      return null;
    }
  }

  // ==================================================================
  // DELETE LISTING
  // ==================================================================
  /// Permanently deletes a food listing (seller can only delete their own)
  /// 
  /// Parameters:
  ///   - listingId: ID of the listing to delete
  /// 
  /// Returns:
  ///   true if deletion successful, false on failure
  // ==================================================================
  Future<bool> deleteListing(String listingId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('food_listings')
          .delete()
          .eq('id', listingId)
          .eq('seller_id', userId); // ✅ Security: only delete own listings

      return true;
    } catch (e) {
      debugPrint('❌ SellerService.deleteListing error: $e');
      return false;
    }
  }

  // ==================================================================
  // MARK LISTING AS SOLD
  // ==================================================================
  /// Marks a listing as sold (removes from active listings)
  /// 
  /// Parameters:
  ///   - listingId: ID of the listing to mark as sold
  /// 
  /// Returns:
  ///   true if update successful, false on failure
  // ==================================================================
  Future<bool> markAsSold(String listingId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('food_listings')
          .update({'is_sold': true})
          .eq('id', listingId)
          .eq('seller_id', userId);

      return true;
    } catch (e) {
      debugPrint('❌ SellerService.markAsSold error: $e');
      return false;
    }
  }

  // ==================================================================
  // ✅ NEW: TOGGLE LISTING VISIBILITY (Hide/Show from Buyers)
  // ==================================================================
  /// Toggles the visibility of a listing without deleting it
  /// Hidden listings are excluded from buyer queries but remain in seller view
  /// 
  /// Parameters:
  ///   - listingId: ID of the listing to toggle
  ///   - isHidden: true to hide, false to show
  /// 
  /// Returns:
  ///   true if update successful, false on failure
  // ==================================================================
  Future<bool> toggleListingVisibility(String listingId, bool isHidden) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('food_listings')
          .update({'is_hidden': isHidden})
          .eq('id', listingId)
          .eq('seller_id', userId); // ✅ Security: only toggle own listings

      return true;
    } catch (e) {
      debugPrint('❌ SellerService.toggleListingVisibility error: $e');
      return false;
    }
  }
}