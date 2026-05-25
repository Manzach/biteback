import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/donation_model.dart';

// ============================================================================
// DONOR SERVICE
// ============================================================================
// Handles all Supabase database operations for the Donor module (UC-06)
// - Fetch donor's posted donations
// - Create new donation advertisements WITH PHOTO UPLOAD
// - Update donation details AND photos (Edit feature)
// - Update donation status (Available/Unavailable/Collected)
// - Delete donations
// Aligns with FYP Report: Table 13 (Donation table), Figure 40 (Donor Flow)
// ============================================================================

class DonorService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==================================================================
  // 📸 PHOTO UPLOAD TO SUPABASE STORAGE
  // ==================================================================
  /// Uploads a donation photo to Supabase Storage bucket 'donation-photos'
  /// Returns the public URL if successful, or null if upload fails
  /// 
  /// File structure: donations/{donorId}/{timestamp}.jpg
  Future<String?> uploadDonationPhoto(File imageFile, String donorId) async {
    try {
      final fileName = 'donations/$donorId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage
          .from('donation-photos')
          .upload(fileName, imageFile, fileOptions: const FileOptions(upsert: true));
      
      return _client.storage
          .from('donation-photos')
          .getPublicUrl(fileName);
      
    } catch (e) {
      debugPrint('❌ Photo upload error: $e');
      return null;
    }
  }

  // ==================================================================
  // 📸 UPLOAD PHOTO FOR EXISTING DONATION (Edit feature)
  // ==================================================================
  /// Uploads a new photo for an existing donation and returns the public URL
  Future<String> updateDonationPhoto(String donationId, File newPhotoFile) async {
    try {
      final fileName = 'donations/$donationId/updated_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage
          .from('donation-photos')
          .upload(fileName, newPhotoFile, fileOptions: const FileOptions(upsert: true));
      
      return _client.storage
          .from('donation-photos')
          .getPublicUrl(fileName);
          
    } catch (e) {
      debugPrint('❌ Photo update error: $e');
      throw Exception('Failed to update photo: $e');
    }
  }

  // ==================================================================
  // FETCH DONATIONS BY DONOR
  // ==================================================================
  Future<List<DonationModel>> fetchDonorDonations(String donorId) async {
    try {
      final response = await _client
          .from('donations')
          .select()
          .eq('donor_id', donorId)
          .order('date_posted', ascending: false);

      return (response as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => DonationModel.fromMap(json))
          .toList();
    } catch (e) {
      debugPrint('❌ DonorService.fetchDonorDonations error: $e');
      throw Exception('Failed to load your donations. Please check your connection.');
    }
  }

  // ==================================================================
  // CREATE NEW DONATION ADVERTISEMENT (UC-06) WITH PHOTO SUPPORT
  // ==================================================================
  Future<void> createDonation(DonationModel donation, {File? photoFile}) async {
    try {
      String? photoUrl = donation.photoUrl;
      
      if (photoFile != null && donation.donorId.isNotEmpty) {
        photoUrl = await uploadDonationPhoto(photoFile, donation.donorId);
      }
      
      final donationData = donation.toMap();
      donationData.remove('donation_id');
      donationData['donor_id'] = donation.donorId;
      
      if (photoUrl != null) {
        donationData['photo_url'] = photoUrl;
      }
      
      await _client.from('donations').insert(donationData);
      
    } catch (e) {
      debugPrint('❌ DonorService.createDonation error: $e');
      throw Exception('Failed to post donation. Please try again.');
    }
  }

// ==================================================================
// ✅ UPDATE EXISTING DONATION (Edit feature)
// ==================================================================
/// Updates an existing donation advertisement in Supabase
Future<void> updateDonation(String donationId, Map<String, dynamic> updates) async {
  try {
    // ✅ Get current user ID with null check
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Remove auto-generated fields that shouldn't be updated
    updates.remove('donation_id');
    updates.remove('donor_id');
    updates.remove('date_posted');
    
    await _client
        .from('donations')
        .update(updates)
        .eq('donation_id', donationId)
        .eq('donor_id', currentUserId); // ✅ Use non-nullable currentUserId
        
  } catch (e) {
    debugPrint('❌ DonorService.updateDonation error: $e');
    throw Exception('Failed to update donation: $e');
  }
}

  // ==================================================================
  // UPDATE DONATION STATUS
  // ==================================================================
  Future<void> updateDonationStatus(String donationId, String status) async {
    try {
      const validStatuses = ['Available', 'Unavailable', 'Collected'];
      if (!validStatuses.contains(status)) {
        throw ArgumentError('Invalid status: $status. Must be one of $validStatuses');
      }

      await _client
          .from('donations')
          .update({'availability_status': status})
          .eq('donation_id', donationId);
    } catch (e) {
      debugPrint('❌ DonorService.updateDonationStatus error: $e');
      throw Exception('Failed to update donation status.');
    }
  }

  // ==================================================================
  // DELETE DONATION
  // ==================================================================
  Future<void> deleteDonation(String donationId) async {
    try {
      await _client
          .from('donations')
          .delete()
          .eq('donation_id', donationId);
    } catch (e) {
      debugPrint('❌ DonorService.deleteDonation error: $e');
      throw Exception('Failed to delete donation.');
    }
  }

  // ==================================================================
  // HELPER: Get single donation by ID
  // ==================================================================
  Future<DonationModel?> getDonationById(String donationId) async {
    try {
      final response = await _client
          .from('donations')
          .select()
          .eq('donation_id', donationId)
          .single();

      return DonationModel.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ DonorService.getDonationById error: $e');
      return null;
    }
  }
} // ✅ CLASS CLOSES HERE - ALL METHODS MUST BE ABOVE THIS LINE