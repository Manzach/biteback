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
  Future<ProfileModel?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      debugPrint('🔍 [ProfileService] Fetching profile for user: ${user.id}');
      
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      debugPrint('📦 [ProfileService] Profile fetch result: ${data != null ? "Found" : "Null"}');
      
      return data != null ? ProfileModel.fromMap(data) : null;
    } catch (e) {
      debugPrint('❌ [ProfileService] getCurrentProfile error: $e');
      return null;
    }
  }

  // ==================================================================
  // ✅ UPDATE CURRENT USER'S PROFILE (With Debug Logging + .select())
  // ==================================================================
  Future<bool> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      debugPrint('🔄 [ProfileService] Starting profile update for user: $userId');
      
      final updates = <String, dynamic>{};
      
      if (fullName != null && fullName.trim().isNotEmpty) {
        updates['full_name'] = fullName.trim();
        debugPrint('📝 [ProfileService] Adding full_name update: "${fullName.trim()}"');
      }
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        updates['phone_number'] = phoneNumber.trim();
        debugPrint('📝 [ProfileService] Adding phone_number update: "${phoneNumber.trim()}"');
      }

      if (updates.isEmpty) {
        debugPrint('⚠️ [ProfileService] No updates to apply');
        return true;
      }

      // ✅ ADD THIS DEBUG BLOCK: Check auth.uid() vs userId parameter
      final currentUser = _client.auth.currentUser;
      debugPrint('🔍 DEBUG: auth.uid() = ${currentUser?.id}');
      debugPrint('🔍 DEBUG: userId param = $userId');
      debugPrint('🔍 DEBUG: Do they match? ${currentUser?.id == userId}');
      debugPrint('🔍 DEBUG: currentUser email = ${currentUser?.email}');
      
      debugPrint('📤 [ProfileService] Sending update to Supabase: $updates');
      
      // ✅ ADD .select() to verify the update succeeded
      final response = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select(); // ✅ Return updated row to verify

      debugPrint('📦 [ProfileService] Update response: $response');
      
      if (response.isNotEmpty) {
        debugPrint('✅ [ProfileService] Profile updated successfully');
        return true;
      } else {
        debugPrint('❌ [ProfileService] No rows updated - check RLS policy or userId');
        return false;
      }
      
    } catch (e, stack) {
      debugPrint('❌ [ProfileService] updateProfile error: $e');
      debugPrint('📋 [ProfileService] Stack trace: $stack');
      return false;
    }
  }

  // ==================================================================
  // FETCH PROFILE BY USER ID (For marketplace, admin, etc.)
  // ==================================================================
  Future<ProfileModel?> getProfileById(String userId) async {
    try {
      debugPrint('🔍 [ProfileService] Fetching profile by ID: $userId');
      
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      debugPrint('📦 [ProfileService] getProfileById result: ${data != null ? "Found" : "Null"}');
      
      return data != null ? ProfileModel.fromMap(data) : null;
    } catch (e) {
      debugPrint('❌ [ProfileService] getProfileById error: $e');
      return null;
    }
  }

  // ==================================================================
  // [ADMIN-ONLY] Update user role (Separate method for security)
  // ==================================================================
  Future<bool> updateUserRole({
    required String targetUserId,
    required String newRole,
    required String adminUserId,
  }) async {
    const validRoles = ['buyer', 'seller', 'donor', 'admin'];
    if (!validRoles.contains(newRole)) {
      debugPrint('❌ [ProfileService] Invalid role: $newRole');
      return false;
    }

    try {
      debugPrint('🔄 [ProfileService] Admin $adminUserId updating role for $targetUserId to $newRole');
      
      final response = await _client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', targetUserId)
          .select();
      
      debugPrint('📦 [ProfileService] Role update response: $response');
      
      if (response.isNotEmpty) {
        debugPrint('✅ [ProfileService] Role updated successfully');
        return true;
      }
      return false;
      
    } catch (e) {
      debugPrint('❌ [ProfileService] updateUserRole error: $e');
      return false;
    }
  }
}