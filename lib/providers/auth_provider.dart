// FILE: lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/utils/role_permissions.dart'; // ← NEW: Import permissions

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authService);

  // ─────────────────────────────────────
  // 🔹 Existing Getters (unchanged)
  // ─────────────────────────────────────
  UserModel? get currentUser => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  // ─────────────────────────────────────
  // 🔹 NEW: Role & Permission Helpers
  // ─────────────────────────────────────

  /// Get current user's role (safe null handling)
  String? get userRole => _user?.userRole;

  /// Check if current user has a specific permission
  /// Usage: if (context.read<AuthProvider>().can('can_purchase')) { ... }
  bool can(String permission) {
    if (_user == null || _user!.userRole == null) return false;
    return RolePermissions.can(_user!.userRole!, permission);
  }

  /// Get user-friendly role display name (e.g., 'buyer' → 'Buyer')
  String get roleDisplayName {
    if (_user?.userRole == null) return 'User';
    return RolePermissions.getDisplayName(_user!.userRole!);
  }

  // ─────────────────────────────────────
  // 🔹 Auth Methods (unchanged logic, minor formatting)
  // ─────────────────────────────────────

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String userRole = 'buyer',
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        userRole: userRole,
      );
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }
      _error = 'Sign up failed';
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final user = await _authService.signIn(
        email: email,
        password: password,
      );
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }
      _error = 'Invalid credentials';
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      _user = await _authService.getCurrentUser();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────
  // 🔹 Internal Helpers
  // ─────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() => _error = null;
}