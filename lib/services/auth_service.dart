// FILE: lib/services/auth_service.dart
// ============================================================================
// AUTH SERVICE
// ============================================================================
// Handles all Supabase authentication operations for BiteBack
// - User registration with role assignment
// - Login with profile fetching from 'profiles' table
// - Session management and password reset
// - Robust fallbacks for RLS policy failures
// Aligns with FYP Report: UC-01, UC-02, UC-03, Section 4.2.1
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  // ==================================================================
  // SIGN UP: Create new user with role in metadata + profiles table
  // ==================================================================
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String userRole = 'buyer',
  }) async {
    try {
      debugPrint('🔐 [AuthService] Starting signup for: $email');

      // 1. Create user in Supabase Auth with metadata
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': userRole,
        },
      );

      if (response.user == null) {
        debugPrint('❌ [AuthService] Signup failed: No user returned');
        return null;
      }

      debugPrint('✅ [AuthService] Auth user created: ${response.user!.id}');

      // 2. Insert profile into 'profiles' table (with retry for RLS timing)
      try {
        await Future.delayed(const Duration(milliseconds: 300)); // Allow trigger to run
        
        await _client.from('profiles').upsert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'phone_number': phoneNumber,
          'role': userRole,
          'account_status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
        
        debugPrint('✅ [AuthService] Profile inserted/updated in profiles table');
      } catch (profileError) {
        debugPrint('⚠️ [AuthService] Profile insert warning: $profileError');
        // Continue - auth metadata has role as fallback
      }

      // 3. Build and return UserModel
      return UserModel(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        userRole: userRole,
        accountStatus: 'active',
      );

    } on AuthException catch (e) {
      debugPrint('❌ [AuthService] Signup AuthException: ${e.message}');
      rethrow;
    } catch (e, stack) {
      debugPrint('❌ [AuthService] Signup unexpected error: $e');
      debugPrint('📋 Stack: $stack');
      rethrow;
    }
  }

  // ==================================================================
  // SIGN IN: Authenticate + fetch profile with fallbacks
  // ==================================================================
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 [AuthService] Starting signin for: $email');

      // 1. Authenticate with Supabase Auth
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        debugPrint('❌ [AuthService] Signin failed: No user returned');
        return null;
      }

      debugPrint('✅ [AuthService] Auth successful for: ${response.user!.email}');

      // 2. Fetch profile from 'profiles' table (with RLS-safe fallback)
      Map<String, dynamic>? profileData;
      try {
        profileData = await _client
            .from('profiles')
            .select('id, email, full_name, phone_number, role, account_status')
            .eq('id', response.user!.id)
            .maybeSingle();
        
        debugPrint('📦 [AuthService] Profile query result: ${profileData != null ? 'Found' : 'Null'}');
      } catch (e) {
        debugPrint('⚠️ [AuthService] Profile query failed (RLS?): $e');
        debugPrint('🔄 [AuthService] Falling back to auth metadata');
        profileData = null;
      }

      // 3. Build UserModel with robust fallbacks
      return _buildUserFromAuthAndProfile(response.user!, profileData);

    } on AuthException catch (e) {
      debugPrint('❌ [AuthService] Signin AuthException: ${e.message}');
      rethrow;
    } catch (e, stack) {
      debugPrint('❌ [AuthService] Signin unexpected error: $e');
      debugPrint('📋 Stack: $stack');
      rethrow;
    }
  }

  // ==================================================================
  // GET CURRENT USER: Check session + fetch profile
  // ==================================================================
  Future<UserModel?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      final user = session?.user;
      
      if (user == null) {
        debugPrint('ℹ️ [AuthService] No active session');
        return null;
      }

      debugPrint('🔐 [AuthService] Checking session for: ${user.email}');

      // Fetch profile with fallback
      Map<String, dynamic>? profileData;
      try {
        profileData = await _client
            .from('profiles')
            .select('id, email, full_name, phone_number, role, account_status')
            .eq('id', user.id)
            .maybeSingle();
      } catch (e) {
        debugPrint('⚠️ [AuthService] getCurrentUser profile query failed: $e');
        profileData = null;
      }

      return _buildUserFromAuthAndProfile(user, profileData);

    } catch (e, stack) {
      debugPrint('❌ [AuthService] getCurrentUser error: $e');
      debugPrint('📋 Stack: $stack');
      return null;
    }
  }

  // ==================================================================
  // SIGN OUT: Clear session
  // ==================================================================
  Future<void> signOut() async {
    try {
      debugPrint('🔐 [AuthService] Signing out');
      await _client.auth.signOut();
      debugPrint('✅ [AuthService] Sign out successful');
    } catch (e) {
      debugPrint('❌ [AuthService] Sign out error: $e');
      rethrow;
    }
  }

  // ==================================================================
  // RESET PASSWORD: Send reset email
  // ==================================================================
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('🔐 [AuthService] Sending password reset for: $email');
      await _client.auth.resetPasswordForEmail(email);
      debugPrint('✅ [AuthService] Password reset email sent');
    } catch (e) {
      debugPrint('❌ [AuthService] Reset password error: $e');
      rethrow;
    }
  }

  // ==================================================================
  // ✅ HELPER: Build UserModel with robust fallbacks + debug logging
  // ==================================================================
  UserModel _buildUserFromAuthAndProfile(
    User user,
    Map<String, dynamic>? profileData,
  ) {
    // 1. Extract full_name with 3-level fallback + logging
    String fullName = profileData?['full_name'] as String? ?? '';
    debugPrint('👤 [AuthService] full_name from profiles: "$fullName"');
    
    if (fullName.isEmpty) {
      fullName = user.userMetadata?['full_name'] as String? ?? '';
      debugPrint('👤 [AuthService] full_name from auth metadata: "$fullName"');
    }
    
    if (fullName.isEmpty) {
      fullName = user.email?.split('@').first ?? 'User';
      debugPrint('👤 [AuthService] full_name from email prefix: "$fullName"');
    }
    
    if (fullName.isEmpty) {
      fullName = 'User';
      debugPrint('⚠️ [AuthService] No name found, using default: "$fullName"');
    }

    // 2. Extract role with fallback
    String userRole = profileData?['role'] as String? ?? '';
    debugPrint('🎭 [AuthService] role from profiles: "$userRole"');
    
    if (userRole.isEmpty) {
      userRole = user.userMetadata?['role'] as String? ?? 'buyer';
      debugPrint('🎭 [AuthService] role from auth metadata: "$userRole"');
    }

    // 3. Extract account_status
    String accountStatus = profileData?['account_status'] as String? ?? 'active';

    // 4. Extract optional fields
    String? phoneNumber = profileData?['phone_number'] as String?;
    String email = profileData?['email'] as String? ?? user.email ?? '';

    // 5. Log final built user (mask ID for security)
    debugPrint('✅ [AuthService] Built UserModel:');
    debugPrint('   - id: ${user.id.substring(0, 8)}...');
    debugPrint('   - email: $email');
    debugPrint('   - fullName: "$fullName"');
    debugPrint('   - userRole: "$userRole"');
    debugPrint('   - accountStatus: "$accountStatus"');
    debugPrint('   - phoneNumber: ${phoneNumber ?? "null"}');

    return UserModel(
      id: profileData?['id'] as String? ?? user.id,
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      userRole: userRole,
      accountStatus: accountStatus,
    );
  }

  // ==================================================================
  // ✅ UTILITY: Check if user is confirmed (for email verification)
  // ==================================================================
  bool isUserConfirmed(User? user) {
    return user?.emailConfirmedAt != null;
  }

  // ==================================================================
  // ✅ UTILITY: Get user role directly from session (quick check)
  // ==================================================================
  String? getUserRoleFromSession() {
    final user = _client.auth.currentUser;
    return user?.userMetadata?['role'] as String?;
  }
}