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
  final bool isSold;
  final double originalPrice;

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
    this.isSold = false,
    required this.originalPrice,
  });

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
      isSold: json['is_sold'] as bool? ?? false,
      originalPrice: (json['original_price'] as num).toDouble(),
    );
  }

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
      'is_sold': isSold,
      'original_price': originalPrice,
    };
  }

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
}