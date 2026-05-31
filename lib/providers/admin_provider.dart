// FILE: lib/providers/admin_provider.dart
// ============================================================================
// ADMIN PROVIDER
// ============================================================================
// State management for admin monitoring & moderation (UC-08)
// - Centralizes dashboard stats, user/listing/donation/report data
// - Handles loading, error, and moderation actions
// - Auto-refreshes dashboard stats after moderation actions
// Aligns with FYP Report: Table 14, UC-08, Provider Architecture
// ============================================================================

import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';
import '../models/food_listing_model.dart';
import '../models/donation_model.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _service;

  // ==================================================================
  // DASHBOARD DATA
  // ==================================================================
  Map<String, int> _stats = {};
  
  // ==================================================================
  // MANAGEMENT DATA
  // ==================================================================
  List<UserModel> _users = [];
  List<FoodListing> _listings = [];
  List<DonationModel> _donations = [];
  List<Map<String, dynamic>> _reports = [];
  
  // ==================================================================
  // STATE
  // ==================================================================
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
  // LOAD DASHBOARD DATA - WITH AUTO-REFRESH ✅
  // ==================================================================
  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    debugPrint('🔍 [AdminProvider] Loading dashboard stats...');

    try {
      // Load platform stats (filters soft-deleted items)
      _stats = await _service.getDashboardStats();
      debugPrint('✅ [AdminProvider] Stats loaded: $_stats');
      
    } catch (e, stack) {
      _error = 'Failed to load dashboard: ${e.toString()}';
      debugPrint('❌ [AdminProvider] loadDashboard error: $e');
      debugPrint('📋 Stack: $stack');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('🔄 [AdminProvider] Dashboard load complete');
    }
  }

  // ==================================================================
  // LOAD USERS
  // ==================================================================
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      debugPrint('🔍 [AdminProvider] Loading users from database...');
      _users = await _service.getAllUsers();
      debugPrint('✅ [AdminProvider] Loaded ${_users.length} users');
      
      if (_users.isEmpty) {
        debugPrint('⚠️ [AdminProvider] No users found - check RLS policies');
      }
    } catch (e, stack) {
      _error = 'Failed to load users: ${e.toString()}';
      debugPrint('❌ [AdminProvider] loadUsers error: $e');
      debugPrint('📋 Stack trace: $stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // LOAD LISTINGS
  // ==================================================================
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

  // ==================================================================
  // LOAD DONATIONS
  // ==================================================================
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

  // ==================================================================
  // LOAD REPORTS
  // ==================================================================
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
  // MODERATION ACTIONS - WITH DASHBOARD REFRESH ✅
  // ==================================================================
  
  Future<bool> updateUserStatus(String userId, String status) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🔄 [AdminProvider] Updating user $userId to $status');
      final success = await _service.updateUserStatus(userId, status);
      if (success) {
        debugPrint('✅ [AdminProvider] User status updated, refreshing data');
        await Future.wait([
          loadUsers(),      // Refresh user list
          loadDashboard(),  // ✅ Refresh dashboard stats
        ]);
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
        debugPrint('✅ [AdminProvider] User deleted, refreshing data');
        await Future.wait([
          loadUsers(),      // Refresh user list
          loadDashboard(),  // ✅ Refresh dashboard stats
        ]);
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

  Future<bool> flagListing(String listingId) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🚩 [AdminProvider] Flagging listing: $listingId');
      final success = await _service.flagListing(listingId);
      if (success) {
        debugPrint('🔄 [AdminProvider] Refreshing listings after flag');
        await loadListings();
        return true;
      }
      return false;
    } catch (e, stack) {
      _error = 'Failed to flag listing';
      debugPrint('❌ [AdminProvider] flagListing error: $e');
      debugPrint('📋 Stack: $stack');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveListing(String listingId) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('✅ [AdminProvider] Approving listing: $listingId');
      final success = await _service.approveListing(listingId);
      if (success) {
        debugPrint('🔄 [AdminProvider] Refreshing listings after approve');
        await loadListings();
        return true;
      }
      return false;
    } catch (e, stack) {
      _error = 'Failed to approve listing';
      debugPrint('❌ [AdminProvider] approveListing error: $e');
      debugPrint('📋 Stack: $stack');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeListing(String listingId) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🗑️ [AdminProvider] Removing listing: $listingId');
      final success = await _service.removeListing(listingId);
      if (success) {
        debugPrint('🔄 [AdminProvider] Refreshing listings AND dashboard');
        await Future.wait([
          loadListings(),      // Refresh listings list
          loadDashboard(),     // ✅ Refresh dashboard stats
        ]);
        return true;
      }
      return false;
    } catch (e, stack) {
      _error = 'Failed to remove listing';
      debugPrint('❌ [AdminProvider] removeListing error: $e');
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
        debugPrint('🔄 [AdminProvider] Refreshing donations AND dashboard');
        await Future.wait([
          loadDonations(),     // Refresh donations list
          loadDashboard(),     // ✅ Refresh dashboard stats
        ]);
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
        debugPrint('🔄 [AdminProvider] Refreshing reports AND dashboard');
        await Future.wait([
          loadReports(),       // Refresh reports list
          loadDashboard(),     // ✅ Refresh dashboard stats
        ]);
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
        debugPrint('🔄 [AdminProvider] Refreshing reports AND dashboard');
        await Future.wait([
          loadReports(),       // Refresh reports list
          loadDashboard(),     // ✅ Refresh dashboard stats
        ]);
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
