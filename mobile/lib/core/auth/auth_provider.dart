import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../api/api_client.dart';
import '../models/worker.dart';
import '../constants.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  Worker? _worker;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  Worker? get worker => _worker;
  String? get error => _error;
  bool get loading => _loading;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiClient _api = ApiClient();

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final response = await _api.get('/api/v1/auth/me');
      _worker = Worker.fromJson(response.data['worker'] ?? response.data);
      _status = AuthStatus.authenticated;
    } catch (_) {
      await _storage.delete(key: AppConstants.tokenKey);
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> login(String phone, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(
        '/api/v1/auth/login',
        data: {'phone': phone, 'password': password},
      );

      final token = response.data['access_token'];
      final worker = Worker.fromJson(response.data['worker']);

      await _storage.write(
        key: AppConstants.tokenKey,
        value: token,
      );

      _worker = worker;
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    String? profession,
    required Map<String, dynamic> payout,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(
        '/api/v1/auth/register',
        data: {
          'name': name,
          'phone': phone,
          'password': password,
          if (profession != null && profession.isNotEmpty)
            'profession': profession,
          'payout': payout,
        },
      );

      final token = response.data['access_token'];
      final worker = Worker.fromJson(response.data['worker']);

      await _storage.write(
        key: AppConstants.tokenKey,
        value: token,
      );

      _worker = worker;
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    _worker = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      final str = e.toString();
      if (str.contains('detail')) {
        try {
          final start = str.indexOf('{');
          final end = str.lastIndexOf('}') + 1;
          if (start != -1 && end > start) {
            final json = jsonDecode(str.substring(start, end));
            return json['detail'] ?? 'Something went wrong';
          }
        } catch (_) {}
      }
      if (str.contains('409')) return 'Phone number already registered';
      if (str.contains('401')) return 'Incorrect phone or password';
      if (str.contains('422')) return 'Please check your details';
    }
    return 'Something went wrong. Please try again.';
  }
}
