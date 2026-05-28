// FILE: lib/models/order_model.dart
class OrderModel {
  final String id;
  final String buyerId;
  final String listingId;
  final int quantity;
  final String status; // 'pending', 'collected', 'cancelled'
  final String? qrCode; // ✅ Nullable: generated after order creation
  final DateTime createdAt;
  final DateTime? collectedAt;

  // ✅ JOINED FIELDS from food_listings (for UI display)
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
    this.qrCode, // ✅ Now nullable
    required this.createdAt,
    this.collectedAt,
    this.foodName,
    this.foodPhotoUrl,
    this.price,
    this.pickupLocation,
  });

  // ✅ Parse Supabase response with nested food_listings join
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final listing = json['food_listings'] as Map<String, dynamic>?;
    
    return OrderModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      listingId: json['listing_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      status: json['status'] as String,
      qrCode: json['qr_code'] as String?, // ✅ Handle nullable
      createdAt: DateTime.parse(json['created_at'] as String),
      collectedAt: json['collected_at'] != null 
          ? DateTime.parse(json['collected_at'] as String) 
          : null,
      // ✅ Extract joined food_listings fields
      foodName: listing?['food_name'] as String?,
      foodPhotoUrl: listing?['photo_url'] as String?,
      price: (listing?['discounted_price'] as num?)?.toDouble(),
      pickupLocation: listing?['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'listing_id': listingId,
      'quantity': quantity,
      'status': status,
      'qr_code': qrCode,
      'created_at': createdAt.toIso8601String(),
      if (collectedAt != null) 'collected_at': collectedAt!.toIso8601String(),
    };
  }
}