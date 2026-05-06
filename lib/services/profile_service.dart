// FILE: lib/services/profile_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _client;

  ProfileService(this._client);

  // ✅ Fetch current user's profile
  Future<ProfileModel?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle(); // Safe: returns null if no row (won't crash)

      return data != null ? ProfileModel.fromMap(data) : null;
    } catch (e) {
      print('❌ Error fetching profile: $e');
      return null;
    }
  }

  // ✅ Update current user's profile
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? role,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (role != null) updates['role'] = role;

      if (updates.isEmpty) return true; // Nothing to update

      await _client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);

      return true;
    } catch (e) {
      print('❌ Error updating profile: $e');
      return false;
    }
  }

  // ✅ Optional: Fetch another user's profile (for marketplace, etc.)
  Future<ProfileModel?> getProfileById(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return data != null ? ProfileModel.fromMap(data) : null;
    } catch (e) {
      print('❌ Error fetching profile by ID: $e');
      return null;
    }
  }
}