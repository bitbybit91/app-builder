import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/dispute.dart';
import '../models/trade.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  Map<String, dynamic> _stats = {};
  List<User> _adminUsers = [];
  List<Trade> _adminTrades = [];
  List<Dispute> _adminDisputes = [];
  Map<String, dynamic> _settings = {};
  bool _loading = false;
  String? _error;
  int _usersPage = 1;
  bool _hasMoreUsers = true;
  int _tradesPage = 1;
  bool _hasMoreTrades = true;
  int _disputesPage = 1;
  bool _hasMoreDisputes = true;

  Map<String, dynamic> get stats => _stats;
  List<User> get adminUsers => _adminUsers;
  List<Trade> get adminTrades => _adminTrades;
  List<Dispute> get adminDisputes => _adminDisputes;
  Map<String, dynamic> get settings => _settings;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMoreUsers => _hasMoreUsers;
  bool get hasMoreTrades => _hasMoreTrades;
  bool get hasMoreDisputes => _hasMoreDisputes;

  Future<void> fetchStats() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.get(ApiEndpoints.adminStats);
      _stats = response as Map<String, dynamic>;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUsers({String? search, bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _usersPage = 1;
      _hasMoreUsers = true;
      _adminUsers = [];
    }
    if (!_hasMoreUsers) return;

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final queryParams = <String, String>{'page': _usersPage.toString()};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      final query = Uri(queryParameters: queryParams).query;
      final response = await ApiService.instance.get('${ApiEndpoints.adminUsers}?$query');
      final data = response as Map<String, dynamic>;
      final items = (data['data'] as List<dynamic>? ?? [])
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
      _adminUsers.addAll(items);
      final meta = data['meta'] as Map<String, dynamic>?;
      final lastPage = meta?['last_page'] as int? ?? 1;
      _hasMoreUsers = _usersPage < lastPage;
      _usersPage++;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> banUser(int userId, String reason) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService.instance.post(
        ApiEndpoints.adminBanUser(userId),
        body: {'reason': reason},
      );
      final idx = _adminUsers.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        _adminUsers[idx] = _adminUsers[idx].copyWith(isBanned: true);
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> unbanUser(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService.instance.post(ApiEndpoints.adminUnbanUser(userId));
      final idx = _adminUsers.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        _adminUsers[idx] = _adminUsers[idx].copyWith(isBanned: false);
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDisputes({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _disputesPage = 1;
      _hasMoreDisputes = true;
      _adminDisputes = [];
    }
    if (!_hasMoreDisputes) return;

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final endpoint = '${ApiEndpoints.adminDisputes}?page=$_disputesPage';
      final response = await ApiService.instance.get(endpoint);
      final data = response as Map<String, dynamic>;
      final items = (data['data'] as List<dynamic>? ?? [])
          .map((e) => Dispute.fromJson(e as Map<String, dynamic>))
          .toList();
      _adminDisputes.addAll(items);
      final meta = data['meta'] as Map<String, dynamic>?;
      final lastPage = meta?['last_page'] as int? ?? 1;
      _hasMoreDisputes = _disputesPage < lastPage;
      _disputesPage++;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> resolveDispute(
    int disputeId,
    String winner,
    String resolution,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService.instance.post(
        ApiEndpoints.adminResolveDispute(disputeId),
        body: {'winner': winner, 'resolution': resolution},
      );
      _adminDisputes.removeWhere((d) => d.id == disputeId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdminTrades({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _tradesPage = 1;
      _hasMoreTrades = true;
      _adminTrades = [];
    }
    if (!_hasMoreTrades) return;

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final endpoint = '${ApiEndpoints.adminTrades}?page=$_tradesPage';
      final response = await ApiService.instance.get(endpoint);
      final data = response as Map<String, dynamic>;
      final items = (data['data'] as List<dynamic>? ?? [])
          .map((e) => Trade.fromJson(e as Map<String, dynamic>))
          .toList();
      _adminTrades.addAll(items);
      final meta = data['meta'] as Map<String, dynamic>?;
      final lastPage = meta?['last_page'] as int? ?? 1;
      _hasMoreTrades = _tradesPage < lastPage;
      _tradesPage++;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSettings() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.get(ApiEndpoints.adminSettings);
      _settings = response as Map<String, dynamic>;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> newSettings) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiService.instance.post(
        ApiEndpoints.adminSettings,
        body: {'settings': newSettings},
      );
      _settings = response as Map<String, dynamic>? ?? _settings;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
