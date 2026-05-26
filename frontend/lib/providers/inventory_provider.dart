import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/category.dart' as models;
import '../models/inventory.dart';
import '../services/inventory_service.dart';

/// State machine for the inventory list screen.
enum InventoryListState { idle, loading, refreshing, loadingMore, ready, error }

/// Owns inventory list state, filters, pagination, and category lookup.
///
/// Validates Requirements 7.1 — 7.7.
///
/// Search input is debounced inside [setSearch] so screens can wire the
/// raw text controller directly without worrying about over-firing
/// requests.
class InventoryProvider extends ChangeNotifier {
  InventoryProvider({InventoryService? service})
    : _service = service ?? InventoryService();

  final InventoryService _service;

  // ---- list state ----
  final List<Inventory> _items = [];
  List<Inventory> get items => List.unmodifiable(_items);

  InventoryListState _state = InventoryListState.idle;
  InventoryListState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ---- pagination ----
  int _currentPage = 1;
  int _lastPage = 1;
  bool get hasNextPage => _currentPage < _lastPage;

  // ---- filters ----
  String _search = '';
  String get search => _search;

  int? _categoryId;
  int? get categoryId => _categoryId;

  String? _statusFilter;
  String? get statusFilter => _statusFilter;

  // ---- categories ----
  List<models.Category> _categories = const [];
  List<models.Category> get categories => _categories;

  // ---- search debounce ----
  Timer? _searchDebounce;
  static const Duration _debounceDelay = Duration(milliseconds: 350);

  // -----------------------------------------------------------
  // Public actions
  // -----------------------------------------------------------

  /// Initial load: categories (for filter UI) plus the first page of
  /// inventories. Idempotent.
  Future<void> bootstrap() async {
    await Future.wait([_loadCategories(), refresh()]);
  }

  /// Refresh from page 1. Replaces the current item list on success.
  Future<void> refresh() async {
    _state = _items.isEmpty
        ? InventoryListState.loading
        : InventoryListState.refreshing;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.list(
      search: _search,
      categoryId: _categoryId,
      status: _statusFilter,
      page: 1,
    );

    if (response.success && response.data != null) {
      _items
        ..clear()
        ..addAll(response.data!.items);
      _currentPage = response.data!.currentPage;
      _lastPage = response.data!.lastPage;
      _state = InventoryListState.ready;
    } else {
      _errorMessage = response.message.isEmpty
          ? 'Could not load inventory.'
          : response.message;
      _state = InventoryListState.error;
    }

    notifyListeners();
  }

  /// Append the next page to the current list. No-op when no more pages.
  Future<void> loadMore() async {
    if (!hasNextPage || _state == InventoryListState.loadingMore) {
      return;
    }

    _state = InventoryListState.loadingMore;
    notifyListeners();

    final nextPage = _currentPage + 1;
    final response = await _service.list(
      search: _search,
      categoryId: _categoryId,
      status: _statusFilter,
      page: nextPage,
    );

    if (response.success && response.data != null) {
      _items.addAll(response.data!.items);
      _currentPage = response.data!.currentPage;
      _lastPage = response.data!.lastPage;
      _state = InventoryListState.ready;
    } else {
      _errorMessage = response.message;
      _state = InventoryListState.error;
    }

    notifyListeners();
  }

  /// Debounced search setter — call this from the [TextField.onChanged]
  /// handler. Triggers `refresh()` once the user stops typing for
  /// `_debounceDelay`.
  void setSearch(String value) {
    _search = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_debounceDelay, refresh);
    notifyListeners();
  }

  void setCategoryId(int? id) {
    if (_categoryId == id) return;
    _categoryId = id;
    refresh();
  }

  void setStatusFilter(String? status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    refresh();
  }

  void clearFilters() {
    _search = '';
    _categoryId = null;
    _statusFilter = null;
    refresh();
  }

  // -----------------------------------------------------------
  // Internals
  // -----------------------------------------------------------

  Future<void> _loadCategories() async {
    final response = await _service.categories();
    if (response.success && response.data != null) {
      _categories = response.data!;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
