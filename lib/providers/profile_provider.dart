// FILE: lib/providers/profile_provider.dart
import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService;
  
  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileProvider(this._profileService);

  // Getters
  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ Load profile on app start or after login
  Future<void> loadProfile() async {
    _setLoading(true);
    _error = null;
    
    try {
      _profile = await _profileService.getCurrentProfile();
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Update profile & refresh state
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? role,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      final success = await _profileService.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
      );
      
      if (success) {
        // Refresh profile after update
        await loadProfile();
        return true;
      }
      _error = 'Failed to update profile';
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() => _error = null;
}