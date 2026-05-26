import 'inventory.dart';
import 'user.dart';

/// Loan status as returned by `LoanResource`.
enum LoanStatus {
  pending,
  approved,
  rejected,
  borrowed,
  returned,
  unknown;

  static LoanStatus fromWire(String value) => switch (value) {
    'pending' => LoanStatus.pending,
    'approved' => LoanStatus.approved,
    'rejected' => LoanStatus.rejected,
    'borrowed' => LoanStatus.borrowed,
    'returned' => LoanStatus.returned,
    _ => LoanStatus.unknown,
  };

  String get wire => switch (this) {
    LoanStatus.pending => 'pending',
    LoanStatus.approved => 'approved',
    LoanStatus.rejected => 'rejected',
    LoanStatus.borrowed => 'borrowed',
    LoanStatus.returned => 'returned',
    LoanStatus.unknown => 'unknown',
  };

  /// Display label for the status chip widget (Task 17.5).
  String get label => switch (this) {
    LoanStatus.pending => 'Pending',
    LoanStatus.approved => 'Approved',
    LoanStatus.rejected => 'Rejected',
    LoanStatus.borrowed => 'Borrowed',
    LoanStatus.returned => 'Returned',
    LoanStatus.unknown => '—',
  };
}

/// Mirrors `LoanResource` on the backend (Requirements 8.1, 8.9, 11.1,
/// 11.3).
class Loan {
  const Loan({
    required this.id,
    required this.status,
    this.borrowDate,
    this.returnDate,
    this.notes,
    this.rejectReason,
    this.documentUrl,
    this.pickedUpAt,
    this.returnedAt,
    this.user,
    this.inventory,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final LoanStatus status;
  final DateTime? borrowDate;
  final DateTime? returnDate;
  final String? notes;
  final String? rejectReason;
  final String? documentUrl;
  final DateTime? pickedUpAt;
  final DateTime? returnedAt;
  final User? user;
  final Inventory? inventory;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPending => status == LoanStatus.pending;
  bool get isTerminal =>
      status == LoanStatus.rejected || status == LoanStatus.returned;

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as int,
      status: LoanStatus.fromWire(json['status'] as String? ?? 'unknown'),
      borrowDate: _parseDate(json['borrow_date']),
      returnDate: _parseDate(json['return_date']),
      notes: json['notes'] as String?,
      rejectReason: json['reject_reason'] as String?,
      documentUrl: json['document_url'] as String?,
      pickedUpAt: _parseDate(json['picked_up_at']),
      returnedAt: _parseDate(json['returned_at']),
      user: json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      inventory: json['inventory'] is Map<String, dynamic>
          ? Inventory.fromJson(json['inventory'] as Map<String, dynamic>)
          : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.wire,
      'borrow_date': borrowDate?.toIso8601String().split('T').first,
      'return_date': returnDate?.toIso8601String().split('T').first,
      'notes': notes,
      'reject_reason': rejectReason,
      'document_url': documentUrl,
      'picked_up_at': pickedUpAt?.toUtc().toIso8601String(),
      'returned_at': returnedAt?.toUtc().toIso8601String(),
      'user': user?.toJson(),
      'inventory': inventory?.toJson(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}
