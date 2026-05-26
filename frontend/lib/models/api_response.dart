/// Generic envelope for the Labventory standardized JSON response
/// (Requirements 17.1 — 17.4):
///
///   { "success": bool, "message": String, "data": T?, "errors"?: ... }
///
/// The Dio response interceptor unwraps the raw JSON into one of these
/// instances so screens / providers see a single shape.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.statusCode,
  });

  final bool success;
  final String message;
  final T? data;

  /// Field-level validation errors, e.g. `{ "email": ["already taken"] }`.
  final Map<String, List<String>>? errors;

  /// Underlying HTTP status code so screens can branch (401 to login, etc.).
  final int? statusCode;

  /// True when this response carries field-level validation errors.
  bool get hasValidationErrors => errors != null && errors!.isNotEmpty;

  /// Build a typed wrapper from a parsed envelope. The decoder receives
  /// the value of the `data` key and is responsible for shaping it into
  /// T (e.g. a model instance, a list, a paginated tuple).
  factory ApiResponse.fromEnvelope(
    Map<String, dynamic> envelope, {
    T Function(Object?)? decoder,
    int? statusCode,
  }) {
    final rawErrors = envelope['errors'];
    Map<String, List<String>>? parsedErrors;
    if (rawErrors is Map) {
      parsedErrors = rawErrors.map((key, value) {
        final messages = (value is List)
            ? value.map((m) => m.toString()).toList()
            : <String>[value.toString()];
        return MapEntry(key.toString(), messages);
      });
    }

    final rawData = envelope['data'];
    T? data;
    if (rawData != null && decoder != null) {
      data = decoder(rawData);
    }

    return ApiResponse<T>(
      success: (envelope['success'] as bool?) ?? false,
      message: (envelope['message'] as String?) ?? '',
      data: data,
      errors: parsedErrors,
      statusCode: statusCode,
    );
  }
}

/// Helper for paginated bodies: { "items": [...], "meta": { ... } }.
class PaginatedData<T> {
  const PaginatedData({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;

  /// Decode a paginated payload from `data` shape.
  ///
  /// Items array can be passed through `itemDecoder` to turn each entry
  /// into a typed model.
  factory PaginatedData.fromEnvelope(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) itemDecoder,
  ) {
    final rawItems = data['items'];
    final items = <T>[];
    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is Map<String, dynamic>) {
          items.add(itemDecoder(entry));
        }
      }
    }

    final meta = (data['meta'] as Map?) ?? const {};
    return PaginatedData<T>(
      items: items,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      perPage: (meta['per_page'] as num?)?.toInt() ?? items.length,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
    );
  }
}
