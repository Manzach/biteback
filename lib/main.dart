import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ============================================================================
// CONFIG & SERVICES
// ============================================================================
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/order_service.dart';
import 'services/seller_service.dart';
import 'services/admin_service.dart'; // ✅ ADD THIS

// ============================================================================
// PROVIDERS (State Management)
// ============================================================================
import 'providers/auth_provider.dart';
import 'providers/buyer_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/donor_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/order_provider.dart';
import 'providers/seller_provider.dart';
import 'providers/admin_provider.dart'; // ✅ ADD THIS
// import 'providers/admin_provider.dart';  // TODO: Uncomment when admin module is ready

// ============================================================================
// DESIGN SYSTEM
// ============================================================================
import 'config/app_colors.dart';

// ============================================================================
// AUTH SCREENS
// ============================================================================
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';

// ============================================================================
// MAIN DASHBOARD
// ============================================================================
import 'screens/home/home_screen.dart';

// ============================================================================
// BUYER SCREENS (UC-04, UC-07)
// ============================================================================
import 'screens/buyer/buyer_home.dart';
import 'screens/buyer/listing_detail_screen.dart';
import 'screens/buyer/order_success_screen.dart';
import 'screens/buyer/cart_screen.dart';
import 'screens/buyer/checkout_confirmation_screen.dart';
import 'screens/buyer/order_history_screen.dart';
import 'screens/buyer/active_order_screen.dart';
import 'screens/buyer/profile_screen.dart';

// ============================================================================
// SELLER SCREENS (UC-05)
// ============================================================================
import 'screens/seller/seller_home.dart';
import 'screens/seller/create_listing_screen.dart';
import 'screens/seller/order_collection_screen.dart';

// ============================================================================
// DONOR SCREENS (UC-06)
// ============================================================================
import 'screens/donor/donor_home.dart';
import 'screens/donor/create_donation_screen.dart';

// ============================================================================
// ADMIN SCREENS (UC-08)
// ============================================================================
import 'screens/admin/admin_home.dart'; // ✅ ADD THIS
// import 'screens/admin/admin_home.dart';  // TODO: Uncomment when admin module is ready

// ============================================================================
// APP ENTRY POINT
// ============================================================================
/// Initializes Supabase, auth, and providers before launching the app
/// Aligns with FYP Report: Figure 26 (System Architecture), Section 4.2
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 1. Initialize Supabase backend
    await SupabaseConfig.initialize();
    
    // 2. Create auth service + provider
    final authService = AuthService(SupabaseConfig.client);
    final authProvider = AuthProvider(authService);
    
    // 3. Check auth state BEFORE showing UI (prevents flicker)
    await authProvider.checkAuthStatus();
    
    // 4. Launch app with initialized providers
    runApp(MyApp(authProvider: authProvider));
    
  } catch (e) {
    // Fallback UI if Supabase fails to initialize
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to connect to server.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your internet connection.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => main(), // Retry
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ROOT WIDGET
// ============================================================================
/// Configures MultiProvider, MaterialApp theme, and routing
/// Uses RoleRouter logic (via HomeScreen) for role-based navigation
class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  
  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🔐 Auth Provider (pre-initialized to preserve session)
        ChangeNotifierProvider.value(value: authProvider),
        
        // 🛒 Buyer Provider - manages listings, orders, QR flow (UC-04, UC-07)
        ChangeNotifierProvider(create: (_) => BuyerProvider()),
        
        // 🛍️ Cart Provider - manages cart items, checkout, multi-location QR
        ChangeNotifierProvider(create: (_) => CartProvider()),
        
        // 👤 Profile Provider - manages buyer profile updates (UC-02)
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(
            ProfileService(SupabaseConfig.client),
          ),
        ),
        
        // 📦 Order Provider - manages order history & active order (UC-04)
        ChangeNotifierProvider(
          create: (_) => OrderProvider(
            OrderService(SupabaseConfig.client),
          ),
        ),
        
        // 🏪 Seller Provider - manages food listings & QR collection (UC-05)
        ChangeNotifierProvider(
          create: (_) => SellerProvider(
            SellerService(),
          ),
        ),
        
        // 🎁 Donor Provider - manages donation advertisements (UC-06)
        ChangeNotifierProvider(create: (_) => DonorProvider()),
        
        // 🛡️ Admin Provider - manages moderation & monitoring (UC-08) ✅ ADD THIS
        ChangeNotifierProvider(
          create: (_) => AdminProvider(
            AdminService(SupabaseConfig.client),
          ),
        ),
        
        // ⚙️ Admin Provider - TODO: Uncomment when admin module is complete
        // ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'BiteBack',
        debugShowCheckedModeBanner: false,
        
        // 🎨 Theme - Matches Figma prototype (Figure 35-42)
        theme: ThemeData(
          primaryColor: AppColors.primaryOrange,
          scaffoldBackgroundColor: AppColors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryOrange,
            secondary: AppColors.secondaryGreen,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          useMaterial3: true,
        ),
        
        // 🧭 Navigation Routes
        initialRoute: '/',
        routes: {
          // Auth Flow
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          
          // Main Dashboard (role-aware via HomeScreen)
          '/home': (context) => const HomeScreen(),
          '/forgot-password': (context) => const Placeholder(),
          
          // ✅ BUYER ROUTES (UC-04: Purchase, UC-07: View Donations)
          '/buyer/home': (context) => const BuyerHome(),
          '/cart': (context) => const CartScreen(),
          '/buyer/order-history': (context) => const OrderHistoryScreen(),
          '/buyer/active-order': (context) => const ActiveOrderScreen(),
          '/buyer/profile': (context) => const ProfileScreen(),
          
          // ✅ SELLER ROUTES (UC-05: Manage Food Listing)
          '/seller/home': (context) => const SellerHome(),
          
          // ✅ DONOR ROUTES (UC-06: Publish Donation)
          '/donor/home': (context) => const DonorHome(),
          
          // ✅ ADMIN ROUTES (UC-08: Monitor & Moderate) ✅ ADD THIS
          '/admin/home': (context) => const AdminHome(),
          
          // ⚙️ ADMIN ROUTES - TODO: Uncomment when module is complete
          // '/admin/home': (context) => const AdminHome(),
          
          // ️ Placeholder routes for screens that require constructor data
          // These prevent crashes if accidentally navigated via named route
          '/buyer/listing-detail': (context) => const _PlaceholderScreen(
            message: 'Use Navigator.push for listing detail (requires FoodListing)',
          ),
          '/buyer/order-success': (context) => const _PlaceholderScreen(
            message: 'Use Navigator.push for order success (requires grouped orders)',
          ),
          '/buyer/checkout': (context) => const _PlaceholderScreen(
            message: 'Use Navigator.push for checkout (requires CartProvider)',
          ),
          '/donor/create': (context) => const _PlaceholderScreen(
            message: 'Use Navigator.push for create donation (requires form data)',
          ),
          '/seller/create-listing': (context) => const _PlaceholderScreen(
            message: 'Use Navigator.push for create listing (requires form data)',
          ),
        },
        
        // 🚫 Handle unknown routes gracefully (prevents white screen crashes)
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Page not found: ${settings.name}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    ),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HELPER: Placeholder Screen for Data-Dependent Routes
// ============================================================================
/// Displays a friendly message when a route requiring constructor data
/// is accidentally accessed via named navigation.
/// Prevents runtime crashes during development.
class _PlaceholderScreen extends StatelessWidget {
  final String message;
  const _PlaceholderScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Note')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}