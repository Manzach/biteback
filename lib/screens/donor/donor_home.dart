import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../models/donation_model.dart';
import 'create_donation_screen.dart';
import 'edit_donation_screen.dart'; // ✅ ADD THIS for edit navigation

// ============================================================================
// DONOR HOME SCREEN
// ============================================================================
// Main dashboard for Donors (UC-06: Publish Donation Advertisement)
// - View donation statistics (Total, Active)
// - Post new donation advertisements
// - Manage existing donations (Edit, Delete)
// NOTE: Donors cannot mark donations as "Collected" - this is handled by buyers picking up
// Aligns with FYP Report: Table 13 (Donation table), Figure 40 (Donor Flow)
// ============================================================================

class DonorHome extends StatefulWidget {
  const DonorHome({super.key});

  @override
  State<DonorHome> createState() => _DonorHomeState();
}

class _DonorHomeState extends State<DonorHome> {
  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<DonorProvider>().loadMyDonations(userId);
      }
    });
  }

  // ==========================================================================
  // MAIN BUILD METHOD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final donor = context.watch<DonorProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text(
          'Donate Food',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Column(
        children: [
          // ==================================================================
          // 📊 STATS BANNER
          // ==================================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.secondaryGreen.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('📦', '${donor.myDonations.length}', 'Total'),
                _buildStatCard('✅', '${donor.activeDonationsCount}', 'Active'),
              ],
            ),
          ),

          // ==================================================================
          // ➕ POST NEW DONATION BUTTON
          // ==================================================================
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateDonationScreen()),
                );
                final userId = auth.currentUser?.id;
                if (userId != null) {
                  donor.loadMyDonations(userId);
                }
              },
              icon: const Icon(Icons.add_circle, size: 22),
              label: const Text(
                'Post Food Donation',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const Divider(),

          // ==================================================================
          // 📋 MY DONATIONS LIST
          // ==================================================================
          Expanded(
            child: donor.isLoading
                ? const Center(child: CircularProgressIndicator())
                : donor.errorMessage != null
                    ? _buildErrorState(donor, auth)
                    : donor.myDonations.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: donor.myDonations.length,
                            itemBuilder: (context, index) {
                              final donation = donor.myDonations[index];
                              return _buildDonationCard(donation, donor);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // HELPER: Build Stat Card Widget
  // ==================================================================
  Widget _buildStatCard(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryOrange,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // ==================================================================
  // HELPER: Build Error State Widget
  // ==================================================================
  Widget _buildErrorState(DonorProvider donor, AuthProvider auth) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              donor.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final userId = auth.currentUser?.id;
                if (userId != null) {
                  donor.loadMyDonations(userId);
                  donor.clearError();
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // HELPER: Build Empty State Widget
  // ==================================================================
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No donations posted yet',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            'Share extra food with those in need!',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // 🎁 DONATION CARD BUILDER (UC-06: Manage Donation Advertisement)
  // ==================================================================
  // Displays individual donation card with:
  // - Title, location, description
  // - Status badge (Available/Unavailable)
  // - Action buttons: ✏️ Edit + 🗑️ Delete
  // ==================================================================
  Widget _buildDonationCard(DonationModel donation, DonorProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Icon + Details + Status Badge
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: donation.photoUrl?.isNotEmpty == true
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            donation.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.volunteer_activism,
                              color: AppColors.secondaryGreen,
                              size: 26,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.volunteer_activism,
                          color: AppColors.secondaryGreen,
                          size: 26,
                        ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.donationTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📍 ${donation.pickupLocation}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: donation.availabilityStatus == 'Available'
                        ? Colors.green[100]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    donation.availabilityStatus,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: donation.availabilityStatus == 'Available'
                          ? Colors.green[800]
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              donation.donationDescription,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // ✅ Action Buttons: Edit + Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ✏️ Edit Button (NEW)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                  onPressed: () => _navigateToEditScreen(context, donation),
                  tooltip: 'Edit donation',
                ),
                
                // 🗑️ Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _confirmDelete(
                    context,
                    donation.donationTitle,
                    () => provider.deleteDonation(donation.donationId),
                  ),
                  tooltip: 'Delete donation',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // ✅ HELPER: Navigate to Edit Screen
  // ==================================================================
  // Opens EditDonationScreen with pre-filled donation data
  // Parameters:
  //   - context: BuildContext for navigation
  //   - donation: DonationModel to edit
  // ==================================================================
  void _navigateToEditScreen(BuildContext context, DonationModel donation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditDonationScreen(donation: donation),
      ),
    );
  }

// ==================================================================
// HELPER: Show Logout Confirmation Dialog
// ==================================================================
void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent accidental dismiss
    builder: (_) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Just close dialog
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // 1. Close dialog first
            Navigator.pop(context);
            
            // 2. Show loading indicator
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Signing out...'),
                backgroundColor: AppColors.primaryOrange,
                duration: Duration(seconds: 1),
              ),
            );
            
            // 3. Sign out via AuthProvider
            await context.read<AuthProvider>().signOut();
            
            // 4. Navigate to login screen (replace all routes)
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false, // Remove all previous routes
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );
}

  // ==================================================================
  // HELPER: Confirm Delete Donation
  // ==================================================================
  void _confirmDelete(
    BuildContext context,
    String title,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Donation'),
        content: Text('Remove "$title"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}