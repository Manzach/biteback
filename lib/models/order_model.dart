class OrderModel {
  final String id;
  final String buyerId;
  final String listingId;
  final int quantity;
  final String status;
  final String qrCode;
  final DateTime createdAt;
  final DateTime? collectedAt;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.listingId,
    required this.quantity,
    required this.status,
    required this.qrCode,
    required this.createdAt,
    this.collectedAt,
  });

  // ✅ Renamed to fromJson for consistency with FoodListing
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      listingId: json['listing_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      status: json['status'] as String,
      qrCode: json['qr_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      collectedAt: json['collected_at'] != null 
          ? DateTime.parse(json['collected_at'] as String) 
          : null,
    );
  }

  // ✅ Renamed to toJson
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