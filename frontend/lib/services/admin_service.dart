import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/inventory.dart';
import '../models/loan.dart';
import 'dio_client.dart';

/// Bundles an inventory together with its active loans, as returned by
/// `GET /api/admin/inventories/{code}/loans`.
class InventoryLoans {
  const InventoryLoans({required this.inventory, required this.loans});

  final Inventory inventory;
  final List<Loan> loans;
}

/// Wraps the admin mobile operations endpoints (`/api/admin/*`) into a
/// typed surface for staff (admin/laboran) users.
///
/// Validates Requirements 20, 21, 22. All envelope handling is centralized
/// here so the provider/screens see strongly-typed `ApiResponse<T>`.
class AdminService {
  AdminService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  /// `GET /admin/inventories/{code}` — resolve an inventory by its code
  /// (the bare QR payload). 404 -> "Inventory code not found".
  Future<ApiResponse<Inventory>> lookupInventory(String code) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.adminInventoryLookup(code),
    );

    return ApiResponse<Inventory>.fromEnvelope(
      _envelopeFrom(response),
      decoder: (data) {
        final map = (data as Map?)?.cast<String, dynamic>() ?? const {};
        return Inventory.fromJson(
          (map['inventory'] as Map).cast<String, dynamic>(),
        );
      },
      statusCode: response.statusCode,
    );
  }

  /// `GET /admin/inventories/{code}/loans` — active loans (approved or
  /// borrowed) for the inventory carrying [code].
  Future<ApiResponse<InventoryLoans>> loansByInventory(String code) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.adminInventoryLoans(code),
    );

    return ApiResponse<InventoryLoans>.fromEnvelope(
      _envelopeFrom(response),
      decoder: (data) {
        final map = (data as Map?)?.cast<String, dynamic>() ?? const {};
        final inventory = Inventory.fromJson(
          (map['inventory'] as Map).cast<String, dynamic>(),
        );
        final rawLoans = map['loans'];
        final loans = <Loan>[];
        if (rawLoans is List) {
          for (final entry in rawLoans) {
            if (entry is Map) {
              loans.add(Loan.fromJson(entry.cast<String, dynamic>()));
            }
          }
        }
        return InventoryLoans(inventory: inventory, loans: loans);
      },
      statusCode: response.statusCode,
    );
  }

  /// `POST /admin/loans/{id}/handover` — approved -> borrowed (stock -= 1).
  Future<ApiResponse<Loan>> handover(int loanId) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.adminLoanHandover(loanId),
    );

    return _decodeLoan(response);
  }

  /// `POST /admin/loans/{id}/return` — borrowed -> returned (stock += 1).
  Future<ApiResponse<Loan>> returnLoan(int loanId) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.adminLoanReturn(loanId),
    );

    return _decodeLoan(response);
  }

  // ---- internal helpers ----

  ApiResponse<Loan> _decodeLoan(Response<dynamic> response) {
    return ApiResponse<Loan>.fromEnvelope(
      _envelopeFrom(response),
      decoder: (data) {
        final map = (data as Map?)?.cast<String, dynamic>() ?? const {};
        return Loan.fromJson((map['loan'] as Map).cast<String, dynamic>());
      },
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _envelopeFrom(Response<dynamic> response) {
    final raw = response.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return {'success': false, 'message': 'Unexpected response shape'};
  }
}
