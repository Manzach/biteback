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
  final String accountStatus; // ✅ Added: Track active/inactive/deleted status

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.userRole = 'buyer',
    this.accountStatus = 'active', // ✅ Default to active
  });

  // ==================================================================
  // ✅ GETTER: Backward compatibility for 'role' access
  // ==================================================================
  /// Returns the user's role ('buyer', 'seller', 'donor', 'admin')
  /// Used by AuthProvider and UI for role-based access checks
  String get role => userRole;

  // ==================================================================
  // ✅ FACTORY: Parse Supabase JSON response (snake_case columns)
  // ==================================================================
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      // ID: From Supabase auth or profiles table
      id: map['id'] as String? ?? map['user_id'] as String? ?? '',
      
      // Email: Handle both 'email' and 'user_email' column names
      email: map['email'] as String? ?? map['user_email'] as String? ?? '',
      
      // Full Name: Supabase uses snake_case 'full_name'
      fullName: map['full_name'] as String? ?? map['fullName'] as String?,
      
      // Phone: Supabase uses snake_case 'phone_number'
      phoneNumber: map['phone_number'] as String? ?? map['phoneNumber'] as String?,
      
      // Role: Handle both 'role' and 'user_role' column names
      userRole: map['role'] as String? ?? 
                map['user_role'] as String? ?? 
                'buyer',
      
      // Account Status: Handle both naming conventions
      accountStatus: map['account_status'] as String? ?? 
                     map['status'] as String? ?? 
                     'active',
    );
  }

  // ==================================================================
  // ✅ METHOD: Convert to Map for Supabase operations (snake_case)
  // ==================================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,              // ✅ Supabase snake_case
      'phone_number': phoneNumber,         // ✅ Supabase snake_case
      'role': userRole,                    // ✅ Or 'user_role' if needed
      'account_status': accountStatus,     // ✅ Supabase snake_case
    };
  }

  // ==================================================================
  // ✅ METHOD: Immutable copy for state updates
  // ==================================================================
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? userRole,
    String? accountStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userRole: userRole ?? this.userRole,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }

  // ==================================================================
  // ✅ HELPERS: Role checks for cleaner UI code
  // ==================================================================
  bool get isAdmin => userRole.toLowerCase() == 'admin';
  bool get isSeller => userRole.toLowerCase() == 'seller';
  bool get isDonor => userRole.toLowerCase() == 'donor';
  bool get isBuyer => userRole.toLowerCase() == 'buyer';

  // ==================================================================
  // ✅ HELPERS: Account status checks for UI logic
  // ==================================================================
  bool get isActive => accountStatus.toLowerCase() == 'active';
  bool get isInactive => accountStatus.toLowerCase() == 'inactive';
  bool get isDeleted => accountStatus.toLowerCase() == 'deleted';
  bool get isSuspended => accountStatus.toLowerCase() == 'suspended';

  // ==================================================================
  // ✅ DEBUG: toString() for console logging
  // ==================================================================
  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, role: $userRole, status: $accountStatus)';
  }

  // ==================================================================
  // ✅ EQUALS: For list comparisons and testing
  // ==================================================================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}