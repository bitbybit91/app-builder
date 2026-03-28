import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _error;
  bool _requiresTwoFactor = false;
  String? _twoFactorSecret;
  String? _twoFactorQrUrl;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get requiresTwoFactor => _requiresTwoFactor;
  String? get twoFactorSecret => _twoFactorSecret;
  String? get twoFactorQrUrl => _twoFactorQrUrl;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      final token = await StorageService.instance.getToken();
      if (token != null) {
        ApiService.instance.setToken(token);
        await _loadUser();
      }
    } catch (_) {
      _user = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await AuthService.instance.login(email, password);

      if (data['requires_2fa'] == true) {
        _requiresTwoFactor = true;
        // Store token temporarily if provided, awaiting 2FA
        if (data['token'] != null) {
          final token = data['token'] as String;
          ApiService.instance.setToken(token);
          await StorageService.instance.saveToken(token);
        }
        return false;
      }

      final token = data['token'] as String?;
      if (token != null) {
        ApiService.instance.setToken(token);
        await StorageService.instance.saveToken(token);
      }
      await _loadUser();
      _requiresTwoFactor = false;
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

  Future<bool> verifyTwoFactor(String code) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final verified = await AuthService.instance.verifyTwoFactor(code);
      if (verified) {
        await _loadUser();
        _requiresTwoFactor = false;
        return true;
      }
      _error = 'Invalid two-factor code';
      return false;
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

  Future<bool> register(
    String name,
    String username,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await AuthService.instance.register(
        name,
        username,
        email,
        password,
        passwordConfirmation,
      );
      final token = data['token'] as String?;
      if (token != null) {
        ApiService.instance.setToken(token);
        await StorageService.instance.saveToken(token);
      }
      await _loadUser();
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

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    try {
      await AuthService.instance.logout();
    } catch (_) {
      // Proceed with local logout even if API call fails
    } finally {
      ApiService.instance.clearToken();
      await StorageService.instance.clearAll();
      _user = null;
      _requiresTwoFactor = false;
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> enableTwoFactor() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await AuthService.instance.enableTwoFactor();
      _twoFactorSecret = data['secret'] as String?;
      _twoFactorQrUrl = data['qr_url'] as String?;
      return data;
    } on ApiException catch (e) {
      _error = e.message;
      return {};
    } catch (e) {
      _error = e.toString();
      return {};
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> disableTwoFactor(String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await AuthService.instance.disableTwoFactor(password);
      await _loadUser();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUser() async {
    final data = await AuthService.instance.getUser();
    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    _user = User.fromJson(userJson);
    await StorageService.instance.saveUserJson(jsonEncode(_user!.toJson()));
  }
}
