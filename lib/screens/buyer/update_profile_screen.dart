import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart'; // ✅ ADD THIS import

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    // ✅ Pre-fill form with current user data from AuthProvider
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _locationController = TextEditingController(text: 'IIUM Campus, Gombak');
  }

  // ==================================================================
  // SAVE PROFILE - WIRED TO PROFILEPROVIDER + SUPABASE
  // ==================================================================
  Future<void> _saveProfile() async {
    // 1. Validate form inputs
    if (!_formKey.currentState!.validate()) return;

    // 2. Get providers
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    
    // 3. Get current user ID (required for update)
    final userId = auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to update profile'), backgroundColor: Colors.red),
      );
      return;
    }

    // 4. Show loading via provider (not local state)
    // ProfileProvider handles isLoading internally
    
    try {
      // 5. Call ProfileProvider to update Supabase
      final success = await profile.updateProfile(
        userId: userId,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        // location is stored locally for now (add to ProfileModel if needed)
      );

      // 6. Handle result (with mounted check for safety)
      if (!mounted) return;

      if (success) {
        // ✅ Success: Show confirmation + refresh AuthProvider so header updates everywhere
        await auth.checkAuthStatus(); // Refresh user data across app
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully! ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Return to previous screen
        Navigator.pop(context);
      } else {
        // ❌ Failure: Show error from provider with retry option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profile.errorMessage ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: profile.clearError,
            ),
          ),
        );
      }
    } catch (e) {
      // 🚨 Unexpected error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Watch ProfileProvider for loading/error state
    final profile = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text('Update Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              _buildField('Full Name', _nameController, 'Enter your full name'),
              const SizedBox(height: 16),
              _buildField('Phone Number', _phoneController, 'e.g., 018 245 1670', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField('Location / Address', _locationController, 'e.g., Block D, Mahallah As-Siddiq'),
              
              const SizedBox(height: 32),
              
              // ✅ SAVE Button with provider loading state
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  // Disable button while provider is loading
                  onPressed: profile.isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: profile.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              // ✅ Show provider error message below button if any
              if (profile.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  profile.errorMessage!,
                  style: TextStyle(color: Colors.red[600], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: profile.clearError,
                    child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================================
  // HELPER: Build Reusable Input Field
  // ==================================================================
  Widget _buildField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}