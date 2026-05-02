import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/loading_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // UI State
  String _selectedRole = 'buyer'; // Default role
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  @override
  void dispose() {
    // 🔥 Critical: Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ Handle Signup Submission
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim(),
      userRole: _selectedRole,
    );
    
    if (success && mounted) {
      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Account created! Check your email to verify.'),
          backgroundColor: AppColors.secondaryGreen,
          duration: Duration(seconds: 4),
        ),
      );
      
      // 🔁 Navigate to login (or home if auto-login enabled)
      Navigator.pushReplacementNamed(context, '/login');
    }
    // ❌ Error is already shown by AuthProvider via UI
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SIGN UP',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                
                // 👤 Full Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Ahmad Danial',
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Name required';
                    if (value!.length < 2) return 'Name too short';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // 📧 Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@iium.edu.my',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email required';
                    if (!value!.contains('@')) return 'Valid email required';
                    if (!value.endsWith('.edu.my') && !value.endsWith('.com')) {
                      return 'Use IIUM or valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // 📱 Phone (Optional)
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  hint: '+60123456789',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^\+?[0-9\s\-]{10,}$').hasMatch(value)) {
                        return 'Valid phone number required';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // 🔐 Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '••••••••',
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
                const SizedBox(height: 16),
                
                // 🔐 Confirm Password
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: '••••••••',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please confirm password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // 👥 Role Selection
                const Text(
                  'I am a:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildRoleChip('buyer', '🛒 Buyer'),
                    const SizedBox(width: 12),
                    _buildRoleChip('seller', '🏪 Seller'),
                    const SizedBox(width: 12),
                    _buildRoleChip('donor', '🎁 Donor'),
                  ],
                ),
                const SizedBox(height: 32),
                
                // 🚀 Signup Button
                LoadingButton(
                  text: 'CREATE ACCOUNT',
                  isLoading: authProvider.isLoading,
                  onPressed: authProvider.isLoading ? null : _handleSignup,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(height: 24),
                
                // ❌ Error Message
                if (authProvider.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.error!,
                            style: TextStyle(color: AppColors.error, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // 🔁 Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: Text(
                        'Log in',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 🔐 Terms Notice
                Text(
                  'By signing up, you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 🎨 Reusable Role Chip Widget
  Widget _buildRoleChip(String value, String label) {
    final isSelected = _selectedRole == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedRole = value);
        }
      },
      selectedColor: AppColors.primaryOrange.withOpacity(0.2),
      backgroundColor: AppColors.grayLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primaryOrange : AppColors.grayBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
}