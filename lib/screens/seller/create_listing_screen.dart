// FILE: lib/screens/seller/create_listing_screen.dart
// ============================================================================
// CREATE/EDIT LISTING SCREEN
// ============================================================================
// Handles both creating new food listings and editing existing ones (UC-05)
// - Pre-fills form when editing existing listing
// - Uploads images to Supabase Storage
// - Calls createListing() or updateListing() based on mode
// - Returns FoodListing object for parent refresh
// Aligns with FYP Report: Table 11, UC-05, Figure 39
// ============================================================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import '../../config/app_colors.dart';
import '../../models/food_listing_model.dart';
import '../../services/seller_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seller_provider.dart';

class CreateListingScreen extends StatefulWidget {
  // ✅ null = create mode, not null = edit mode
  final FoodListing? listing;

  const CreateListingScreen({super.key, this.listing});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  // Form controllers - match FoodListing field names
  final _foodNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();

  // State variables
  File? _selectedImage;
  String? _existingPhotoUrl; // ✅ Match model: photoUrl (not imageUrl)
  DateTime? _expiryDate;
  bool _isLoading = false;
  String? _errorMessage;

  // Services
  final _sellerService = SellerService();
  final _imagePicker = ImagePicker();

  // ✅ Track edit mode
  late final bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.listing != null;

