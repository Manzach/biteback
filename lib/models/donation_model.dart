// FILE: lib/models/donation_model.dart
// ============================================================================
// DONATION MODEL
// ============================================================================
// Data model for food donation advertisements (UC-06)
// Aligns with FYP Report: Table 13 (Donation table), Section 3.5.1
// ============================================================================

import 'package:flutter/foundation.dart';

class DonationModel {
  // ==================================================================
  // CORE FIELDS (Match Supabase 'donations' table)
  // ==================================================================
  final String donationId;        // donation_id (PK) from Supabase
  final String donorId;           // donor_id (FK)
  final String donationTitle;     // donation_title
  final String donationDescription; // donation_description
  final String pickupLocation;    // pickup_location
  final DateTime datePosted;      // date_posted
  final DateTime? availabilityDate; // availability_date (optional)
  final String availabilityStatus; // availability_status
  final String? photoUrl;         // photo_url (optional)
  final int? quantity;            // quantity (optional)

  DonationModel({
    required this.donationId,
    required this.donorId,
    required this.donationTitle,
    required this.donationDescription,
    required this.pickupLocation,
    required this.datePosted,
    this.availabilityDate,
    required this.availabilityStatus,
    this.photoUrl,
    this.quantity,
  });

  // ✅ ADD THIS: Consistent 'id' getter for UI compatibility
  String get id => donationId;

  // ==================================================================
  // ✅ FACTORY: Convert Supabase JSON → DonationModel
  // ==================================================================
  factory DonationModel.fromMap(Map<String, dynamic> map) {
    return DonationModel(
      // Accept both 'donation_id' and 'id' for flexibility
      donationId: map['donation_id'] as String? ?? map['id'] as String? ?? '',
      donorId: map['donor_id'] as String? ?? '',
      donationTitle: map['donation_title'] as String? ?? map['title'] as String? ?? 'Food Donation',
      donationDescription: map['donation_description'] as String? ?? map['description'] as String? ?? '',
      pickupLocation: map['pickup_location'] as String? ?? '',
      datePosted: map['date_posted'] != null 
          ? DateTime.parse(map['date_posted'] as String) 
          : DateTime.now(),
      availabilityDate: map['availability_date'] != null
          ? DateTime.parse(map['availability_date'] as String)
          : null,
      // ✅ Map DB column 'availability_status' to Dart field with fallback
      availabilityStatus: map['availability_status'] as String? ?? 
                          map['status'] as String? ?? 'Available',
      photoUrl: map['photo_url'] as String? ?? map['image_url'] as String?,
      quantity: map['quantity'] != null 
          ? (map['quantity'] as num).toInt() 
          : null,
    );
  }

  // ==================================================================
  // ✅ METHOD: Convert DonationModel → JSON (for Supabase)
  // ==================================================================
  Map<String, dynamic> toMap() {
    return {
      'donation_id': donationId,
      'donor_id': donorId,
      'donation_title': donationTitle,
      'donation_description': donationDescription,
      'pickup_location': pickupLocation,
      'date_posted': datePosted.toIso8601String(),
      if (availabilityDate != null) 
        'availability_date': availabilityDate!.toIso8601String(),
      // ✅ Use correct DB column name
      'availability_status': availabilityStatus,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (quantity != null) 'quantity': quantity,
    };
  }

  // ==================================================================
  // ✅ HELPER: Empty factory for safe fallbacks
  // ==================================================================
  factory DonationModel.empty() {
    return DonationModel(
      donationId: '',
      donorId: '',
      donationTitle: '',
      donationDescription: '',
      pickupLocation: '',
      datePosted: DateTime.now(),
      availabilityStatus: 'Available', // ✅ Default matches schema
    );
  }

  // ==================================================================
  // ✅ STATUS HELPERS - Null-safe & lowercase comparison
  // ==================================================================
  
  /// Check if donation is still available for claiming
  bool get isAvailable => availabilityStatus.toLowerCase() == 'available';
  
  /// Check if donation has been claimed
  bool get isClaimed => availabilityStatus.toLowerCase() == 'claimed';
  
  /// Check if donation was removed by admin
  bool get isRemoved => availabilityStatus.toLowerCase() == 'removed';

  // ==================================================================
  // ✅ HELPER: Format date for display (DD/MM/YYYY)
  // ==================================================================
  String get formattedDate {
    return '${datePosted.day.toString().padLeft(2, '0')}/'
           '${datePosted.month.toString().padLeft(2, '0')}/'
           '${datePosted.year}';
  }

  // ==================================================================
  // ✅ HELPER: Format availability date for display
  // ==================================================================
  String? get formattedAvailabilityDate {
    if (availabilityDate == null) return null;
    return '${availabilityDate!.day.toString().padLeft(2, '0')}/'
           '${availabilityDate!.month.toString().padLeft(2, '0')}/'
           '${availabilityDate!.year}';
  }

  // ==================================================================
  // ✅ DEBUG: toString() for console logging
  // ==================================================================
  @override
  String toString() {
    return 'DonationModel(donationId: $donationId, title: "$donationTitle", status: $availabilityStatus)';
  }

  // ==================================================================
  // ✅ EQUALS: For list comparisons and testing
  // ==================================================================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DonationModel && other.donationId == donationId;
  }

  @override
  int get hashCode => donationId.hashCode;
}