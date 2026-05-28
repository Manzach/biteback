// FILE: lib/services/report_service.dart
// ============================================================================
// REPORT SERVICE
// ============================================================================
// Handles Supabase database operations for issue reports (UC-08)
// - Create reports from buyers/sellers/donors
// - Fetch pending reports for admin moderation
// - Update report status (resolved/dismissed)
// Aligns with FYP Report: Table 14 (Admin Log), UC-08
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ReportService {
  final SupabaseClient _client;

  ReportService(this._client);

  // ==================================================================
  // CREATE REPORT (Buyer/Seller/Donor) - MINIMAL REQUIRED COLUMNS ONLY
  // ==================================================================
  Future<bool> createReport({
    required String reporterId,
    required String targetType, // 'listing', 'donation', 'user'
    required String targetId,
    required String reason,     // 'inappropriate_content', 'wrong_item', 'scam', 'spam', 'other'
    String? description,
  }) async {
    try {
      debugPrint('🚩 [ReportService] Creating report...');
      debugPrint('   - reported_by: $reporterId');
      debugPrint('   - report_type: $targetType');
      debugPrint('   - target_id: $targetId');
      debugPrint('   - reason: $reason');
      
      // ✅ FIX: Only include REQUIRED (NOT NULL) columns to avoid cache issues
      // Skip nullable columns like 'admin_note', 'target_type' that cause PGRST204
      final response = await _client
          .from('reports')
          .insert({
            'reported_by': reporterId,                    // ✅ NOT NULL
            'report_type': targetType,                    // ✅ NOT NULL
            'target_id': targetId,                        // ✅ NOT NULL
            'title': 'Report: ${reason.replaceAll('_', ' ')}', // ✅ NOT NULL
            'reason': reason,                             // ✅ NOT NULL
            'description': description?.trim() ?? 'No additional details provided', // ✅ NOT NULL
            'status': 'Pending',                          // ✅ NOT NULL - Capitalized for CHECK constraint
            'created_at': DateTime.now().toIso8601String(),   // ✅ NOT NULL
            'updated_at': DateTime.now().toIso8601String(),   // ✅ NOT NULL
            // ❌ SKIP these nullable columns to avoid cache issues:
            // 'admin_note': null,      // Nullable - causes PGRST204 if cache stale
            // 'target_type': targetType, // Nullable - not required for insert
          })
          .select(); // ✅ Return inserted row to verify success
      
      debugPrint('📦 [ReportService] Insert response: $response');
      
      if (response.isNotEmpty) {
        debugPrint('✅ [ReportService] Report inserted successfully: ${response.first}');
        return true;
      } else {
        debugPrint('❌ [ReportService] Insert returned empty array - likely RLS blocking');
        return false;
      }
      
    } on PostgrestException catch (e) {
      // ✅ Catch Supabase-specific errors with detailed info
      debugPrint('💥 [ReportService] PostgrestException: ${e.message}');
      debugPrint('   - Code: ${e.code}');
      debugPrint('   - Details: ${e.details}');
      debugPrint('   - Hint: ${e.hint}');
      return false;
      
    } catch (e, stack) {
      // ✅ Catch any other unexpected errors
      debugPrint('💥 [ReportService] Unexpected error: $e');
      debugPrint('📋 [ReportService] Stack trace: $stack');
      return false;
    }
  }

  // ==================================================================
  // FETCH PENDING REPORTS (Admin Dashboard) - SIMPLIFIED QUERY
  // ==================================================================
  Future<List<Map<String, dynamic>>> getPendingReports() async {
    try {
      debugPrint('📋 [ReportService] Fetching pending reports...');
      
      // ✅ FIX: Select ALL columns (*) from reports table only.
      // Removed the "profiles" join to avoid permission errors.
      // The admin UI will display reported_by as UUID for now.
      final response = await _client
          .from('reports')
          .select('*') 
          .eq('status', 'Pending') // ✅ Must match DB CHECK constraint (capitalized)
          .order('created_at', ascending: false);
      
      debugPrint('📦 [ReportService] Found ${response.length} pending reports');
      return (response as List).cast<Map<String, dynamic>>();
      
    } on PostgrestException catch (e) {
      debugPrint('💥 [ReportService] PostgrestException in getPendingReports: ${e.message}');
      debugPrint('   - Code: ${e.code}');
      debugPrint('   - Details: ${e.details}');
      return [];
    } catch (e) {
      debugPrint('❌ [ReportService] getPendingReports error: $e');
      return [];
    }
  }

   // ==================================================================
  // UPDATE REPORT STATUS (Admin Action) - SIMPLIFIED + DEBUG LOGGING
  // ==================================================================
  Future<bool> updateReportStatus({
    required String reportId,
    required String newStatus, // 'resolved' or 'dismissed' (lowercase input)
    String? adminNote,
  }) async {
    try {
      debugPrint('🔄 [ReportService] Updating report $reportId');
      debugPrint('   - Input status: "$newStatus"');
      
      // ✅ Map lowercase input to capitalized values that match DB CHECK constraint
      final dbStatus = _mapStatusToDatabaseValue(newStatus);
      debugPrint('   - Mapped status: "$dbStatus"');
      
      // ✅ ONLY update status field - skip updated_at to avoid any trigger/constraint issues
      final updates = <String, dynamic>{
        'status': dbStatus,  // ✅ Use capitalized value only
      };

      debugPrint('   - Sending update payload: $updates');
      
      final response = await _client
          .from('reports')
          .update(updates)
          .eq('id', reportId)
          .select(); // ✅ Return updated row to verify
      
      debugPrint('📦 [ReportService] Update response: $response');
      
      if (response.isNotEmpty) {
        debugPrint('✅ [ReportService] Report status updated to $dbStatus');
        return true;
      } else {
        debugPrint('❌ [ReportService] Update returned empty - check if report ID exists');
        return false;
      }
      
    } on PostgrestException catch (e) {
      // ✅ Catch Supabase-specific errors with detailed info
      debugPrint('💥 [ReportService] PostgrestException: ${e.message}');
      debugPrint('   - Code: ${e.code}');
      debugPrint('   - Details: ${e.details}');
      debugPrint('   - Hint: ${e.hint}');
      
      // ✅ Log the exact failing row if available
      if (e.details != null && e.details.toString().contains('Failing row')) {
        debugPrint('🔍 [ReportService] Failing row data: ${e.details}');
      }
      
      return false;
      
    } catch (e, stack) {
      // ✅ Catch any other unexpected errors
      debugPrint('💥 [ReportService] Unexpected error: $e');
      debugPrint('📋 [ReportService] Stack trace: $stack');
      return false;
    }
  }

  // ==================================================================
  // HELPER: Map status values to database-accepted capitalized format
  // ==================================================================
  String _mapStatusToDatabaseValue(String inputStatus) {
    switch (inputStatus.toLowerCase()) {
      case 'resolved':
        return 'Resolved';
      case 'dismissed':
        return 'Dismissed';
      case 'pending':
      default:
        return 'Pending';
    }
  }
}