import 'package:flutter/material.dart';
import '../../models/donation_model.dart';
import '../../config/app_colors.dart';

class DonationDetailScreen extends StatelessWidget {
  final DonationModel donation;
  const DonationDetailScreen({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        title: const Text('Donation Details', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Donation Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: donation.photoUrl?.isNotEmpty == true
                  ? Image.network(
                      donation.photoUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.volunteer_activism,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.volunteer_activism,
                        size: 60,
                        color: AppColors.secondaryGreen,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // 📝 Donation Title
            Text(
              donation.donationTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 8),

            // 🏷️ Availability Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: donation.availabilityStatus == 'Available'
                    ? Colors.green[100]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                donation.availabilityStatus,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: donation.availabilityStatus == 'Available'
                      ? Colors.green[800]
                      : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📋 Description Section
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              donation.donationDescription,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // 📦 Quantity (if available)
            if (donation.quantity != null) ...[
              const Text(
                'Quantity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${donation.quantity} pack${donation.quantity! > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
            ],

            // 📍 Pickup Location
            const Text(
              'Pickup Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    donation.pickupLocation,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 📅 Date Posted
            const Text(
              'Posted On',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${donation.datePosted.day}/${donation.datePosted.month}/${donation.datePosted.year}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),

            // 📅 Availability Date (if available)
            if (donation.availabilityDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Available: ${donation.availabilityDate!.day}/${donation.availabilityDate!.month}/${donation.availabilityDate!.year}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 32),

            // 📞 Contact/Claim Button
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact donor feature coming soon!'),
                    backgroundColor: AppColors.primaryOrange,
                  ),
                );
              },
              icon: const Icon(Icons.mail_outline),
              label: const Text('Contact Donor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryGreen,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}