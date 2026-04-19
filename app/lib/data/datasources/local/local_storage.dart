import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  Box<String>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>('app_storage');
  }

  /// 保存 Token
  Future<void> saveToken(String token) async {
    await _box?.put(_tokenKey, token);
  }

  /// 获取 Token
  Future<String?> getToken() async {
    return _box?.get(_tokenKey);
  }

  /// 清除 Token
  Future<void> clearToken() async {
    await _box?.delete(_tokenKey);
  }

  /// 保存用户数据
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final encoded = jsonEncode(userData);
    await _box?.put(_userKey, encoded);
  }

  /// 获取用户数据
  Future<Map<String, dynamic>?> getUserData() async {
    final encoded = _box?.get(_userKey);
    if (encoded == null) return null;
    return jsonDecode(encoded) as Map<String, dynamic>;
  }
}
