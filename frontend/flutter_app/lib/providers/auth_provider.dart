import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token != null) {
        _apiService.setToken(token);
        _user = await _apiService.getCurrentUser();
        _isAuthenticated = true;
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      final token = response['access_token'];

      await _storageService.saveToken(token);
      _apiService.setToken(token);

      _user = await _apiService.getCurrentUser();
      await _storageService.saveUser(_user!);

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.register(email, username, password);
      
      // Auto-login after registration
      return await login(email, password);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}