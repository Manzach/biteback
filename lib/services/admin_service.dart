// FILE: lib/services/admin_service.dart
// ============================================================================
// ADMIN SERVICE
// ============================================================================
// Handles Supabase operations for admin monitoring & moderation (UC-08)
// - Fetches dashboard statistics
// - Retrieves users, listings, donations, and reports
// - Provides moderation actions (toggle status, flag, resolve, delete)
// Aligns with FYP Report: Table 10-14, UC-08, Section 4.3.1
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/food_listing_model.dart';
import '../models/donation_model.dart';

class AdminService {
  final SupabaseClient _client;

  AdminService(this._client);

  // ==================================================================
  // DASHBOARD STATISTICS
  // ==================================================================
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final users = await _client.from('profiles').select('id');
      final listings = await _client.from('food_listings').select('id');
      final donations = await _client.from('donations').select('id');
      final orders = await _client.from('orders').select('id');
      final pendingReports = await _client.from('reports').select('id').eq('status', 'Pending');

      return {
        'users': users.length,
        'listings': listings.length,
        'donations': donations.length,
        'orders': orders.length,
        'pendingReports': pendingReports.length,
      };
    } catch (e) {
      debugPrint('❌ AdminService.getDashboardStats error: $e');
      return {'users': 0, 'listings': 0, 'donations': 0, 'orders': 0, 'pendingReports': 0};
    }
  }

  // ==================================================================
  // USER MANAGEMENT - FIXED TO FETCH ALL USERS
  // ==================================================================
  Future<List<UserModel>> getAllUsers() async {
    try {
      debugPrint('🔍 [AdminService] Fetching all users from profiles table...');
      
      // ✅ FIX: Select ALL columns from profiles table without filtering
      // This ensures admin can see ALL users, not just their own profile
      final response = await _client
          .from('profiles')
          .select('*')  // ✅ Select all columns
          .order('created_at', ascending: false);

      debugPrint('📦 [AdminService] Profiles query returned ${response.length} users');
      
      if (response.isEmpty) {
        debugPrint('⚠️ [AdminService] No users found - check RLS policies or table name');
        return [];
      }

      return (response as List)
          .map((json) {
            try {
              return UserModel.fromMap(json as Map<String, dynamic>);
            } catch (e) {
              debugPrint('❌ [AdminService] Error parsing user: $e');
              return null;
            }
          })
          .whereType<UserModel>()  // Filter out nulls from failed parsing
          .toList();
          
    } on PostgrestException catch (e) {
      debugPrint('💥 [AdminService] PostgrestException in getAllUsers: ${e.message}');
      debugPrint('   - Code: ${e.code}');
      debugPrint('   - Details: ${e.details}');
      debugPrint('   - Hint: ${e.hint}');
      return [];
    } catch (e, stack) {
      debugPrint('❌ [AdminService] getAllUsers error: $e');
      debugPrint('📋 Stack trace: $stack');
      return [];
    }
  }

  Future<bool> updateUserStatus(String userId, String status) async {
    try {
      debugPrint('🔄 [AdminService] Updating user $userId status to: $status');
      
      final response = await _client
          .from('profiles')
          .update({'account_status': status})
          .eq('id', userId)
          .select();
      
      debugPrint('📦 [AdminService] Update response: $response');
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ AdminService.updateUserStatus error: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      // Soft delete: update status instead of hard delete
      final response = await _client
          .from('profiles')
          .update({'account_status': 'deleted'})
          .eq('id', userId)
          .select();
      
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ AdminService.deleteUser error: $e');
      return false;
    }
  }

  // ==================================================================
  // ITEM (LISTING) MODERATION - WITH DEBUG LOGGING
  // ==================================================================
  Future<List<FoodListing>> getAllListings() async {
    try {
      final response = await _client
          .from('food_listings')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FoodListing.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ AdminService.getAllListings error: $e');
      return [];
    }
  }

  Future<bool> flagListing(String listingId) async {
    try {
      debugPrint('🚩 [AdminService] Attempting to flag listing: $listingId');
      
      final response = await _client
          .from('food_listings')
          .update({'moderation_status': 'Flagged'})
          .eq('id', listingId)
          .select();
      
      debugPrint('📦 [AdminService] Flag response: $response');
      
      if (response.isNotEmpty) {
        final newStatus = response[0]['moderation_status'];
        debugPrint('✅ [AdminService] Successfully flagged. New status: $newStatus');
        return true;
      } else {
        debugPrint('⚠️ [AdminService] No rows updated - listing may not exist or RLS blocked');
        return false;
      }
    } catch (e, stack) {
      debugPrint('❌ [AdminService] flagListing error: $e');
      debugPrint('📋 Stack trace: $stack');
      return false;
    }
  }

  Future<bool> approveListing(String listingId) async {
    try {
      debugPrint('✅ [AdminService] Attempting to approve listing: $listingId');
      
      final response = await _client
          .from('food_listings')
          .update({'moderation_status': 'Active'})
          .eq('id', listingId)
          .select();
      
      debugPrint('📦 [AdminService] Approve response: $response');
      
      if (response.isNotEmpty) {
        final newStatus = response[0]['moderation_status'];
        debugPrint('✅ [AdminService] Successfully approved. New status: $newStatus');
        return true;
      }
      return false;
    } catch (e, stack) {
      debugPrint('❌ [AdminService] approveListing error: $e');
      debugPrint('📋 Stack trace: $stack');
      return false;
    }
  }

  Future<bool> removeListing(String listingId) async {
    try {
      debugPrint('🗑️ [AdminService] Attempting to remove listing: $listingId');
      
      final response = await _client
          .from('food_listings')
          .update({'moderation_status': 'Removed'})
          .eq('id', listingId)
          .select();
      
      debugPrint('📦 [AdminService] Remove response: $response');
      
      if (response.isNotEmpty) {
        final newStatus = response[0]['moderation_status'];
        debugPrint('✅ [AdminService] Successfully removed. New status: $newStatus');
        return true;
      }
      return false;
    } catch (e, stack) {
      debugPrint('❌ [AdminService] removeListing error: $e');
      debugPrint('📋 Stack trace: $stack');
      return false;
    }
  }

  // ==================================================================
  // DONATION (ADS) MODERATION - WITH DEBUG LOGGING ✅ FIXED
  // ==================================================================
  Future<List<DonationModel>> getAllDonations() async {
    try {
      final response = await _client
          .from('donations')
          .select()
          .order('date_posted', ascending: false);

      return (response as List)
          .map((json) => DonationModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ AdminService.getAllDonations error: $e');
      return [];
    }
  }

  Future<bool> removeDonation(String donationId) async {
    try {
      debugPrint('🗑️ [AdminService] Attempting to remove donation ID: $donationId');
      
      final response = await _client
          .from('donations')
          .update({'availability_status': 'Removed'})
          .eq('donation_id', donationId)
          .select(); 
      
      debugPrint('📦 [AdminService] Database response: $response');
      
      if (response.isNotEmpty) {
        final newStatus = response[0]['availability_status'];
        debugPrint('✅ [AdminService] Donation removed successfully. New status: $newStatus');
        return true;
      } else {
        debugPrint('⚠️ [AdminService] No rows updated. Check ID or Permissions (RLS).');
        return false;
      }
    } catch (e, stack) {
      debugPrint('❌ [AdminService] removeDonation Error: $e');
      debugPrint('📋 Stack Trace: $stack');
      return false;
    }
  }

  // ==================================================================
  // ISSUE/REPORT MANAGEMENT
  // ==================================================================
  Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      final response = await _client
          .from('reports')
          .select()
          .order('created_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint('❌ AdminService.getAllReports error: $e');
      return [];
    }
  }

  Future<bool> resolveReport(String reportId) async {
    try {
      final adminId = _client.auth.currentUser?.id;
      final response = await _client
          .from('reports')
          .update({
            'status': 'Resolved',
            'resolved_at': DateTime.now().toIso8601String(),
            'resolved_by': adminId,
          })
          .eq('id', reportId)
          .select();
      
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ AdminService.resolveReport error: $e');
      return false;
    }
  }

  Future<bool> deleteReport(String reportId) async {
    try {
      final response = await _client
          .from('reports')
          .delete()
          .eq('id', reportId)
          .select();
      
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ AdminService.deleteReport error: $e');
      return false;
    }
  }
}