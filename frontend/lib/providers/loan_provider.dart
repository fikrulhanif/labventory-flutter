import 'package:flutter/foundation.dart';

import '../models/api_response.dart';
import '../models/loan.dart';
import '../services/loan_service.dart';

enum LoanHistoryState { idle, loading, refreshing, loadingMore, ready, error }

/// Owns the student's loan history list state plus the form-level
/// state for the "Create loan" screen (loading flag + 422 errors).
class LoanProvider extends ChangeNotifier {
  LoanProvider({LoanService? service}) : _service = service ?? LoanService();

  final LoanService _service;

  // ---- history state ----
  final List<Loan> _items = [];
  List<Loan> get items => List.unmodifiable(_items);

  LoanHistoryState _state = LoanHistoryState.idle;
  LoanHistoryState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 1;
  int _lastPage = 1;
  bool get hasNextPage => _currentPage < _lastPage;

  LoanStatus? _statusFilter;
  LoanStatus? get statusFilter => _statusFilter;

  // ---- create-loan state ----
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _submitError;
  String? get submitError => _submitError;

  Map<String, List<String>> _validationErrors = {};
  Map<String, List<String>> get validationErrors => _validationErrors;

  // -----------------------------------------------------------
  // History actions
  // -----------------------------------------------------------

  Future<void> loadHistory({bool refresh = false}) async {
    if (refresh || _items.isEmpty) {
      _state = _items.isEmpty
          ? LoanHistoryState.loading
          : LoanHistoryState.refreshing;
      _errorMessage = null;
      notifyListeners();
    }

    final response = await _service.history(status: _statusFilter, page: 1);

    if (response.success && response.data != null) {
      _items
        ..clear()
        ..addAll(response.data!.items);
      _currentPage = response.data!.currentPage;
      _lastPage = response.data!.lastPage;
      _state = LoanHistoryState.ready;
    } else {
      _errorMessage = response.message.isEmpty
          ? 'Could not load loans.'
          : response.message;
      _state = LoanHistoryState.error;
    }

    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasNextPage || _state == LoanHistoryState.loadingMore) return;

    _state = LoanHistoryState.loadingMore;
    notifyListeners();

    final response = await _service.history(
      status: _statusFilter,
      page: _currentPage + 1,
    );

    if (response.success && response.data != null) {
      _items.addAll(response.data!.items);
      _currentPage = response.data!.currentPage;
      _lastPage = response.data!.lastPage;
      _state = LoanHistoryState.ready;
    } else {
      _errorMessage = response.message;
      _state = LoanHistoryState.error;
    }

    notifyListeners();
  }

  void setStatusFilter(LoanStatus? status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    loadHistory(refresh: true);
  }

  // -----------------------------------------------------------
  // Create
  // -----------------------------------------------------------

  /// Submit a loan request. Returns the created [Loan] on success or
  /// `null` on failure (caller should inspect [submitError] /
  /// [validationErrors]).
  Future<Loan?> submitLoan({
    required int inventoryId,
    required DateTime borrowDate,
    required DateTime returnDate,
    required String documentPath,
    String? documentFilename,
    String? notes,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    _validationErrors = {};
    notifyListeners();

    try {
      final response = await _service.create(
        inventoryId: inventoryId,
        borrowDate: borrowDate,
        returnDate: returnDate,
        documentPath: documentPath,
        documentFilename: documentFilename,
        notes: notes,
      );

      if (response.success && response.data != null) {
        // Prepend so the brand new loan appears at the top of the
        // history list without waiting for a refresh.
        _items.insert(0, response.data!);
        return response.data;
      }

      _captureErrors(response);
      return null;
    } catch (e) {
      _submitError = 'Network error: ${e.toString()}';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearSubmitErrors() {
    if (_submitError == null && _validationErrors.isEmpty) return;
    _submitError = null;
    _validationErrors = {};
    notifyListeners();
  }

  // -----------------------------------------------------------
  // Detail (lightweight wrapper; screens cache results themselves)
  // -----------------------------------------------------------

  Future<Loan?> fetchDetail(int id) async {
    final response = await _service.detail(id);
    if (response.success) return response.data;
    return null;
  }

  /// Cancel a pending loan. Returns `true` on success.
  /// On success the loan is updated in the in-memory list to `rejected`
  /// so the UI reflects the change immediately without a full reload.
  Future<bool> cancelLoan(int id) async {
    try {
      final response = await _service.cancel(id);
      if (response.success) {
        // Optimistic: update status in the cached list
        final idx = _items.indexWhere((l) => l.id == id);
        if (idx != -1) {
          final updated = Loan.fromJson({
            ..._items[idx].toJson(),
            'status': 'rejected',
            'reject_reason': 'Dibatalkan oleh mahasiswa.',
          });
          _items[idx] = updated;
          notifyListeners();
        }
        return true;
      }
      _submitError = response.message;
      return false;
    } catch (e) {
      _submitError = 'Kesalahan jaringan: ${e.toString()}';
      return false;
    }
  }

  void _captureErrors<T>(ApiResponse<T> response) {
    _submitError = response.message.isNotEmpty
        ? response.message
        : 'Could not submit loan request.';
    _validationErrors = response.errors ?? {};
  }

  /// Cleared on logout so the next user sees an empty history.
  void clearAll() {
    _items.clear();
    _state = LoanHistoryState.idle;
    _statusFilter = null;
    _currentPage = 1;
    _lastPage = 1;
    _errorMessage = null;
    _submitError = null;
    _validationErrors = {};
    notifyListeners();
  }
}
