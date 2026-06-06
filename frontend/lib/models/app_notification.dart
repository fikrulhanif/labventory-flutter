/// Mirrors `NotificationResource` from the backend.
///
/// Named AppNotification to avoid shadowing dart:html's Notification.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.loanId,
    required this.isRead,
    this.createdAt,
  });

  final int id;
  final String title;
  final String message;

  /// One of: loan_created | loan_approved | loan_rejected |
  ///          loan_borrowed | loan_returned | system
  final String type;

  final int? loanId;
  final bool isRead;
  final DateTime? createdAt;

  // ---- Type constants (match backend) ----
  static const String typeLoanCreated = 'loan_created';
  static const String typeLoanApproved = 'loan_approved';
  static const String typeLoanRejected = 'loan_rejected';
  static const String typeLoanBorrowed = 'loan_borrowed';
  static const String typeLoanReturned = 'loan_returned';
  static const String typeSystem = 'system';

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String? ?? typeSystem,
      loanId: json['loan_id'] as int?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: _parseDate(json['created_at']),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      loanId: loanId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }
}
