// lib/shared/widgets/permission_builder.dart
// ✅ Flutter-dependent UI helper — separate from pure logic
import 'package:flutter/material.dart';
import '../utils/role_permissions.dart';

/// Conditionally show a widget based on role permissions.
/// Usage:
/// ```dart
/// PermissionBuilder(
///   role: user.userRole,
///   permission: 'can_purchase',
///   builder: (context) => ElevatedButton(...),
///   fallback: (context) => const Text('Upgrade to buy'),
/// )
/// ```
class PermissionBuilder extends StatelessWidget {
  final String role;
  final String permission;
  final WidgetBuilder builder;
  final WidgetBuilder? fallback;

  const PermissionBuilder({
    super.key,
    required this.role,
    required this.permission,
    required this.builder,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (RolePermissions.can(role, permission)) {
      return builder(context);
    }
    return fallback?.call(context) ?? const SizedBox.shrink();
  }
}

/// Simple extension for quick inline checks
extension PermissionCheck on String {
  bool can(String permission) => RolePermissions.can(this, permission);
}