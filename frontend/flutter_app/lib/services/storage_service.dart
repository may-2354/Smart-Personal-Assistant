import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config/app_constants.dart';
import '../models/user_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token Management
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  // User Data
  Future<void> saveUser(User user) async {
    await _prefs?.setString(
      AppConstants.userKey,
      json.encode(user.toJson()),
    );
  }

  User? getUser() {
    final userJson = _prefs?.getString(AppConstants.userKey);
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }
    return null;
  }

  Future<void> deleteUser() async {
    await _prefs?.remove(AppConstants.userKey);
  }

  // Clear All Data
  Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
  }
}