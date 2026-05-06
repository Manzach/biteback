import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/app_colors.dart';
import '../../models/food_listing_model.dart';
import '../../services/seller_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _foodNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();

  File? _selectedImage;
  DateTime? _selectedExpiryDate;
  bool _isLoading = false;
  String? _errorMessage;

  final _sellerService = SellerService();
  final _imagePicker = ImagePicker();

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

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  bool _validateForm() {
    if (_foodNameController.text.isEmpty) {
      _showError('Please enter food name');
      return false;
    }

    if (_originalPriceController.text.isEmpty ||
        double.tryParse(_originalPriceController.text) == null) {
      _showError('Please enter valid original price');
      return false;
    }

    if (_discountedPriceController.text.isEmpty ||
        double.tryParse(_discountedPriceController.text) == null) {
      _showError('Please enter valid discounted price');
      return false;
    }

    if (_quantityController.text.isEmpty ||
        int.tryParse(_quantityController.text) == null) {
      _showError('Please enter valid quantity');
      return false;
    }

    if (_selectedExpiryDate == null) {
      _showError('Please select expiry date');
      return false;
    }

    if (_locationController.text.isEmpty) {
      _showError('Please enter location');
      return false;
    }

    if (_selectedImage == null) {
      _showError('Please upload a photo');
      return false;
    }

    final original = double.parse(_originalPriceController.text);
    final discounted = double.parse(_discountedPriceController.text);

    if (discounted >= original) {
      _showError('Discounted price must be less than original price');
      return false;
    }

    if (_selectedExpiryDate!.isBefore(DateTime.now())) {
      _showError('Expiry date must be in the future');
      return false;
    }

    return true;
  }

  void _showError(String message) {
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

  Future<void> _submitListing() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final photoUrl = await _sellerService.uploadListingPhoto(
        _selectedImage!.path,
        fileName,
      );

      if (photoUrl == null) {
        throw Exception('Failed to upload photo');
      }

      final listing = await _sellerService.createListing(
        foodName: _foodNameController.text.trim(),
        description: _descriptionController.text.trim(),
        originalPrice: double.parse(_originalPriceController.text),
        discountedPrice: double.parse(_discountedPriceController.text),
        quantity: int.parse(_quantityController.text),
        expiryDate: _selectedExpiryDate!,
        location: _locationController.text.trim(),
        photoUrl: photoUrl,
      );

      if (listing == null) {
        throw Exception('Failed to create listing');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing created successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, listing);
      }
    } catch (e) {
      _showError('Error creating listing: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryGreen,
        title: const Text(
          'Create New Listing',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading your listing...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELL YOUR NEAR EXPIRED FOOD HERE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Turn near-expired food into affordable meals for others.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[900], fontSize: 12),
                      ),
                    ),
                  if (_errorMessage != null) const SizedBox(height: 16),

                  _buildFormField(
                    label: 'Food Name',
                    controller: _foodNameController,
                    hint: 'e.g., Gardenia Squiggles',
                  ),

                  _buildFormField(
                    label: 'Description (Optional)',
                    controller: _descriptionController,
                    hint: 'Add any details about the food',
                    maxLines: 3,
                  ),

                  _buildFormField(
                    label: 'Original Price (RM)',
                    controller: _originalPriceController,
                    hint: 'e.g., 5.50',
                    keyboardType: TextInputType.number,
                  ),

                  _buildFormField(
                    label: 'Discounted Price (RM)',
                    controller: _discountedPriceController,
                    hint: 'e.g., 1.00',
                    keyboardType: TextInputType.number,
                  ),

                  _buildFormField(
                    label: 'Quantity',
                    controller: _quantityController,
                    hint: 'Number of items',
                    keyboardType: TextInputType.number,
                  ),

                  const Text(
                    'Expiry Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectExpiryDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedExpiryDate == null
                            ? 'Tap to select date'
                            : '${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedExpiryDate == null
                              ? Colors.grey[600]
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFormField(
                    label: 'Location',
                    controller: _locationController,
                    hint: 'e.g., Mahallah Siddiq Coop',
                  ),

                  const Text(
                    'Upload Photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: _selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 40,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to upload photo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                      child: Text(
                        _isLoading ? 'UPLOADING...' : 'UPLOAD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

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
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}