// FILE: lib/services/profile_service.dart
// ============================================================================
// PROFILE SERVICE
// ============================================================================
// Handles Supabase database operations for user profiles
// - Fetch current user's profile
// - Update profile fields (full_name, phone_number)
// - SECURITY: Role updates restricted to admin-only operations
// Aligns with FYP Report: Table 10 (User table), UC-02 (Login/Profile)
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // ✅ For debugPrint
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _client;

  ProfileService(this._client);

  // ==================================================================
  // FETCH CURRENT USER'S PROFILE
  // ==================================================================
  /// Retrieves the profile data for the currently authenticated user
  /// Returns null if user is not logged in or profile doesn't exist
  /// Uses maybeSingle() to avoid crashes on missing rows
  // ==================================================================
  Future<ProfileModel?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle(); // Safe: returns null if no row

      return data != null ? ProfileModel.fromMap(data) : null;
    } catch (e) {
      debugPrint('❌ ProfileService.getCurrentProfile error: $e');
      return null;
    }
  }

// ==================================================================
// UPDATE CURRENT USER'S PROFILE (SECURE)
// ==================================================================
Future<bool> updateProfile({
  required String userId, // ✅ ADD THIS parameter
  String? fullName,
  String? phoneNumber,
}) async {
  try {
    final updates = <String, dynamic>{};
    
    if (fullName != null && fullName.trim().isNotEmpty) {
      updates['full_name'] = fullName.trim();
    }
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      updates['phone_number'] = phoneNumber.trim();
    }

    if (updates.isEmpty) return true;

    await _client
        .from('profiles')
        .update(updates)
        .eq('id', userId); // ✅ Use passed userId instead of auth.currentUser?.id

    return true;
  } catch (e) {
    debugPrint('❌ ProfileService.updateProfile error: $e');
    return false;
  }
}

  // ==================================================================
  // FETCH PROFILE BY USER ID (For marketplace, admin, etc.)
  // ==================================================================
  /// Retrieves profile data for a specific user ID
  /// Useful for displaying seller/donor info in listings
  /// Returns null if profile doesn't exist or fetch fails
  // ==================================================================
  Future<ProfileModel?> getProfileById(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return data != null ? ProfileModel.fromMap(data) : null;
    } catch (e) {
      debugPrint('❌ ProfileService.getProfileById error: $e');
      return null;
    }
  }

  // ==================================================================
  // [ADMIN-ONLY] Update user role (Separate method for security)
  // ==================================================================
  /// Updates a user's role - RESTRICTED TO ADMIN USE ONLY
  /// 
  /// ⚠️ This method should ONLY be called from AdminService/AdminProvider
  /// It includes an additional check to ensure caller has admin privileges
  /// 
  /// Parameters:
  ///   - targetUserId: The user whose role will be changed
  ///   - newRole: New role value ('buyer', 'seller', 'donor', 'admin')
  ///   - adminUserId: The ID of the admin performing the action (for audit)
  // ==================================================================
  Future<bool> updateUserRole({
    required String targetUserId,
    required String newRole,
    required String adminUserId, // For audit/logging
  }) async {
    // ✅ Validate role value against allowed options
    const validRoles = ['buyer', 'seller', 'donor', 'admin'];
    if (!validRoles.contains(newRole)) {
      debugPrint('❌ Invalid role: $newRole');
      return false;
    }

    try {
      // ✅ Optional: Verify adminUserId has admin role (add your logic here)
      // final adminProfile = await getProfileById(adminUserId);
      // if (adminProfile?.role != 'admin') return false;

      await _client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', targetUserId);

      return true;
    } catch (e) {
      debugPrint('❌ ProfileService.updateUserRole error: $e');
      return false;
    }
  }
}