// FILE: lib/models/food_listing_model.dart
// ============================================================================
// FOOD LISTING MODEL
// ============================================================================
// Represents a food item listed by a seller for discounted sale
// Includes moderation status for admin oversight (UC-08)
// Aligns with FYP Report: Table 11 (Food Listing)
// ============================================================================

class FoodListing {
  final String id;
  final String sellerId;
  final String foodName;
  final String description;
  final double discountedPrice;
  final int quantity;
  final DateTime expiryDate;
  final String location;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isHidden;
  final bool isSold;
  final double originalPrice;
  final String moderationStatus; // ✅ NEW: 'Active', 'Flagged', 'Removed'

  FoodListing({
    required this.id,
    required this.sellerId,
    required this.foodName,
    required this.description,
    required this.discountedPrice,
    required this.quantity,
    required this.expiryDate,
    required this.location,
    required this.photoUrl,
    required this.createdAt,
    this.isHidden = false,
    this.isSold = false,
    required this.originalPrice,
    this.moderationStatus = 'Active', // ✅ DEFAULT: Visible to buyers
  });

  // ==================================================================
  // Factory: converts Supabase JSON → FoodListing
  // ==================================================================
  factory FoodListing.fromJson(Map<String, dynamic> json) {
    return FoodListing(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      foodName: json['food_name'] as String,
      description: json['description'] as String? ?? '',
      discountedPrice: (json['discounted_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      location: json['location'] as String,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isHidden: json['is_hidden'] as bool? ?? false,
      isSold: json['is_sold'] as bool? ?? false,
      originalPrice: (json['original_price'] as num).toDouble(),
      // ✅ Map DB column 'moderation_status' to Dart field
      moderationStatus: json['moderation_status'] as String? ?? 'Active',
    );
  }

  // ==================================================================
  // Factory: converts FoodListing → JSON (for debugging/sending)
  // ==================================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'food_name': foodName,
      'description': description,
      'discounted_price': discountedPrice,
      'quantity': quantity,
      'expiry_date': expiryDate.toIso8601String(),
      'location': location,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'is_hidden': isHidden,
      'is_sold': isSold,
      'original_price': originalPrice,
      'moderation_status': moderationStatus, // ✅ Include for updates
    };
  }

  // ==================================================================
  // Factory: Empty instance for fallbacks
  // ==================================================================
  factory FoodListing.empty() {
    return FoodListing(
      id: '',
      sellerId: '',
      foodName: '',
      description: '',
      discountedPrice: 0,
      quantity: 0,
      expiryDate: DateTime.now(),
      location: '',
      photoUrl: null,
      createdAt: DateTime.now(),
      isHidden: false,
      isSold: false,
      originalPrice: 0,
      moderationStatus: 'Active', // ✅ Default for empty
    );
  }

  // ==================================================================
  // Getters (unchanged)
  // ==================================================================
  double get discountPercentage {
    if (originalPrice == 0) return 0;
    return ((originalPrice - discountedPrice) / originalPrice * 100);
  }

  int get hoursUntilExpiry {
    final hours = expiryDate.difference(DateTime.now()).inHours;
    return hours < 0 ? 0 : hours;
  }

  bool get isExpired {
    return expiryDate.isBefore(DateTime.now());
  }

  bool get isAvailable => !isSold && !isExpired && quantity > 0;

  // ==================================================================
  // ✅ NEW: Moderation Status Helpers (Cleaner UI checks)
  // ==================================================================
  bool get isActive => moderationStatus.toLowerCase() == 'active';
  bool get isFlagged => moderationStatus.toLowerCase() == 'flagged';
  bool get isRemoved => moderationStatus.toLowerCase() == 'removed';

  // ==================================================================
  // ✅ NEW: CopyWith for immutable updates
  // ==================================================================
  FoodListing copyWith({
    String? id,
    String? sellerId,
    String? foodName,
    String? description,
    double? discountedPrice,
    int? quantity,
    DateTime? expiryDate,
    String? location,
    String? photoUrl,
    DateTime? createdAt,
    bool? isHidden,
    bool? isSold,
    double? originalPrice,
    String? moderationStatus,
  }) {
    return FoodListing(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      foodName: foodName ?? this.foodName,
      description: description ?? this.description,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      location: location ?? this.location,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isHidden: isHidden ?? this.isHidden,
      isSold: isSold ?? this.isSold,
      originalPrice: originalPrice ?? this.originalPrice,
      moderationStatus: moderationStatus ?? this.moderationStatus,
    );
  }
}