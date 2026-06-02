// FILE: lib/services/buyer_service.dart
// ============================================================================
// BUYER SERVICE
// ============================================================================
// Handles Supabase database operations for buyer features
// - Fetch active food listings (UC-04) ✅ with optional backend search
// - Create & retrieve orders with QR codes (UC-04)
// - Fetch donation advertisements (UC-07)
// Aligns with FYP Report: Table 11 (Food Listing), UC-04, UC-07
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // ✅ ADD THIS for debugPrint
import '../models/food_listing_model.dart';
import '../models/order_model.dart';
import '../models/donation_model.dart';

class BuyerService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==================================================================
  // 🍽️ FOOD LISTINGS (UC-04: Purchase Near-Expiry Food)
  // ==================================================================

  /// Fetch active, AVAILABLE, unsold, non-expired, VISIBLE food listings from sellers
  /// 
  /// Filters applied (per Table 11 - Food Listing):
  /// - availability_status = 'Available' ✅ (only purchasable items)
  /// - is_sold = false (not yet purchased)
  /// - is_hidden = false (seller hasn't hidden it)
  /// - expiry_date >= now (still valid)
  /// - Optional: searchQuery filters by food_name, description, or category (case-insensitive)
  /// 
  /// Parameters:
  ///   - searchQuery: Optional search term to filter listings by name, description, or category
  /// 
  /// Returns listings ordered by creation date (newest first)
  // ==================================================================
  Future<List<FoodListing>> fetchActiveListings({String? searchQuery}) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      // Start with base query - ALWAYS filter by availability_status = 'Available' per Table 11
      var query = _client
          .from('food_listings')
          .select()
          .eq('availability_status', 'Available') // ✅ CRITICAL: Only show Available items to buyers
          .eq('is_sold', false)                   // Safety: exclude already sold
          .eq('is_hidden', false)                 // Safety: exclude seller-hidden items
          .gte('expiry_date', now);               // Safety: exclude expired items

      // 🔍 Apply backend search filter if query provided
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        // Case-insensitive partial match on food_name, description, or category
        query = query.or('food_name.ilike.%$q%,description.ilike.%$q%,category.ilike.%$q%');
      }

      final response = await query.order('created_at', ascending: false);

      debugPrint('📦 [BuyerService] Fetched ${response.length} available listings for buyer');
      return (response as List)
          .map((json) => FoodListing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [BuyerService] fetchActiveListings error: $e');
      throw Exception('Failed to load food listings: $e');
    }
  }

  // ==================================================================
  // 🛒 ORDERS (UC-04: Purchase Flow + QR Generation) - DENORMALIZED ✅
  // ==================================================================

  /// Create a new order and generate unique QR code for pickup verification
  /// 
  /// BEST PRACTICE: Stores food_name and total_price at time of purchase
  /// (denormalization) so historical orders show correct data even if
  /// the original listing is modified or deleted later.
  /// 
  /// Parameters:
  ///   - listingId: The food listing being purchased
  ///   - foodName: Name of the food item (snapshot at purchase time)
  ///   - unitPrice: Price per unit at purchase time (snapshot)
  ///   - quantity: Number of items to order (default: 1)
  /// 
  /// Returns:
  ///   OrderModel with generated QR code payload
  // ==================================================================
  Future<OrderModel> createOrder({
    required String listingId,
    required String foodName,      // ✅ NEW: Pass food name for historical record
    required double unitPrice,     // ✅ NEW: Pass unit price for historical record
    int quantity = 1,
  }) async {
    try {
      final buyerId = _client.auth.currentUser?.id;
      if (buyerId == null) throw Exception('User not authenticated');

      // Generate unique QR payload: BB-{timestamp}-{buyerId}
      final qrPayload = 'BB-${DateTime.now().millisecondsSinceEpoch}-$buyerId';
      
      // ✅ Calculate total price at purchase time
      final totalPrice = unitPrice * quantity;

      debugPrint('🛒 [BuyerService] Creating order: listing=$listingId, food=$foodName, unit=RM$unitPrice, qty=$quantity, total=RM$totalPrice');

      final response = await _client
          .from('orders')
          .insert({
            'buyer_id': buyerId,
            'listing_id': listingId,
            'quantity': quantity,
            'status': 'pending',
            'qr_code': qrPayload,
            // ✅ DENORMALIZE: Store snapshot at purchase time for historical accuracy
            'food_name': foodName,           // ✅ Snapshot of food name
            'unit_price': unitPrice,         // ✅ Price per unit at purchase
            'total_price': totalPrice,       // ✅ Calculated total paid
            'created_at': DateTime.now().toIso8601String(), // ✅ FIXED: Changed from 'order_date' to 'created_at' to match DB schema
          })
          .select()
          .single();

      debugPrint('✅ [BuyerService] Order created successfully with ID: ${response['id']}');
      return OrderModel.fromJson(response);
      
    } on PostgrestException catch (e) {
      debugPrint('❌ [BuyerService] createOrder PostgrestException:');
      debugPrint('   - Message: ${e.message}');
      debugPrint('   - Code: ${e.code}');
      debugPrint('   - Details: ${e.details}');
      
      if (e.code == '23503') {
        debugPrint('💡 FIX: Foreign key violation - verify listing_id exists in food_listings table');
      } else if (e.code == '23505') {
        debugPrint('💡 FIX: Unique constraint violation - check orders table primary key');
      } else if (e.code == '23514') {
        debugPrint('💡 FIX: CHECK constraint violation - verify orders table has food_name/total_price columns');
      }
      throw Exception('Failed to create order: ${e.message}');
    } catch (e) {
      debugPrint('❌ [BuyerService] createOrder error: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get order history for current buyer (for order tracking)
  /// Returns all orders regardless of status (pending/collected/cancelled)
  /// 
  /// Note: Orders include denormalized food_name and total_price fields
  /// stored at purchase time for accurate historical display.
  // ==================================================================
  Future<List<OrderModel>> getBuyerOrders() async {
    try {
      final buyerId = _client.auth.currentUser?.id;
      if (buyerId == null) throw Exception('User not authenticated');

      debugPrint('🔍 [BuyerService] Fetching order history for buyer: $buyerId');

      final response = await _client
          .from('orders')
          .select()
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false);

      debugPrint('📦 [BuyerService] Fetched ${response.length} orders for buyer');
      
      return (response as List)
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [BuyerService] getBuyerOrders error: $e');
      throw Exception('Failed to load order history: $e');
    }
  }

  // ==================================================================
  // 🎁 DONATIONS (UC-07: View Donation Advertisements)
  // ==================================================================

  /// Fetch all AVAILABLE donation advertisements posted by donors
  /// Returns only donations with status 'Available' for buyers to view
  /// (per Table 13: Donation - availability_status: 'Available', 'Claimed', 'Removed')
  // ==================================================================
  Future<List<DonationModel>> fetchDonations() async {
    try {
      final response = await _client
          .from('donations')
          .select()
          .eq('availability_status', 'Available') // ✅ Only show Available donations to buyers
          .order('date_posted', ascending: false); // Newest first

      debugPrint('🎁 [BuyerService] Fetched ${response.length} available donations for buyer');
      return (response as List)
          .map((json) => DonationModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [BuyerService] fetchDonations error: $e');
      throw Exception('Failed to load donations: $e');
    }
  }

  /// Fetch a single donation by ID (for detail screen)
  /// Returns null if donation doesn't exist or was collected/deleted
  // ==================================================================
  Future<DonationModel?> getDonationById(String donationId) async {
    try {
      final response = await _client
          .from('donations')
          .select()
          .eq('donation_id', donationId)
          .single();

      return DonationModel.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      // Return null if not found (donation may have been collected/deleted)
      debugPrint('⚠️ [BuyerService] Donation $donationId not found or inaccessible');
      return null;
    }
  }

  /// Fetch donations by pickup location (for location-based filtering)
  /// Uses case-insensitive partial match for flexible location search
  // ==================================================================
  Future<List<DonationModel>> fetchDonationsByLocation(String location) async {
    try {
      final response = await _client
          .from('donations')
          .select()
          .eq('availability_status', 'Available') // ✅ Only Available donations
          .ilike('pickup_location', '%$location%') // Case-insensitive partial match
          .order('date_posted', ascending: false);

      return (response as List)
          .map((json) => DonationModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [BuyerService] fetchDonationsByLocation error: $e');
      throw Exception('Failed to load donations by location: $e');
    }
  }
}