import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_listing_model.dart'; // ✅ Matches your actual filename
import '../models/order_model.dart';

class BuyerService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch active, unsold, non-expired food listings
  Future<List<FoodListing>> fetchActiveListings() async {
    final now = DateTime.now().toIso8601String();
    
    final response = await _client
        .from('food_listings')
        .select()
        .eq('is_sold', false)
        .gte('expiry_date', now)
        .order('created_at', ascending: false);

    // ✅ Use fromJson (not fromMap) - matches your FoodListing model
    return (response as List)
        .map((json) => FoodListing.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new order and generate QR code
  Future<OrderModel> createOrder({
    required String listingId,
    int quantity = 1,
  }) async {
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

    // ✅ Also use fromJson for OrderModel (if it exists)
    return OrderModel.fromJson(response);
  }

  /// Get order history for current buyer
  Future<List<OrderModel>> getBuyerOrders() async {
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
  }
}