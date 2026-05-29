// FILE: lib/screens/buyer/all_donations_screen.dart
// ============================================================================
// ALL DONATIONS SCREEN
// ============================================================================
// Displays all active donation advertisements with search & filter capabilities
// Uses client-side filtering via BuyerProvider.donations
// Aligns with FYP Report: UC-07, Table 8, Table 13, Figure 41
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/buyer_provider.dart';
import '../../models/donation_model.dart';
import 'donation_detail_screen.dart';

class AllDonationsScreen extends StatefulWidget {
  const AllDonationsScreen({super.key});

  @override
  State<AllDonationsScreen> createState() => _AllDonationsScreenState();
}

class _AllDonationsScreenState extends State<AllDonationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // ✅ Load donations if not already fetched by BuyerHome
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BuyerProvider>();
      if (provider.donations.isEmpty && (provider.isLoadingDonations != true)) {
        provider.loadDonations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================================================================
  // 🔍 CLIENT-SIDE SEARCH FILTER - FIXED FIELD NAMES
  // ==================================================================
  /// Filters donations by title, description, or pickup location
  /// Uses correct field names from DonationModel (per FYP Report Table 13)
  List<DonationModel> get _filteredDonations {
    final allDonations = context.read<BuyerProvider>().donations;
    
    if (_searchQuery.isEmpty) return allDonations;
    
    final query = _searchQuery.toLowerCase().trim();
    return allDonations.where((donation) {
      // ✅ Use correct field names from DonationModel:
      // - donationTitle (not 'title')
      // - donationDescription (not 'description') 
      // - pickupLocation (not 'location')
      final titleMatch = donation.donationTitle?.toLowerCase().contains(query) ?? false;
      final descMatch = donation.donationDescription?.toLowerCase().contains(query) ?? false;
      final locationMatch = donation.pickupLocation?.toLowerCase().contains(query) ?? false;
      
      return titleMatch || descMatch || locationMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuyerProvider>();
    final filteredDonations = _filteredDonations;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryGreen,
        title: const Text(
          'All Donations',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by title, location, or description...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),

          // ✅ Listing Count Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredDonations.length} donation(s) found',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                if (_searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),

          // ✅ Donations List
          Expanded(
            child: provider.isLoadingDonations == true
                ? const Center(child: CircularProgressIndicator())
                : provider.donationErrorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                provider.donationErrorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => provider.refreshDonations(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredDonations.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                _searchQuery.isEmpty
                                    ? 'No donations available. 🎁\nCheck back soon!'
                                    : 'No results for "${_searchQuery}"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.refreshDonations(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredDonations.length,
                              itemBuilder: (context, index) {
                                final donation = filteredDonations[index];
                                return _buildDonationCard(donation);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // 🎁 DONATION CARD BUILDER - FIXED FIELD NAMES
  // ==================================================================
  Widget _buildDonationCard(DonationModel donation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DonationDetailScreen(donation: donation),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image / Placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: donation.photoUrl?.isNotEmpty == true
                    ? Image.network(
                        donation.photoUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Use donationTitle (not 'title')
                    Text(
                      donation.donationTitle ?? 'Food Donation',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // ✅ Use donationDescription (not 'description')
                    Text(
                      donation.donationDescription ?? 'No description provided',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            // ✅ Use pickupLocation (not 'location')
                            donation.pickupLocation ?? 'Campus Location',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          // ✅ Use datePosted (not 'createdAt')
                          donation.datePosted != null 
                              ? '${donation.datePosted!.day}/${donation.datePosted!.month}/${donation.datePosted!.year}'
                              : 'Date N/A',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (donation.quantity != null && donation.quantity! > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${donation.quantity} pack(s) available',
                        style: TextStyle(fontSize: 11, color: AppColors.secondaryGreen, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (donation.isAvailable ?? false) ? Colors.green[100] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (donation.isAvailable ?? false) ? '✓ Available' : '✗ Taken',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: (donation.isAvailable ?? false) ? Colors.green[800] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================================
  // HELPER: Placeholder Widget
  // ==================================================================
  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.secondaryGreen.withOpacity(0.1),
      child: const Icon(Icons.volunteer_activism, color: AppColors.secondaryGreen, size: 30),
    );
  }
}