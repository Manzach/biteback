import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ✅ For development: hardcode directly (NEVER commit to Git!)
  static const String _url = 'https://gqgkewzpzvqhkhoxtcmx.supabase.co';  
  static const String _anonKey = 'sb_publishable_QHU9F30bfbFVa7blJoVbNA_Xvypp0m5'; // Publishable key

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
    print('✅ Supabase initialized: $_url'); // Debug print
  }

  static SupabaseClient get client => Supabase.instance.client;
}