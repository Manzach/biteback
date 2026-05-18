import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔐 Config & Services
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/buyer_provider.dart'; // ✅ Buyer state management
import 'services/auth_service.dart';

// 🎨 Design System
import 'config/app_colors.dart';

// 🖥️ Screens
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';  
import 'screens/home/home_screen.dart';

// 🛒 Buyer Screens
import 'screens/buyer/buyer_home.dart';
import 'screens/buyer/listing_detail_screen.dart';
import 'screens/buyer/order_success_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Supabase
  await SupabaseConfig.initialize();
  
  // 2. Create services + providers
  final authService = AuthService(SupabaseConfig.client);
  final authProvider = AuthProvider(authService);
  
  // 3. Check auth state BEFORE showing UI
  await authProvider.checkAuthStatus();
  
  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  
  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth provider (already initialized)
        ChangeNotifierProvider.value(value: authProvider),
        
        // ✅ Buyer provider - manages listings, orders, QR flow
        ChangeNotifierProvider(create: (_) => BuyerProvider()),
      ],
      child: MaterialApp(
        title: 'BiteBack',
        debugShowCheckedModeBanner: false,
        
        // 🎨 Theme - Matches Figma
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
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/forgot-password': (context) => const Placeholder(),
          
          // ✅ BUYER ROUTES
          '/buyer/home': (context) => const BuyerHome(),
          
          // Note: Screens that need data (listing, order) use Navigator.push
          // These placeholders prevent crashes if accidentally navigated via named route
          '/buyer/listing-detail': (context) => const _PlaceholderScreen(
            message: 'Use Navigator.push for listing detail (requires FoodListingModel)',
          ),
          '/buyer/order-success': (context) => const _PlaceholderScreen(
            message: 'Use Navigator.push for order success (requires OrderModel)',
          ),
        },
        
        // 🚫 Handle unknown routes gracefully
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        ),
      ),
    );
  }
}

// ✅ Helper widget for placeholder routes
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
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}