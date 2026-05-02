// FILE: lib/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String userRole;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.userRole = 'buyer',
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      fullName: map['full_name'],
      phoneNumber: map['phone_number'],
      userRole: map['role'] ?? 'buyer',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': userRole,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? userRole,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userRole: userRole ?? this.userRole,
    );
  }
}