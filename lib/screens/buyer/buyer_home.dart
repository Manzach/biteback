import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class BuyerHome extends StatelessWidget {
  const BuyerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: AppColors.primaryOrange,
            title: const Text('🛒 Browse Food', style: TextStyle(color: Colors.white)),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {/* TODO: Open cart */},
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Near You',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // TODO: Replace with real food list
                  _buildPlaceholderCard('🍎 Fresh Fruits - 50% off', 'IIUM Cafeteria'),
                  _buildPlaceholderCard('🥪 Sandwiches - Near Expiry', 'Kulliyyah Store'),
                  _buildPlaceholderCard('🥤 Drinks Bundle', 'Student Hub'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(String title, String location) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(location, style: TextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {/* TODO: Navigate to item detail */},
      ),
    );
  }
}