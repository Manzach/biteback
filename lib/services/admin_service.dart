// FILE: lib/services/admin_service.dart
// ============================================================================
// ADMIN SERVICE (DEBUG INSTRUMENTED)
// ============================================================================
// Handles Supabase operations for admin monitoring & moderation (UC-08)
// - Fetches dashboard statistics (filtered for soft-deletes)
// - Retrieves users, listings, donations, and reports
// - Provides moderation actions (toggle status, flag, resolve, delete)
// - Analytics/Activity Feed removed per FYP scope (Phase 2 enhancement)
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
  // ✅ DASHBOARD STATISTICS - INSTRUMENTED DEBUG VERSION ✅
  // ==================================================================
  /// Get platform statistics with per-query error isolation
  /// 
  /// Valid status values per FYP Report Tables 10-14:
  /// - profiles.account_status: 'active', 'suspended', 'deleted'
  /// - food_listings.availability_status: 'Available', 'Sold', 'Expired', 'Removed', 'Flagged'
  /// - donations.availability_status: 'Available', 'Claimed', 'Removed'
  /// - reports.status: 'Pending', 'Resolved', 'Dismissed'
  /// 
  /// Returns:
  ///   Map with counts for users, listings, donations, orders, pendingReports
  // ==================================================================
  Future<Map<String, int>> getDashboardStats() async {
    try {
      debugPrint('🔍 [AdminService] ===== STARTING DASHBOARD STATS =====');
      
      int usersCount = 0;
      int listingsCount = 0;
      int donationsCount = 0;
      int ordersCount = 0;
      int pendingReports = 0;

      // --- QUERY 1: USERS ---
      try {
        debugPrint('🔍 Query 1: Fetching active users from "profiles"...');
        final usersResponse = await _client
            .from('profiles')
            .select('id')
            .eq('account_status', 'active');
        usersCount = usersResponse.length;
        debugPrint('✅ Query 1 Success: $usersCount active users found');
      } catch (e) {
        debugPrint('❌ [DEBUG] Query 1 FAILED: $e');
        debugPrint('💡 FIX: Check if table "profiles" exists and has column "account_status"');
      }

      // --- QUERY 2: LISTINGS ---
      try {
        debugPrint('🔍 Query 2: Fetching available listings from "food_listings"...');
        final listingsResponse = await _client
            .from('food_listings')
            .select('id')
            .eq('availability_status', 'Available');
        listingsCount = listingsResponse.length;
        debugPrint('✅ Query 2 Success: $listingsCount available listings found');
      } catch (e) {
        debugPrint('❌ [DEBUG] Query 2 FAILED: $e');
        debugPrint('💡 FIX: Check if table "food_listings" exists and has column "availability_status"');
      }

      // --- QUERY 3: DONATIONS ---
      try {
        debugPrint('🔍 Query 3: Fetching available donations from "donations"...');
        final donationsResponse = await _client
            .from('donations')
            .select('id')
            .eq('availability_status', 'Available');
        donationsCount = donationsResponse.length;
        debugPrint('✅ Query 3 Success: $donationsCount available donations found');
      } catch (e) {
        debugPrint('❌ [DEBUG] Query 3 FAILED: $e');
        debugPrint('💡 FIX: Check if table "donations" exists and has column "availability_status"');
      }

      // --- QUERY 4: ORDERS ---
      try {
        debugPrint('🔍 Query 4: Fetching all orders from "orders"...');
        final ordersResponse = await _client
            .from('orders')
            .select('id');
        ordersCount = ordersResponse.length;
        debugPrint('✅ Query 4 Success: $ordersCount orders found');
      } catch (e) {
        debugPrint('❌ [DEBUG] Query 4 FAILED: $e');
        debugPrint('💡 FIX: Check if table "orders" exists');
      }

      // --- QUERY 5: REPORTS ---
      try {
        debugPrint('🔍 Query 5: Fetching pending reports from "reports"...');
        final reportsResponse = await _client
            .from('reports')
            .select('id')
            .eq('status', 'Pending');
        pendingReports = reportsResponse.length;
        debugPrint('✅ Query 5 Success: $pendingReports pending reports found');
      } catch (e) {
        debugPrint('❌ [DEBUG] Query 5 FAILED: $e');
        debugPrint('💡 FIX: Check if table "reports" exists and has column "status"');
      }

      debugPrint('✅ [AdminService] ===== ALL QUERIES COMPLETE =====');
      debugPrint('✅ Final stats: users=$usersCount, listings=$listingsCount, donations=$donationsCount, orders=$ordersCount, pending=$pendingReports');
      
      return {
        'users': usersCount,
        'listings': listingsCount,
        'donations': donationsCount,
        'orders': ordersCount,
        'pendingReports': pendingReports,
      };
      
    } catch (e, stack) {
      debugPrint('❌ [AdminService] GLOBAL ERROR in getDashboardStats: $e');
      debugPrint('📋 Stack: $stack');
      return _getMockDashboardStats();
    }
  }

  // ==================================================================
  // ✅ MOCK DATA HELPER (For FYP Demo)
  // ==================================================================
  Map<String, int> _getMockDashboardStats() {
    return {
      'users': 150,
      'listings': 45,
      'donations': 23,
      'orders': 89,
      'pendingReports': 5,
    };
  }

  // ==================================================================
  // USER MANAGEMENT
  // ==================================================================
  Future<List<UserModel>> getAllUsers() async {
    try {
      debugPrint('🔍 [AdminService] Fetching all users from profiles table...');
      
      final response = await _client
          .from('profiles')
          .select('*')
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
          .whereType<UserModel>()
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
  // ✅ ITEM (LISTING) MODERATION - FILTERED FOR ADMIN UI ✅
  // ==================================================================
  Future<List<FoodListing>> getAllListings() async {
    try {
      debugPrint('🔍 [AdminService] Fetching active/manageable listings...');
      
      // ✅ Filter out soft-deleted listings for admin view
      // This ensures removed items don't appear in the management list
      // Valid values: 'Available', 'Sold', 'Expired', 'Removed', 'Flagged'
      final response = await _client
          .from('food_listings')
          .select()
          .neq('availability_status', 'Removed') // ✅ Exclude soft-deleted items
          .order('created_at', ascending: false);

      debugPrint('📦 [AdminService] Fetched ${response.length} listings (excluding Removed)');

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
      
      // ✅ Use availability_status per your schema (Table 11)
      final response = await _client
          .from('food_listings')
          .update({'availability_status': 'Flagged'})
          .eq('id', listingId)
          .select();
      
      debugPrint('📦 [AdminService] Flag response: $response');
      
      if (response.isNotEmpty) {
        final newStatus = response[0]['availability_status'];
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
      
      // ✅ Use availability_status per your schema (Table 11)
      final response = await _client
          .from('food_listings')
          .update({'availability_status': 'Available'})
          .eq('id', listingId)
          .select();
      
      debugPrint('📦 [AdminService] Approve response: $response');
      
      if (response.isNotEmpty) {
        final newStatus = response[0]['availability_status'];
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

  // ==================================================================
  // ✅ ITEM REMOVAL - SOFT DELETE WITH CORRECT COLUMN ✅
  // ==================================================================
  Future<bool> removeListing(String listingId) async {
    try {
      debugPrint('🗑️ [AdminService] Soft-deleting listing: $listingId');
      
      // ✅ SOFT DELETE: Update availability_status instead of deleting row
      // This preserves the listing_id foreign key in the orders table
      // ✅ Uses correct column name from your schema (Table 11): availability_status
      final response = await _client
          .from('food_listings')
          .update({'availability_status': 'Removed'})
          .eq('id', listingId)
          .select(); // Returns updated row for verification

      if (response.isNotEmpty) {
        debugPrint('✅ [AdminService] Listing soft-deleted successfully');
        return true;
      } else {
        debugPrint('⚠️ [AdminService] No rows updated. Check ID or RLS policies.');
        return false;
      }
    } catch (e, stack) {
      debugPrint('❌ [AdminService] removeListing error: $e');
      debugPrint('📋 Stack trace: $stack');
      return false;
    }
  }

  // ==================================================================
  // ✅ DONATION (ADS) MODERATION - FILTERED FOR ADMIN UI ✅
  // ==================================================================
  Future<List<DonationModel>> getAllDonations() async {
    try {
      debugPrint('🔍 [AdminService] Fetching active donations...');
      
      // ✅ Filter out soft-deleted donations for admin view
      // This ensures removed ads don't appear in the management list
      // Valid values: 'Available', 'Claimed', 'Removed'
      final response = await _client
          .from('donations')
          .select()
          .neq('availability_status', 'Removed') // ✅ Exclude soft-deleted items
          .order('date_posted', ascending: false);

      debugPrint('📦 [AdminService] Fetched ${response.length} donations (excluding Removed)');

      return (response as List)
          .map((json) => DonationModel.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ AdminService.getAllDonations error: $e');
      return [];
    }
  }

  // ==================================================================
  // ✅ DONATION REMOVAL - SOFT DELETE WITH CORRECT COLUMN ✅
  // ==================================================================
  Future<bool> removeDonation(String donationId) async {
    try {
      debugPrint('🗑️ [AdminService] Soft-deleting donation: $donationId');
      
      // ✅ SOFT DELETE: Update availability_status instead of deleting row
      // This preserves the donation_id foreign key in any related tables
      // ✅ Uses correct column name from your schema (Table 13): availability_status
      final response = await _client
          .from('donations')
          .update({'availability_status': 'Removed'})
          .eq('donation_id', donationId) // ✅ Use donation_id (PK) per your schema
          .select(); // Returns updated row for verification

      if (response.isNotEmpty) {
        debugPrint('✅ [AdminService] Donation soft-deleted successfully');
        return true;
      } else {
        debugPrint('⚠️ [AdminService] No rows updated. Check ID or RLS policies.');
        return false;
      }
    } catch (e, stack) {
      debugPrint('❌ [AdminService] removeDonation error: $e');
      debugPrint('📋 Stack trace: $stack');
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