import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_listing_model.dart';
import '../config/supabase_config.dart';

class SellerService {
  final _supabase = SupabaseConfig.client;

  Future<String?> uploadListingPhoto(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final userId = _supabase.auth.currentUser!.id;
      final storagePath = 'listings/$userId/$fileName';

      await _supabase.storage
          .from('food-listings')
          .upload(storagePath, file);

      final publicUrl = _supabase.storage
          .from('food-listings')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

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
      final userId = _supabase.auth.currentUser!.id;

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
      };

      final response = await _supabase
          .from('food_listings')
          .insert(data)
          .select()
          .single();

      return FoodListing.fromJson(response);
    } catch (e) {
      print('Error creating listing: $e');
      return null;
    }
  }

  Future<List<FoodListing>> getSellerListings() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('food_listings')
          .select()
          .eq('seller_id', userId)
          .order('created_at', ascending: false);

      final listings = (response as List)
          .map((item) => FoodListing.fromJson(item as Map<String, dynamic>))
          .toList();

      return listings;
    } catch (e) {
      print('Error fetching listings: $e');
      return [];
    }
  }

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
      final userId = _supabase.auth.currentUser!.id;

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
          .eq('seller_id', userId)
          .select()
          .single();

      return FoodListing.fromJson(response);
    } catch (e) {
      print('Error updating listing: $e');
      return null;
    }
  }

  Future<bool> deleteListing(String listingId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from('food_listings')
          .delete()
          .eq('id', listingId)
          .eq('seller_id', userId);

      return true;
    } catch (e) {
      print('Error deleting listing: $e');
      return false;
    }
  }

  Future<bool> markAsSold(String listingId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from('food_listings')
          .update({'is_sold': true})
          .eq('id', listingId)
          .eq('seller_id', userId);

      return true;
    } catch (e) {
      print('Error marking as sold: $e');
      return false;
    }
  }
}