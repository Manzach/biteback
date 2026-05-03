import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class DonorHome extends StatelessWidget {
  const DonorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {/* TODO: Open post donation */},
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.volunteer_activism, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.blueAccent,
            title: const Text('🎁 My Donations', style: TextStyle(color: Colors.white)),
            floating: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Donation History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // TODO: Replace with real donations
                  _buildDonationCard('🍲 20 Meals Donated', 'Accepted by IIUM Charity', '2 days ago'),
                  _buildDonationCard('🥫 Canned Goods Bundle', 'Picked up', '1 week ago'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(String title, String status, String date) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$status • $date', style: TextStyle(color: Colors.grey[600])),
        trailing: Icon(
          status == 'Picked up' ? Icons.check_circle : Icons.pending,
          color: status == 'Picked up' ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}