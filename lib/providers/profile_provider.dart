import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';

// ============================================================================
// PROFILE PROVIDER
// ============================================================================
// Manages profile update state for buyer profile editing.
// Provides loading/error feedback to the UI and delegates database
// operations to ProfileService.
// ============================================================================

class ProfileProvider with ChangeNotifier {
  final ProfileService _service;

  ProfileProvider(this._service);

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.updateProfile(
        userId: userId,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      if (!success) {
        _errorMessage = 'Failed to update profile. Please try again.';
      }

      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
