import 'dart:io'; // ✅ ADD THIS for File type support
import 'package:flutter/foundation.dart';
import '../models/donation_model.dart';
import '../services/donor_service.dart';

// ============================================================================
// DONOR PROVIDER
// ============================================================================
// State management for the Donor module (UC-06: Publish Donation Advertisement)
// - Manages donor's posted donations list
// - Handles loading, error, and CRUD operations WITH PHOTO UPLOAD SUPPORT
// - Notifies UI of state changes via ChangeNotifier
// Aligns with FYP Report: Table 13 (Donation table), Figure 40 (Donor Flow)
// ============================================================================

class DonorProvider with ChangeNotifier {
  final DonorService _service = DonorService();

  // ==================================================================
  // STATE VARIABLES (Private - encapsulated)
  // ==================================================================
  List<DonationModel> _myDonations = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ==================================================================
  // GETTERS (Public, read-only for UI)
  // ==================================================================
  // ✅ Use List.unmodifiable() to prevent external modification
  List<DonationModel> get myDonations => List.unmodifiable(_myDonations);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================================================================
  // LOAD DONATIONS (Fetch donor's posted donations)
  // ==================================================================
  /// Loads all donations posted by this donor from Supabase
  /// Updates UI state: loading → success/error
  /// Must be called with valid donorId (from AuthProvider)
  Future<void> loadMyDonations(String donorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myDonations = await _service.fetchDonorDonations(donorId);
    } catch (e) {
      _errorMessage = 'Failed to load your donations. Please check your connection.';
      debugPrint('❌ DonorProvider.loadMyDonations error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // CREATE DONATION WITH PHOTO UPLOAD SUPPORT (UC-06)
  // ==================================================================
  /// Creates a new donation advertisement and saves to Supabase
  /// Optionally uploads a photo to Supabase Storage first
  Future<bool> createDonation({
    required String donorId,
    required String donationTitle,
    required String donationDescription,
    required String pickupLocation,
    required DateTime availabilityDate,
    int? quantity,
    File? photoFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final donation = DonationModel(
        donationId: '',
        donorId: donorId,
        donationTitle: donationTitle.trim(),
        donationDescription: donationDescription.trim(),
        pickupLocation: pickupLocation.trim(),
        datePosted: DateTime.now(),
        availabilityDate: availabilityDate,
        availabilityStatus: 'Available',
        photoUrl: null,
        quantity: quantity,
      );

      await _service.createDonation(donation, photoFile: photoFile);
      await loadMyDonations(donorId);
      return true;
      
    } catch (e) {
      _errorMessage = 'Failed to post donation: ${e.toString()}';
      debugPrint('❌ DonorProvider.createDonation error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // ✅ EDIT DONATION (UC-06: Update Donation Advertisement) - NOW INSIDE CLASS
  // ==================================================================
  /// Updates an existing donation with new details
  /// 
  /// Parameters:
  ///   - donationId: ID of donation to edit
  ///   - donationTitle: Updated title
  ///   - donationDescription: Updated description
  ///   - pickupLocation: Updated location
  ///   - availabilityDate: Updated date
  ///   - quantity: Updated quantity (optional)
  ///   - photoFile: New photo file (optional, triggers upload)
  /// 
  /// Returns:
  ///   - bool: true on success, false on failure
  // ==================================================================
  Future<bool> editDonation({
    required String donationId,
    required String donationTitle,
    required String donationDescription,
    required String pickupLocation,
    required DateTime availabilityDate,
    int? quantity,
    File? photoFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ✅ Prepare updates map
      final updates = <String, dynamic>{
        'donation_title': donationTitle.trim(),
        'donation_description': donationDescription.trim(),
        'pickup_location': pickupLocation.trim(),
        'availability_date': availabilityDate.toIso8601String(),
        if (quantity != null) 'quantity': quantity,
      };

      // ✅ Handle photo upload if new photo provided
      if (photoFile != null) {
        final newPhotoUrl = await _service.updateDonationPhoto(donationId, photoFile);
        updates['photo_url'] = newPhotoUrl;
      }

      // ✅ Update donation in Supabase
      await _service.updateDonation(donationId, updates);
      
      // ✅ Refresh list to show updated donation
      if (_myDonations.isNotEmpty) {
        await loadMyDonations(_myDonations.first.donorId);
      }
      
      return true;
      
    } catch (e) {
      _errorMessage = 'Failed to update donation: ${e.toString()}';
      debugPrint('❌ DonorProvider.editDonation error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // UPDATE DONATION STATUS
  // ==================================================================
  Future<void> updateDonationStatus(String donationId, String status) async {
    try {
      await _service.updateDonationStatus(donationId, status);
      if (_myDonations.isNotEmpty) {
        await loadMyDonations(_myDonations.first.donorId);
      }
    } catch (e) {
      _errorMessage = 'Failed to update donation status';
      debugPrint('❌ DonorProvider.updateDonationStatus error: $e');
      notifyListeners();
    }
  }

  // ==================================================================
  // DELETE DONATION
  // ==================================================================
  Future<void> deleteDonation(String donationId) async {
    try {
      await _service.deleteDonation(donationId);
      if (_myDonations.isNotEmpty) {
        await loadMyDonations(_myDonations.first.donorId);
      }
    } catch (e) {
      _errorMessage = 'Failed to delete donation';
      debugPrint('❌ DonorProvider.deleteDonation error: $e');
      notifyListeners();
    }
  }

  // ==================================================================
  // UTILITY METHODS
  // ==================================================================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  int get activeDonationsCount => _myDonations
      .where((d) => d.availabilityStatus == 'Available')
      .length;

  int get collectedDonationsCount => _myDonations
      .where((d) => d.availabilityStatus == 'Collected')
      .length;
} // ✅ CLASS CLOSES HERE - ALL METHODS MUST BE ABOVE THIS LINE