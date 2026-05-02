import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🔐 Config & Services
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';

// 🎨 Design System
import 'config/app_colors.dart';

// 🖥️ Screens
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';  
import 'screens/home/home_screen.dart';  // ← ADD THIS IMPORT


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Supabase
  await SupabaseConfig.initialize();
  
  // 2. Create service + provider
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
        ChangeNotifierProvider.value(value: authProvider),
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
          '/signup': (context) => const SignupScreen(),  // ✅ ADDED
          '/home': (context) => const HomeScreen(),       // Day 2: HomeScreen
          '/forgot-password': (context) => const Placeholder(),
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