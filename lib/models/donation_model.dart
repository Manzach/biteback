class DonationModel {
  final String donationId;
  final String donorId;
  final String donationTitle;
  final String donationDescription;
  final String pickupLocation;
  final DateTime datePosted;
  final DateTime? availabilityDate;
  final String availabilityStatus;
  final String? photoUrl;
  final int? quantity;

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

  // ✅ Factory: Convert Supabase JSON → DonationModel
  factory DonationModel.fromMap(Map<String, dynamic> map) {
    return DonationModel(
      donationId: map['donation_id'] as String? ?? '',
      donorId: map['donor_id'] as String? ?? '',
      donationTitle: map['donation_title'] as String? ?? 'Food Donation',
      donationDescription: map['donation_description'] as String? ?? '',
      pickupLocation: map['pickup_location'] as String? ?? '',
      datePosted: map['date_posted'] != null 
          ? DateTime.parse(map['date_posted'] as String) 
          : DateTime.now(),
      availabilityDate: map['availability_date'] != null
          ? DateTime.parse(map['availability_date'] as String)
          : null,
      availabilityStatus: map['availability_status'] as String? ?? 'Available',
      photoUrl: map['photo_url'] as String?,
      // ✅ Safer quantity parsing: handles both int and num from Supabase
      quantity: map['quantity'] != null 
          ? (map['quantity'] as num).toInt() 
          : null,
    );
  }

  // ✅ Convert DonationModel → JSON (for sending to Supabase)
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
      'availability_status': availabilityStatus,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (quantity != null) 'quantity': quantity,
    };
  }

  // ✅ Helper: Empty factory for safe fallbacks (like FoodListing.empty())
  factory DonationModel.empty() {
    return DonationModel(
      donationId: '',
      donorId: '',
      donationTitle: '',
      donationDescription: '',
      pickupLocation: '',
      datePosted: DateTime.now(),
      availabilityStatus: 'Available',
    );
  }

  // ✅ Helper: Check if donation is still available for viewing
  bool get isAvailable => availabilityStatus == 'Available';
}