import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class SellerHome extends StatelessWidget {
  const SellerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {/* TODO: Open create listing */},
        backgroundColor: AppColors.secondaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.secondaryGreen,
            title: const Text('🏪 My Listings', style: TextStyle(color: Colors.white)),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart, color: Colors.white),
                onPressed: () {/* TODO: Open analytics */},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Listings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // TODO: Replace with real listings
                  _buildListingCard('🥗 Salad Boxes', '3 available', 'Expires: 2h'),
                  _buildListingCard('🍞 Bread Loaves', '12 available', 'Expires: 5h'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(String title, String available, String expiry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(available, style: TextStyle(color: Colors.grey[700])),
            Text(expiry, style: const TextStyle(color: Colors.orange, fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () {/* TODO: Edit listing */},
      ),
    );
  }
}