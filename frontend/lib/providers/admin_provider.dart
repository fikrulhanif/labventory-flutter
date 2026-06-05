import 'package:flutter/foundation.dart';

import '../models/inventory.dart';
import '../models/loan.dart';
import '../services/admin_service.dart';

/// Where the admin QR/lookup flow currently is.
enum AdminLookupStatus {
  /// Nothing scanned yet — show the scanner / manual entry.
  idle,

  /// A lookup is in flight.
  loading,

  /// Inventory + active loans resolved successfully.
  loaded,

  /// The scanned/typed code did not match any inventory.
  notFound,

  /// Network or unexpected error.
  error,
}

/// Owns the state of the admin operations flow: the scanned inventory,
/// its active loans, the selected loan, and the handover/return action
/// state (Requirements 20-22).
class AdminProvider extends ChangeNotifier {
  AdminProvider({AdminService? service}) : _service = service ?? AdminService();

  final AdminService _service;

  AdminLookupStatus _status = AdminLookupStatus.idle;
  AdminLookupStatus get status => _status;

  Inventory? _inventory;
  Inventory? get inventory => _inventory;

  List<Loan> _loans = const [];
  List<Loan> get loans => _loans;

  Loan? _selectedLoan;
  Loan? get selectedLoan => _selectedLoan;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// True while a handover/return action is being submitted.
  bool _isActing = false;
  bool get isActing => _isActing;

  bool get hasResult => _status == AdminLookupStatus.loaded;

  // -----------------------------------------------------------
  // Lookup flow
  // -----------------------------------------------------------

  /// Resolve a scanned/typed inventory code and load its active loans.
  /// Both the QR scanner and the manual-entry field call this.
  Future<void> lookupByCode(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) return;

    _status = AdminLookupStatus.loading;
    _errorMessage = null;
    _selectedLoan = null;
    notifyListeners();

    try {
      final response = await _service.loansByInventory(code);

      if (response.success && response.data != null) {
        _inventory = response.data!.inventory;
        _loans = response.data!.loans;
        // Auto-select when there's exactly one active loan so the admin
        // can act in a single tap.
        _selectedLoan = _loans.length == 1 ? _loans.first : null;
        _status = AdminLookupStatus.loaded;
      } else if (response.statusCode == 404) {
        _inventory = null;
        _loans = const [];
        _status = AdminLookupStatus.notFound;
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Kode inventaris tidak ditemukan';
      } else {
        _status = AdminLookupStatus.error;
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Gagal memuat data inventaris.';
      }
    } catch (e) {
      _status = AdminLookupStatus.error;
      _errorMessage = 'Kesalahan jaringan: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  void selectLoan(Loan loan) {
    _selectedLoan = loan;
    notifyListeners();
  }

  /// Reset to the idle scanning state (e.g. after finishing an action or
  /// when the user wants to scan another item).
  void reset() {
    _status = AdminLookupStatus.idle;
    _inventory = null;
    _loans = const [];
    _selectedLoan = null;
    _errorMessage = null;
    _isActing = false;
    notifyListeners();
  }

  // -----------------------------------------------------------
  // Actions
  // -----------------------------------------------------------

  /// Confirm physical handover for [loanId] (approved -> borrowed).
  /// Returns the success message on success, or null on failure (with
  /// [errorMessage] populated).
  Future<String?> handover(int loanId) {
    return _act(() => _service.handover(loanId));
  }

  /// Confirm physical return for [loanId] (borrowed -> returned).
  Future<String?> returnLoan(int loanId) {
    return _act(() => _service.returnLoan(loanId));
  }

  Future<String?> _act(Future<dynamic> Function() action) async {
    _isActing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await action();

      if (response.success && response.data != null) {
        // Refresh the active loans for the current inventory so the list
        // reflects the new state (the processed loan drops off / changes).
        final code = _inventory?.code;
        final message = response.message;
        if (code != null) {
          await _refreshLoans(code);
        }
        return message.isNotEmpty ? message : 'Berhasil diproses.';
      }

      _errorMessage = response.message.isNotEmpty
          ? response.message
          : 'Aksi gagal diproses.';
      return null;
    } catch (e) {
      _errorMessage = 'Kesalahan jaringan: ${e.toString()}';
      return null;
    } finally {
      _isActing = false;
      notifyListeners();
    }
  }

  /// Silently reload the active loans after an action.
  Future<void> _refreshLoans(String code) async {
    try {
      final response = await _service.loansByInventory(code);
      if (response.success && response.data != null) {
        _inventory = response.data!.inventory;
        _loans = response.data!.loans;
        if (_selectedLoan != null) {
          // Keep the selection only if the loan is still active.
          final stillActive = _loans
              .where((l) => l.id == _selectedLoan!.id)
              .toList();
          _selectedLoan = stillActive.isNotEmpty
              ? stillActive.first
              : (_loans.length == 1 ? _loans.first : null);
        } else if (_loans.length == 1) {
          _selectedLoan = _loans.first;
        }
      }
    } catch (_) {
      // Soft fail; the action already succeeded.
    }
  }
}
