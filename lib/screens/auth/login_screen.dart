// FILE: lib/screens/auth/login_screen.dart
// ============================================================================
// LOGIN SCREEN
// ============================================================================
// Handles user authentication with hidden admin access
// - Normal users: Email + Password → /home → RoleDashboard handles UI
// - Admins: Long-press logo OR normal login → /home → RoleDashboard shows admin content
// Aligns with FYP Report: UC-02, UC-03, Figure 36-37
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ For HapticFeedback
import 'package:flutter/foundation.dart'; // ✅ For debugPrint
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/loading_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==================================================================
  // NORMAL USER LOGIN (Original Flow: Always Go to /home)
  // ==================================================================
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    debugPrint('🔐 [Login] Starting normal login flow...');
    debugPrint('🔐 [Login] Email: ${_emailController.text.trim()}');
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      debugPrint(' [Login] signIn() returned: $success');
      debugPrint('🔐 [Login] Auth error: ${authProvider.error}');
      
      if (!mounted) {
        debugPrint('⚠️ [Login] Widget unmounted during login. Aborting.');
        return;
      }
      
      if (success) {
        debugPrint('🔐 [Login] Auth successful. User: ${authProvider.currentUser?.email}');
        debugPrint('🔐 [Login] Role: ${authProvider.currentUser?.userRole}');
        
        // ✅ ORIGINAL FLOW: Always navigate to /home, let RoleDashboard handle UI
        debugPrint('✅ [Login] Navigating to /home (RoleDashboard will handle role-specific content)');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        debugPrint('❌ [Login] Login failed. Showing error.');
      }
    } catch (e, stack) {
      debugPrint('💥 [Login] Unexpected error: $e');
      debugPrint('📋 [Login] Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==================================================================
  // ✅ HIDDEN ADMIN LOGIN DIALOG (Original Flow: Go to /home)
  // ==================================================================
  /// Shows a hidden admin login dialog when logo is long-pressed
  /// After successful login, navigates to /home where RoleDashboard shows admin content
  /// Aligns with UC-03: "Admin hold the biteback symbol to redirect to admin login"
  // ==================================================================
  void _showAdminLoginDialog(BuildContext context) {
    final adminEmailController = TextEditingController();
    final adminPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🔐 Admin Access', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter administrator credentials',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // ✅ Admin Email Field
            CustomTextField(
              controller: adminEmailController,
              label: 'Admin Email',
              hint: 'admin@biteback.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            
            // ✅ Admin Password Field
            CustomTextField(
              controller: adminPasswordController,
              label: 'Password',
              hint: 'Enter admin password',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = adminEmailController.text.trim();
              final password = adminPasswordController.text;
              
              if (email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
                );
                return;
              }
              
              debugPrint('🛡️ [AdminLogin] Attempting admin login for: $email');
              
              final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
              
              try {
                final success = await authProvider.signIn(email: email, password: password);
                debugPrint('🛡️ [AdminLogin] signIn() returned: $success');
                debugPrint('🛡️ [AdminLogin] Auth error: ${authProvider.error}');
                
                if (!mounted) {
                  debugPrint('⚠️ [AdminLogin] Context unmounted. Aborting.');
                  return;
                }
                
                if (success) {
                  final currentUser = authProvider.currentUser;
                  debugPrint('🛡️ [AdminLogin] currentUser loaded: ${currentUser?.email}');
                  debugPrint('🛡️ [AdminLogin] Role: ${currentUser?.userRole} | isAdmin: ${currentUser?.isAdmin}');
                  
                  // ✅ ORIGINAL FLOW: Navigate to /home, let RoleDashboard show admin content
                  Navigator.pop(ctx);
                  debugPrint('✅ [AdminLogin] Admin verified. Navigating to /home (RoleDashboard will show admin content)');
                  Navigator.pushReplacementNamed(context, '/home');
                  
                } else {
                  debugPrint('❌ [AdminLogin] signIn() failed. Showing invalid credentials.');
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Invalid admin credentials'), backgroundColor: Colors.red),
                  );
                }
              } catch (e, stack) {
                debugPrint('💥 [AdminLogin] Exception: $e');
                debugPrint('📋 [AdminLogin] Stack: $stack');
                if (mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Login error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Login as Admin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // ✅ LOGO WITH HIDDEN ADMIN ACCESS (Long-press to reveal)
                // Aligns with UC-03: "Admin hold the biteback symbol to redirect to admin login page"
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque, // Ensures full tap area is responsive
                    onTap: () {
                      // Normal tap does nothing - just visual feedback
                      HapticFeedback.lightImpact();
                    },
                    onLongPress: () {
                      // ✅ Hidden admin access triggered
                      HapticFeedback.mediumImpact(); // Subtle vibration feedback
                      debugPrint('🎯 [UI] Logo long-pressed. Opening admin login dialog.');
                      _showAdminLoginDialog(context);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          height: 220,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 8),
                        // Subtle hint for admins (barely visible)
                        Text(
                          'BiteBack',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Login Header
                Center(
                  child: Text(
                    'LOG IN',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@iium.edu.my',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email required';
                    if (!value!.contains('@')) return 'Valid email required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Password required';
                    if (value!.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.primaryOrange),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                LoadingButton(
                  text: 'LOG IN',
                  isLoading: authProvider.isLoading,
                  onPressed: authProvider.isLoading ? null : _handleLogin,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(height: 24),

                // Error Message
                if (authProvider.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authProvider.error!,
                      style: TextStyle(color: AppColors.error, fontSize: 14),
                    ),
                  ),

                const SizedBox(height: 32),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}