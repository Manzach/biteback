// FILE: lib/providers/admin_provider.dart
// ============================================================================
// ADMIN PROVIDER
// ============================================================================
// State management for admin monitoring & moderation (UC-08)
// - Centralizes dashboard stats, user/listing/donation/report data
// - Handles loading, error, and moderation actions
// Aligns with FYP Report: Table 14, UC-08, Provider Architecture
// ============================================================================

import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';
import '../models/food_listing_model.dart';
import '../models/donation_model.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _service;

  Map<String, int> _stats = {};
  List<UserModel> _users = [];
  List<FoodListing> _listings = [];
  List<DonationModel> _donations = [];
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = false;
  String? _error;

  AdminProvider(this._service);

  // ==================================================================
  // GETTERS
  // ==================================================================
  Map<String, int> get stats => Map.unmodifiable(_stats);
  List<UserModel> get users => List.unmodifiable(_users);
  List<FoodListing> get listings => List.unmodifiable(_listings);
  List<DonationModel> get donations => List.unmodifiable(_donations);
  List<Map<String, dynamic>> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================================================================
  // LOAD DASHBOARD DATA
  // ==================================================================
  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔍 [AdminProvider] Loading dashboard stats...');
      _stats = await _service.getDashboardStats();
      debugPrint('✅ [AdminProvider] Stats loaded: $_stats');
    } catch (e) {
      _error = 'Failed to load dashboard stats';
      debugPrint('❌ AdminProvider.loadDashboard error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // LOAD USERS - ENHANCED WITH DETAILED LOGGING ✅
  // ==================================================================
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      debugPrint('🔍 [AdminProvider] Loading users from database...');
      
      _users = await _service.getAllUsers();
      
      debugPrint('📦 [AdminProvider] Service returned ${_users.length} users');
      
      if (_users.isEmpty) {
        debugPrint('⚠️ [AdminProvider] No users found - check:');
        debugPrint('   1. RLS policies on profiles table');
        debugPrint('   2. Database has user records');
        debugPrint('   3. Admin role in auth.users metadata');
      } else {
        // Log first 3 users for debugging
        for (int i = 0; i < _users.length && i < 3; i++) {
          final user = _users[i];
          debugPrint('✅ [AdminProvider] User $i: ${user.fullName} (${user.userRole}) - ${user.accountStatus}');
        }
        if (_users.length > 3) {
          debugPrint('... and ${_users.length - 3} more users');
        }
      }
      
    } catch (e, stack) {
      _error = 'Failed to load users: ${e.toString()}';
      debugPrint('❌ [AdminProvider] loadUsers error: $e');
      debugPrint('📋 Stack trace: $stack');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('🔄 [AdminProvider] Loading state reset, users count: ${_users.length}');
    }
  }

  Future<void> loadListings() async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🔍 [AdminProvider] Loading listings...');
      _listings = await _service.getAllListings();
      debugPrint('✅ [AdminProvider] Loaded ${_listings.length} listings');
    } catch (e) {
      _error = 'Failed to load listings';
      debugPrint('❌ AdminProvider.loadListings error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDonations() async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🔍 [AdminProvider] Loading donations...');
      _donations = await _service.getAllDonations();
      debugPrint('✅ [AdminProvider] Loaded ${_donations.length} donations');
    } catch (e) {
      _error = 'Failed to load donations';
      debugPrint('❌ AdminProvider.loadDonations error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🔍 [AdminProvider] Loading reports...');
      _reports = await _service.getAllReports();
      debugPrint('✅ [AdminProvider] Loaded ${_reports.length} reports');
    } catch (e) {
      _error = 'Failed to load reports';
      debugPrint('❌ AdminProvider.loadReports error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // MODERATION ACTIONS (With Loading State & Error Handling)
  // ==================================================================
  
  Future<bool> updateUserStatus(String userId, String status) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🔄 [AdminProvider] Updating user $userId to $status');
      final success = await _service.updateUserStatus(userId, status);
      if (success) {
        debugPrint('✅ [AdminProvider] User status updated, refreshing list');
        await loadUsers();
      } else {
        debugPrint('⚠️ [AdminProvider] Update returned false');
      }
      return success;
    } catch (e) {
      _error = 'Failed to update user status';
      debugPrint('❌ AdminProvider.updateUserStatus error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🗑️ [AdminProvider] Deleting user $userId');
      final success = await _service.deleteUser(userId);
      if (success) {
        debugPrint('✅ [AdminProvider] User deleted, refreshing list');
        await loadUsers();
      } else {
        debugPrint('⚠️ [AdminProvider] Delete returned false');
      }
      return success;
    } catch (e) {
      _error = 'Failed to delete user';
      debugPrint('❌ AdminProvider.deleteUser error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ IMPROVED: Flag listing with loading state & error handling
  Future<bool> flagListing(String listingId) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🚩 [Provider] Flagging listing: $listingId');
      final success = await _service.flagListing(listingId);
      
      if (success) {
        debugPrint('🔄 [Provider] Refreshing listings after flag');
        await loadListings();
        return true;
      }
      return false;
    } catch (e, stack) {
      _error = 'Failed to flag listing';
      debugPrint('❌ [Provider] flagListing error: $e');
      debugPrint('📋 Stack: $stack');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ IMPROVED: Approve listing with loading state & error handling
  Future<bool> approveListing(String listingId) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('✅ [Provider] Approving listing: $listingId');
      final success = await _service.approveListing(listingId);
      
      if (success) {
        debugPrint('🔄 [Provider] Refreshing listings after approve');
        await loadListings();
        return true;
      }
      return false;
    } catch (e, stack) {
      _error = 'Failed to approve listing';
      debugPrint('❌ [Provider] approveListing error: $e');
      debugPrint('📋 Stack: $stack');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ IMPROVED: Remove listing with loading state & error handling
  Future<bool> removeListing(String listingId) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🗑️ [Provider] Removing listing: $listingId');
      final success = await _service.removeListing(listingId);
      
      if (success) {
        debugPrint('🔄 [Provider] Refreshing listings after remove');
        await loadListings();
        return true;
      }
      return false;
    } catch (e, stack) {
      _error = 'Failed to remove listing';
      debugPrint('❌ [Provider] removeListing error: $e');
      debugPrint('📋 Stack: $stack');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeDonation(String donationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🗑️ [AdminProvider] Removing donation: $donationId');
      final success = await _service.removeDonation(donationId);
      if (success) {
        debugPrint('✅ [AdminProvider] Donation removed, refreshing list');
        await loadDonations();
      }
      return success;
    } catch (e) {
      _error = 'Failed to remove donation';
      debugPrint('❌ AdminProvider.removeDonation error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resolveReport(String reportId) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('✅ [AdminProvider] Resolving report: $reportId');
      final success = await _service.resolveReport(reportId);
      if (success) {
        debugPrint('🔄 [AdminProvider] Report resolved, refreshing list');
        await loadReports();
      }
      return success;
    } catch (e) {
      _error = 'Failed to resolve report';
      debugPrint('❌ AdminProvider.resolveReport error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReport(String reportId) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🗑️ [AdminProvider] Deleting report: $reportId');
      final success = await _service.deleteReport(reportId);
      if (success) {
        debugPrint('🔄 [AdminProvider] Report deleted, refreshing list');
        await loadReports();
      }
      return success;
    } catch (e) {
      _error = 'Failed to delete report';
      debugPrint('❌ AdminProvider.deleteReport error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // UTILITY
  // ==================================================================
  void clearError() {
    _error = null;
    notifyListeners();
    debugPrint('🧹 [AdminProvider] Error cleared');
  }
}