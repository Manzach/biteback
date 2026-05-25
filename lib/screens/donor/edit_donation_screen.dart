import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../models/donation_model.dart';

// ============================================================================
// EDIT DONATION SCREEN
// ============================================================================
// Allows donors to edit existing donation advertisements (UC-06)
// - Pre-fills form with existing donation data
// - Supports photo replacement
// - Validates input before submission
// ============================================================================

class EditDonationScreen extends StatefulWidget {
  final DonationModel donation;
  
  const EditDonationScreen({super.key, required this.donation});

  @override
  State<EditDonationScreen> createState() => _EditDonationScreenState();
}

class _EditDonationScreenState extends State<EditDonationScreen> {
  // ==================================================================
  // FORM CONTROLLERS & STATE
  // ==================================================================
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _quantityController;
  late DateTime _selectedDate;
  
  // Photo state
  File? _selectedPhoto;
  String? _existingPhotoUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    // ✅ Pre-fill form with existing donation data
    _titleController = TextEditingController(text: widget.donation.donationTitle);
    _descriptionController = TextEditingController(text: widget.donation.donationDescription);
    _locationController = TextEditingController(text: widget.donation.pickupLocation);
    _quantityController = TextEditingController(
      text: widget.donation.quantity?.toString() ?? '',
    );
    _selectedDate = widget.donation.availabilityDate ?? DateTime.now();
    _existingPhotoUrl = widget.donation.photoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final donor = context.watch<DonorProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text(
          'Edit Donation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📝 Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 60,
                      color: AppColors.secondaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '"Update your donation details"',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 📋 Edit Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Donation Title
                  _buildInputField(
                    label: 'Donation Title *',
                    controller: _titleController,
                    hint: 'e.g., Extra Food from M Kitchen',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Food Description
                  _buildInputField(
                    label: 'Food Description *',
                    controller: _descriptionController,
                    hint: 'Describe the food items, quantity, packaging, etc.',
                    maxLines: 3,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a description' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quantity (Optional)
                  _buildInputField(
                    label: 'Quantity (Optional)',
                    controller: _quantityController,
                    hint: 'e.g., 10 food packs',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final qty = int.tryParse(v);
                      if (qty == null || qty <= 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Pickup Location
                  _buildInputField(
                    label: 'Pickup Location *',
                    controller: _locationController,
                    hint: 'e.g., KICT Cafe, Mahallah X, etc.',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter pickup location' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Availability Date
                  const Text(
                    'Pickup & Availability Date *',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ==================================================================
                  // 📸 PHOTO SECTION (Edit/Replace)
                  // ==================================================================
                  const Text(
                    'Photo (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  GestureDetector(
                    onTap: _isPickingPhoto ? null : _pickImage,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: _getPhotoPreview(),
                    ),
                  ),
                  
                  if (_selectedPhoto != null || _existingPhotoUrl != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _selectedPhoto = null;
                          _existingPhotoUrl = null;
                        }),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Remove', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Show provider error if any
                  if (donor.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        donor.errorMessage!,
                        style: TextStyle(color: Colors.red[600], fontSize: 12),
                      ),
                    ),
                  
                  // ✅ UPDATE Button with loading state
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (donor.isLoading || _isPickingPhoto) ? null : _submitEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: donor.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'UPDATE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // HELPER: Get Photo Preview (existing or new)
  // ==================================================================
  Widget _getPhotoPreview() {
    if (_selectedPhoto != null) {
      // New photo selected
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_selectedPhoto!, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Text('Tap to change', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ),
        ],
      );
    } else if (_existingPhotoUrl != null) {
      // Existing photo from database
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _existingPhotoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: Text('Tap to replace', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ),
        ],
      );
    } else {
      // No photo - show placeholder
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isPickingPhoto)
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
        else
          const Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
        const SizedBox(height: 8),
        Text(
          _isPickingPhoto ? 'Selecting...' : 'Tap to add photo',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  // ==================================================================
  // HELPER: Build Reusable Input Field
  // ==================================================================
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int? maxLines,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines ?? 1,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          validator: validator,
        ),
      ],
    );
  }

  // ==================================================================
  // HELPER: Date Picker
  // ==================================================================
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ==================================================================
  // HELPER: Pick Image
  // ==================================================================
  Future<void> _pickImage() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
      
      if (source == null || !mounted) return;
      
      setState(() => _isPickingPhoto = true);
      
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (photo != null && mounted) {
        setState(() {
          _selectedPhoto = File(photo.path);
          _existingPhotoUrl = null; // Clear existing URL when new photo selected
        });
      }
    } catch (e) {
      debugPrint('❌ Image picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  // ==================================================================
  // HELPER: Submit Edit Form
  // ==================================================================
  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to edit')),
      );
      return;
    }

    // Parse quantity
    final quantityText = _quantityController.text.trim();
    final int? quantity = quantityText.isEmpty ? null : int.tryParse(quantityText);
    if (quantityText.isNotEmpty && quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Updating donation...'),
          ],
        ),
        backgroundColor: AppColors.primaryOrange,
        duration: Duration(seconds: 3),
      ),
    );

    // Submit to provider
    final donorProvider = context.read<DonorProvider>();
    
    final success = await donorProvider.editDonation(
      donationId: widget.donation.donationId,
      donationTitle: _titleController.text.trim(),
      donationDescription: _descriptionController.text.trim(),
      pickupLocation: _locationController.text.trim(),
      availabilityDate: _selectedDate,
      quantity: quantity,
      photoFile: _selectedPhoto, // Pass new photo if selected
    );

    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation updated successfully! ✅'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(donorProvider.errorMessage ?? 'Failed to update donation'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: donorProvider.clearError,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}