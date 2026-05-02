// FILE: lib/services/auth_service.dart
// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String userRole = 'buyer',
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
         data:{
          'full_name': fullName,
          'role': userRole,
        },
      );
      if (response.user == null) return null;
      await Future.delayed(const Duration(milliseconds: 200));
      return UserModel(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        userRole: userRole,
      );
    } on AuthException catch (e) {
      print('❌ Signup error: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) return null;

      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (profileData == null) {
        final user = response.user;
        return UserModel(
          id: user!.id,
          email: email,
          fullName: user.userMetadata?['full_name'] as String? ?? 'User',
          phoneNumber: null,
          userRole: user.userMetadata?['role'] as String? ?? 'buyer',
        );
      }
      return UserModel.fromMap(profileData);
    } on AuthException catch (e) {
      print('❌ Login error: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final session = _client.auth.currentSession;
    final user = session?.user;
    if (user == null) return null;

    try {
      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return profileData != null ? UserModel.fromMap(profileData) : null;
    } catch (e) {
      print('❌ getCurrentUser error: $e');
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}