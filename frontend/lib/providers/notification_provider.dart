import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';

enum NotificationLoadState {
  idle,
  loading,
  refreshing,
  loadingMore,
  ready,
  error,
}

/// Owns the notification list, unread badge count, and mark-read actions
/// for the authenticated student.
///
/// Pattern mirrors LoanProvider and InventoryProvider.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? service})
    : _service = service ?? NotificationService();

  final NotificationService _service;

  final List<AppNotification> _items = [];
  List<AppNotification> get items => List.unmodifiable(_items);

  NotificationLoadState _state = NotificationLoadState.idle;
  NotificationLoadState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 1;
  int _lastPage = 1;
  bool get hasNextPage => _currentPage < _lastPage;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool get hasUnread => _unreadCount > 0;

  // ───────────────────────────────────────────────────────────────
  // Load / refresh
  // ───────────────────────────────────────────────────────────────

  Future<void> load({bool refresh = false}) async {
    if (refresh || _items.isEmpty) {
      _state = _items.isEmpty
          ? NotificationLoadState.loading
          : NotificationLoadState.refreshing;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _service.list(page: 1);

      if (response.success && response.data != null) {
        _items
          ..clear()
          ..addAll(response.data!.items);
        _currentPage = response.data!.currentPage;
        _lastPage = response.data!.lastPage;
        _state = NotificationLoadState.ready;
        _syncUnreadFromList();
      } else {
        _errorMessage = response.message.isEmpty
            ? 'Gagal memuat notifikasi.'
            : response.message;
        _state = NotificationLoadState.error;
      }
    } catch (e) {
      _errorMessage = 'Kesalahan jaringan: ${e.toString()}';
      _state = NotificationLoadState.error;
    }

    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasNextPage || _state == NotificationLoadState.loadingMore) return;

    _state = NotificationLoadState.loadingMore;
    notifyListeners();

    try {
      final response = await _service.list(page: _currentPage + 1);

      if (response.success && response.data != null) {
        _items.addAll(response.data!.items);
        _currentPage = response.data!.currentPage;
        _lastPage = response.data!.lastPage;
        _state = NotificationLoadState.ready;
      } else {
        _state = NotificationLoadState.ready; // keep current items
      }
    } catch (_) {
      _state = NotificationLoadState.ready;
    }

    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────
  // Unread count (badge)
  // ───────────────────────────────────────────────────────────────

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _service.unreadCount();
      notifyListeners();
    } catch (_) {
      // Soft fail — badge just keeps last known count.
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Mark read
  // ───────────────────────────────────────────────────────────────

  /// Mark one notification as read (optimistic UI update).
  Future<void> markRead(int id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1) return;

    final wasUnread = !_items[idx].isRead;
    if (!wasUnread) return; // already read — nothing to do

    // Optimistic: update in-memory immediately.
    _items[idx] = _items[idx].copyWith(isRead: true);
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    // Fire-and-forget: tell the server.
    try {
      await _service.markRead(id);
    } catch (_) {
      // Soft fail — the server will still show it as unread on next refresh,
      // but the UX is already improved.
    }
  }

  /// Mark all as read (optimistic).
  Future<void> markAllRead() async {
    final hadUnread = _unreadCount > 0;
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].isRead) {
        _items[i] = _items[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    if (hadUnread) notifyListeners();

    try {
      await _service.markAllRead();
    } catch (_) {
      // Soft fail.
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Cleanup
  // ───────────────────────────────────────────────────────────────

  void clearAll() {
    _items.clear();
    _state = NotificationLoadState.idle;
    _unreadCount = 0;
    _currentPage = 1;
    _lastPage = 1;
    _errorMessage = null;
    notifyListeners();
  }

  void _syncUnreadFromList() {
    _unreadCount = _items.where((n) => !n.isRead).length;
  }
}
