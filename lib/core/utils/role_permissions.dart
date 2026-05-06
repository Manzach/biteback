// lib/core/utils/role_permissions.dart
// ✅ NO Flutter imports — pure Dart logic only!

/// Central place for role permissions and display names.
///
/// When the app grows, add new roles and permissions here.
class RolePermissions {
  // Define capabilities per role.
  // Each role maps to a set of named permissions.
  static const Map<String, Map<String, bool>> _rules = {
    'buyer': {
      'can_browse_food': true,
      'can_purchase': true,
      'can_post_listings': false,
      'can_post_donations': false,
      'can_moderate': false,
      'can_view_analytics': false,
    },
    'seller': {
      'can_browse_food': true,
      'can_purchase': false,
      'can_post_listings': true,
      'can_post_donations': true,
      'can_moderate': false,
      'can_view_analytics': true,
    },
    'donor': {
      'can_browse_food': false,
      'can_purchase': false,
      'can_post_listings': false,
      'can_post_donations': true,
      'can_moderate': false,
      'can_view_analytics': false,
    },
    'admin': {
      'can_browse_food': true,
      'can_purchase': false,
      'can_post_listings': false,
      'can_post_donations': false,
      'can_moderate': true,
      'can_view_analytics': true,
    },
  };

  /// Check if a role has a specific permission
  static bool can(String role, String permission) {
    return _rules[role]?[permission] ?? false;
  }

  /// Get user-friendly role name (e.g., 'buyer' → 'Buyer')
  static String getDisplayName(String role) {
    return switch (role.toLowerCase()) {
      'buyer' => 'Buyer',
      'seller' => 'Seller',
      'donor' => 'Donor',
      'admin' => 'Admin',
      _ => 'User',
    };
  }

  /// Get list of all valid roles (useful for dropdowns, validation)
  static List<String> get validRoles => ['buyer', 'seller', 'donor', 'admin'];
}