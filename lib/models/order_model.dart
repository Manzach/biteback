// FILE: lib/models/order_model.dart
// ============================================================================
// ORDER MODEL
// ============================================================================
// Represents an order in the BiteBack system
// Aligns with FYP Report: Table 12 (Order), UC-04, Figure 38
// ============================================================================

class OrderModel {
  final String id;
  final String buyerId;
  final String listingId;
  final int quantity;
  final String status; // 'pending', 'collected', 'cancelled' (lowercase per DB)
  final String? qrCode; // ✅ Nullable: format BB-{timestamp}-{buyer_id}
  final DateTime createdAt;
  final DateTime? collectedAt;

  // ✅ JOINED FIELDS from food_listings (for UI display) - All nullable
  final String? foodName;
  final String? foodPhotoUrl;
  final double? price;
  final String? pickupLocation;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.listingId,
    required this.quantity,
    required this.status,
    this.qrCode,
    required this.createdAt,
    this.collectedAt,
    this.foodName,
    this.foodPhotoUrl,
    this.price,
    this.pickupLocation,
  });

  // ==================================================================
  // ✅ FACTORY: Parse Supabase JSON with SAFE NULL HANDLING
  // Based on orders_rows.sql schema
  // ==================================================================
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // ✅ Safely extract nested food_listings join (may not always be present)
    final listing = json['food_listings'] as Map<String, dynamic>?;

    // Helper to coerce various types (int, String, null) into a trimmed String
    String toStr(dynamic v) => v == null ? '' : v.toString().trim();

    return OrderModel(
      // ✅ Required fields with safe fallbacks (handle ints or different key names)
      id: toStr(json['id'] ?? json['order_id']),
      buyerId: toStr(json['buyer_id'] ?? json['buyerId']),
      listingId: toStr(json['listing_id'] ?? json['listingId']),

      // ✅ Safe numeric parsing with fallback
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,

      // ✅ Status: lowercase per your DB, with fallback
      status: toStr(json['status']).isNotEmpty ? toStr(json['status']).toLowerCase() : 'pending',

      // ✅ Nullable qr_code (format: BB-{timestamp}-{buyer_id})
      qrCode: (json['qr_code'] as String?) ?? toStr(json['qrCode'] ?? json['qr']),
      
      // ✅ Safe DateTime parsing with fallback to now
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      
      // ✅ Nullable collected_at
      collectedAt: json['collected_at'] != null 
          ? DateTime.tryParse(json['collected_at'] as String) 
          : null,
      
      // ✅ Safely extract joined food_listings fields (all nullable)
      foodName: listing?['food_name'] as String?,
      foodPhotoUrl: listing?['photo_url'] as String?,

      // ✅ Safe price parsing from listing's discounted_price
      price: listing?['discounted_price'] != null
          ? (listing!['discounted_price'] as num?)?.toDouble()
          : null,

      // ✅ Pickup location from listing's location field
      pickupLocation: listing?['location'] as String?,
    );
  }

  // ==================================================================
  // ✅ METHOD: Convert to Map for Supabase (snake_case columns)
  // ==================================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'listing_id': listingId,
      'quantity': quantity,
      'status': status.toLowerCase(),  // ✅ Ensure lowercase for DB
      'qr_code': qrCode,
      'created_at': createdAt.toIso8601String(),
      if (collectedAt != null) 'collected_at': collectedAt!.toIso8601String(),
    };
  }

  // ==================================================================
  // ✅ METHOD: Immutable copy for state updates
  // ==================================================================
  OrderModel copyWith({
    String? id,
    String? buyerId,
    String? listingId,
    int? quantity,
    String? status,
    String? qrCode,
    DateTime? createdAt,
    DateTime? collectedAt,
    String? foodName,
    String? foodPhotoUrl,
    double? price,
    String? pickupLocation,
  }) {
    return OrderModel(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      listingId: listingId ?? this.listingId,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
      collectedAt: collectedAt ?? this.collectedAt,
      foodName: foodName ?? this.foodName,
      foodPhotoUrl: foodPhotoUrl ?? this.foodPhotoUrl,
      price: price ?? this.price,
      pickupLocation: pickupLocation ?? this.pickupLocation,
    );
  }

  // ==================================================================
  // ✅ HELPERS: Status checks for UI logic
  // ==================================================================
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCollected => status.toLowerCase() == 'collected';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  // ==================================================================
  // ✅ DEBUG: toString() for console logging
  // ==================================================================
  @override
  String toString() {
    return 'OrderModel(id: $id, buyer: $buyerId, status: $status, qr: $qrCode)';
  }

  // ==================================================================
  // ✅ EQUALS: For list comparisons and testing
  // ==================================================================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}