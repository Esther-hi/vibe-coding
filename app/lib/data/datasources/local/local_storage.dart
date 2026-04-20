import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _todoKey = 'local_todos';

  Box<String>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>('app_storage');
  }

  Future<void> saveToken(String token) async {
    await _box?.put(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _box?.get(_tokenKey);
  }

  Future<void> clearToken() async {
    await _box?.delete(_tokenKey);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final encoded = jsonEncode(userData);
    await _box?.put(_userKey, encoded);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final encoded = _box?.get(_userKey);
    if (encoded == null) return null;
    return jsonDecode(encoded) as Map<String, dynamic>;
  }

  // 本地待办列表
  Future<void> saveLocalTodos(List<Map<String, dynamic>> todos) async {
    final encoded = jsonEncode(todos);
    await _box?.put(_todoKey, encoded);
  }

  List<Map<String, dynamic>> getLocalTodos() {
    final encoded = _box?.get(_todoKey);
    if (encoded == null) return [];
    final list = jsonDecode(encoded) as List;
    return list.cast<Map<String, dynamic>>();
  }
}