    // ✅ Pre-fill form if editing existing listing
    if (_isEditing && widget.listing != null) {
      final listing = widget.listing!;
      _foodNameController.text = listing.foodName;
      _descriptionController.text = listing.description;
      _originalPriceController.text = listing.originalPrice.toStringAsFixed(2);
      _discountedPriceController.text = listing.discountedPrice.toStringAsFixed(2);
      _quantityController.text = listing.quantity.toString();
      _locationController.text = listing.location;
      _expiryDate = listing.expiryDate;
      _existingPhotoUrl = listing.photoUrl;
    } else {
      // Default expiry date for new listings (tomorrow)
      _expiryDate = DateTime.now().add(const Duration(days: 1));
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ==================================================================
  // SELECT EXPIRY DATE
  // ==================================================================
  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 1)),
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
        _expiryDate = picked;
      });
    }
  }

  // ==================================================================
  // PICK IMAGE FROM GALLERY
  // ==================================================================
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = null;
          // ✅ When new image selected, clear existing URL
          _existingPhotoUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error picking image: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================================================================
  // FORM VALIDATION
  // ==================================================================
  bool _validateForm() {
    if (_foodNameController.text.trim().isEmpty) {
      _showError('Please enter food name');
      return false;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please enter description');
      return false;
    }

    if (_originalPriceController.text.isEmpty ||
        double.tryParse(_originalPriceController.text) == null ||
        double.parse(_originalPriceController.text) <= 0) {
      _showError('Please enter valid original price');
      return false;
    }

    if (_discountedPriceController.text.isEmpty ||
        double.tryParse(_discountedPriceController.text) == null ||
        double.parse(_discountedPriceController.text) <= 0) {
      _showError('Please enter valid discounted price');
      return false;
    }

    if (_quantityController.text.isEmpty ||
        int.tryParse(_quantityController.text) == null ||
        int.parse(_quantityController.text) <= 0) {
      _showError('Please enter valid quantity');
      return false;
    }

    if (_locationController.text.trim().isEmpty) {
      _showError('Please enter pickup location');
      return false;
    }

    if (_expiryDate == null) {
      _showError('Please select expiry date');
      return false;
    }

    // ✅ Image is optional when editing (can keep existing)
    if (!_isEditing && _selectedImage == null && _existingPhotoUrl == null) {
      _showError('Please upload a photo');
      return false;
    }

    final original = double.parse(_originalPriceController.text);
    final discounted = double.parse(_discountedPriceController.text);

    if (discounted >= original) {
      _showError('Discounted price must be less than original price');
      return false;
    }

    if (_expiryDate!.isBefore(DateTime.now())) {
      _showError('Expiry date must be in the future');
      return false;
    }

    return true;
  }

  // ==================================================================
  // SHOW ERROR MESSAGE
  // ==================================================================
  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================================================================
  // SUBMIT LISTING (Create OR Edit)
  // ==================================================================
  Future<void> _submitListing() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ✅ Get seller ID from auth provider
      final sellerId = context.read<AuthProvider>().currentUser?.id;
      if (sellerId == null) {
        throw Exception('User not authenticated');
      }

      // ✅ Handle image upload
      String? photoUrl = _existingPhotoUrl;

      if (_selectedImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        photoUrl = await _sellerService.uploadListingPhoto(
          _selectedImage!.path,
          fileName,
        );

        if (photoUrl == null) {
          throw Exception('Failed to upload photo');
        }
      }

      FoodListing? resultListing;

      if (_isEditing && widget.listing != null) {
        // ✅ EDIT MODE: Call updateListing with correct field names
        resultListing = await _sellerService.updateListing(
          listingId: widget.listing!.id,
          foodName: _foodNameController.text.trim(),
          description: _descriptionController.text.trim(),
          originalPrice: double.parse(_originalPriceController.text),
          discountedPrice: double.parse(_discountedPriceController.text),
          quantity: int.parse(_quantityController.text),
          expiryDate: _expiryDate!,
          location: _locationController.text.trim(),
          photoUrl: photoUrl, // ✅ Pass photoUrl for image updates
        );
      } else {
        // ✅ CREATE MODE: Call createListing
        resultListing = await _sellerService.createListing(
          foodName: _foodNameController.text.trim(),
          description: _descriptionController.text.trim(),
          originalPrice: double.parse(_originalPriceController.text),
          discountedPrice: double.parse(_discountedPriceController.text),
          quantity: int.parse(_quantityController.text),
          expiryDate: _expiryDate!,
          location: _locationController.text.trim(),
          photoUrl: photoUrl ?? '',
        );
      }

      // ✅ Return the FoodListing object to parent
      if (resultListing != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Listing updated successfully! ✏️'
                : 'Listing created successfully! 🎉'),
            backgroundColor: AppColors.secondaryGreen,
          ),
        );
        // ✅ FIX: Return FoodListing object, NOT bool
        Navigator.pop(context, resultListing);
      } else if (!mounted) {
        throw Exception(_isEditing ? 'Update failed' : 'Create failed');
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================================================================
  // BUILD FORM FIELD WIDGET
  // ==================================================================
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ==================================================================
  // BUILD IMAGE PICKER WIDGET
  // ==================================================================
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Photo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // ✅ Show existing image when editing
        if (_isEditing && _existingPhotoUrl != null && _selectedImage == null)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.secondaryGreen!,
                  width: 2,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _existingPhotoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primaryOrange,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Image not available',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Overlay with "Tap to change" hint
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Change Photo',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // ✅ Normal image picker for create or when changing image
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            size: 32,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload photo',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Recommended: 1200x800px',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Cancel',
        ),
        title: Text(
          _isEditing ? 'Edit Listing' : 'Create New Listing',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _showDeleteDialog(),
              tooltip: 'Delete Listing',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryOrange),
                  const SizedBox(height: 16),
                  Text(
                    _isEditing ? 'Updating listing...' : 'Creating listing...',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    _isEditing
                        ? 'Update your food listing'
                        : 'List your near-expiry food',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isEditing
                        ? 'Make changes to your existing listing'
                        : 'Turn surplus food into affordable meals',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message banner
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[800], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_errorMessage != null) const SizedBox(height: 16),

                  // Form Fields
                  _buildFormField(
                    label: 'Food Name *',
                    controller: _foodNameController,
                    hint: 'e.g., Gardenia Squiggles Bread',
                  ),

                  _buildFormField(
                    label: 'Description *',
                    controller: _descriptionController,
                    hint: 'Describe the food item, condition, etc.',
                    maxLines: 3,
                  ),

                  // Price Row
                  const Text(
                    'Pricing *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: 'Original Price (RM)',
                          controller: _originalPriceController,
                          hint: '10.00',
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: 'Discounted Price (RM)',
                          controller: _discountedPriceController,
                          hint: '7.00',
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),

                  _buildFormField(
                    label: 'Available Quantity *',
                    controller: _quantityController,
                    hint: 'e.g., 5',
                    keyboardType: TextInputType.number,
                  ),

                  _buildFormField(
                    label: 'Pickup Location *',
                    controller: _locationController,
                    hint: 'e.g., Mahallah Siddiq Kitchen',
                  ),

                  // Expiry Date Picker
                  const Text(
                    'Expiry Date *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectExpiryDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.primaryOrange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select expiry date',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  _expiryDate != null
                                      ? dateFormat.format(_expiryDate!)
                                      : 'Tap to select',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image Picker
                  _buildImagePicker(),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primaryOrange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isEditing
                                ? 'Changes will be visible to buyers immediately after saving.'
                                : 'Your listing will be visible to buyers once published.',
                            style: TextStyle(
                              color: AppColors.primaryOrange.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                      child: Text(
                        _isLoading
                            ? 'SAVING...'
                            : (_isEditing ? 'UPDATE LISTING' : 'PUBLISH LISTING'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ==================================================================
  // SHOW DELETE CONFIRMATION DIALOG (Edit Mode Only)
  // ==================================================================
  void _showDeleteDialog() {
    if (!_isEditing || widget.listing == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${widget.listing!.foodName}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ This action cannot be undone. The listing will be permanently removed.',
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
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
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                final success = await _sellerService.deleteListing(widget.listing!.id);

                if (mounted) {
                  setState(() => _isLoading = false);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Listing deleted successfully'),
                        backgroundColor: AppColors.secondaryGreen,
                      ),
                    );
                    // Return null to indicate deletion
                    Navigator.pop(context, null);
                  } else {
                    _showError('Failed to delete listing');
                  }
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  _showError('Error: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}