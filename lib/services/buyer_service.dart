import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_listing_model.dart';
import '../models/order_model.dart';
import '../models/donation_model.dart'; // ✅ ADD THIS for donation support

class BuyerService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==================================================================
  // 🍽️ FOOD LISTINGS (UC-04: Purchase Near-Expiry Food)
  // ==================================================================

  /// Fetch active, unsold, non-expired food listings from sellers
  Future<List<FoodListing>> fetchActiveListings() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      final response = await _client
          .from('food_listings')
          .select()
          .eq('is_sold', false)
          .gte('expiry_date', now)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FoodListing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load food listings: $e');
    }
  }

  // ==================================================================
  // 🛒 ORDERS (UC-04: Purchase Flow + QR Generation)
  // ==================================================================

  /// Create a new order and generate unique QR code for pickup verification
  Future<OrderModel> createOrder({
    required String listingId,
    int quantity = 1,
  }) async {
    try {
      final buyerId = _client.auth.currentUser?.id;
      if (buyerId == null) throw Exception('User not authenticated');

      // Generate unique QR payload: BB-{timestamp}-{buyerId}
      final qrPayload = 'BB-${DateTime.now().millisecondsSinceEpoch}-$buyerId';

      final response = await _client
          .from('orders')
          .insert({
            'buyer_id': buyerId,
            'listing_id': listingId,
            'quantity': quantity,
            'status': 'pending',
            'qr_code': qrPayload,
          })
          .select()
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get order history for current buyer (for order tracking)
  Future<List<OrderModel>> getBuyerOrders() async {
    try {
      final buyerId = _client.auth.currentUser?.id;
      if (buyerId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('orders')
          .select()
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load order history: $e');
    }
  }

  // ==================================================================
  // 🎁 DONATIONS (UC-07: View Donation Advertisements)
  // ==================================================================

  /// Fetch all AVAILABLE donation advertisements posted by donors
  /// Returns only donations with status 'Available' for buyers to view
  Future<List<DonationModel>> fetchDonations() async {
    try {
      final response = await _client
          .from('donations')
          .select()
          .eq('availability_status', 'Available') // Only show available donations
          .order('date_posted', ascending: false); // Newest first

      return (response as List)
          .map((json) => DonationModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load donations: $e');
    }
  }

  /// Fetch a single donation by ID (for detail screen)
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
      return null;
    }
  }

  /// Fetch donations by pickup location (for location-based filtering)
  Future<List<DonationModel>> fetchDonationsByLocation(String location) async {
    try {
      final response = await _client
          .from('donations')
          .select()
          .eq('availability_status', 'Available')
          .ilike('pickup_location', '%$location%') // Case-insensitive partial match
          .order('date_posted', ascending: false);

      return (response as List)
          .map((json) => DonationModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load donations by location: $e');
    }
  }
}