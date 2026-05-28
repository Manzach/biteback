// FILE: lib/models/user_model.dart
// ============================================================================
// USER MODEL
// ============================================================================
// Represents a user in the BiteBack system with role-based access
// Aligns with FYP Report: Table 10 (User), UC-01, UC-02, UC-03
// ============================================================================

class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String userRole;
  final String accountStatus; // ✅ ADD THIS FIELD

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.userRole = 'buyer',
    this.accountStatus = 'active', // ✅ ADD DEFAULT VALUE
  });

  // ==================================================================
  // ✅ ADD THIS: Getter for backward compatibility
  // ==================================================================
  /// Returns the user's role ('buyer', 'seller', 'donor', 'admin')
  /// Used by AuthProvider and UI for role-based access checks
  // ==================================================================
  String get role => userRole;

  // ==================================================================
  // Parse Supabase JSON response (uses fromMap naming convention)
  // ==================================================================
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? map['user_email'] as String? ?? '',
      fullName: map['full_name'] as String?,
      phoneNumber: map['phone_number'] as String?,
      userRole: map['role'] as String? ?? 'buyer',
      accountStatus: map['account_status'] as String? ?? 'active',
    );
  }

  // ==================================================================
  // Convert to Map for Supabase operations
  // ==================================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': userRole,
      'account_status': accountStatus, // ✅ STORE TO DB
    };
  }

  // ==================================================================
  // Immutable copy method for state updates
  // ==================================================================
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? userRole,
    String? accountStatus, // ✅ ADD TO COPYWITH
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userRole: userRole ?? this.userRole,
      accountStatus: accountStatus ?? this.accountStatus, // ✅ ADD HERE
    );
  }

  // ==================================================================
  // ✅ ADD THIS: Helper getters for role checks (cleaner UI code)
  // ==================================================================
  bool get isAdmin => userRole.toLowerCase() == 'admin';
  bool get isSeller => userRole.toLowerCase() == 'seller';
  bool get isDonor => userRole.toLowerCase() == 'donor';
  bool get isBuyer => userRole.toLowerCase() == 'buyer';

  // ==================================================================
  // ✅ ADD THIS: Helper getters for account status checks
  // ==================================================================
  bool get isActive => accountStatus.toLowerCase() == 'active';
  bool get isInactive => accountStatus.toLowerCase() == 'inactive';
  bool get isDeleted => accountStatus.toLowerCase() == 'deleted';
}