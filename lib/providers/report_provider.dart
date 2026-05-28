// FILE: lib/providers/report_provider.dart
// ============================================================================
// REPORT PROVIDER
// ============================================================================
// State management for issue reporting (UC-08)
// - Submit new reports from buyers/sellers/donors
// - Fetch pending reports for admin moderation
// - Resolve/dismiss reports with admin actions
// Aligns with FYP Report: Table 14 (Admin Log), UC-08
// ============================================================================

import 'package:flutter/foundation.dart';
import '../services/report_service.dart';

class ReportProvider with ChangeNotifier {
  final ReportService _service;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _pendingReports = [];

  ReportProvider(this._service);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get pendingReports => List.unmodifiable(_pendingReports);

  // ==================================================================
  // SUBMIT REPORT - WITH REAL ERROR PROPAGATION
  // ==================================================================
  Future<bool> submitReport({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 [ReportProvider] submitReport called');
      debugPrint('   - reporterId: $reporterId');
      debugPrint('   - targetType: $targetType');
      debugPrint('   - targetId: $targetId');
      
      final success = await _service.createReport(
        reporterId: reporterId,
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        description: description,
      );
      
      debugPrint('✅ [ReportProvider] Service returned: $success');
      
      if (!success) {
        // ✅ Service already logged the detailed error; set a user-friendly message
        _errorMessage = 'Failed to submit report. Please check your connection and try again.';
        debugPrint('⚠️ [ReportProvider] Error set: $_errorMessage');
      }
      
      return success;
      
    } catch (e, stack) {
      // ✅ Catch unexpected errors and log full details
      debugPrint('💥 [ReportProvider] Unexpected error in submitReport: $e');
      debugPrint('📋 [ReportProvider] Stack trace: $stack');
      _errorMessage = 'Error: ${e.toString()}';
      return false;
      
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('🔄 [ReportProvider] Loading state reset');
    }
  }

  // ==================================================================
  // LOAD PENDING REPORTS (Admin Dashboard)
  // ==================================================================
  Future<void> loadPendingReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 [ReportProvider] Loading pending reports...');
      _pendingReports = await _service.getPendingReports();
      debugPrint('✅ [ReportProvider] Loaded ${_pendingReports.length} pending reports');
    } catch (e, stack) {
      debugPrint('❌ [ReportProvider] loadPendingReports error: $e');
      debugPrint('📋 [ReportProvider] Stack: $stack');
      _errorMessage = 'Failed to load reports: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // RESOLVE REPORT (Admin Action)
  // ==================================================================
  Future<bool> resolveReport(String reportId, {String? note}) async {
    debugPrint('🔄 [ReportProvider] resolveReport called for $reportId');
    return _updateStatus(reportId, 'resolved', note);
  }

  // ==================================================================
  // DISMISS REPORT (Admin Action)
  // ==================================================================
  Future<bool> dismissReport(String reportId, {String? note}) async {
    debugPrint('🔄 [ReportProvider] dismissReport called for $reportId');
    return _updateStatus(reportId, 'dismissed', note);
  }

  // ==================================================================
  // INTERNAL: Update Report Status
  // ==================================================================
  Future<bool> _updateStatus(String reportId, String status, String? note) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      debugPrint('🔄 [ReportProvider] Updating report $reportId to $status');
      
      final success = await _service.updateReportStatus(
        reportId: reportId,
        newStatus: status,
        adminNote: note,
      );
      
      debugPrint('✅ [ReportProvider] Update result: $success');
      
      if (success) {
        // ✅ Refresh the list after successful update
        await loadPendingReports();
      }
      
      return success;
      
    } catch (e, stack) {
      debugPrint('❌ [ReportProvider] _updateStatus error: $e');
      debugPrint('📋 [ReportProvider] Stack: $stack');
      _errorMessage = 'Failed to update report: ${e.toString()}';
      return false;
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================================================================
  // CLEAR ERROR MESSAGE
  // ==================================================================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}