import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/datasources/local/local_storage.dart';
import 'api_client_provider.dart';

/// 认证状态
class AuthState {
  final bool isAuthenticated;
  final String? token;
  final String? userId;
  final String? username;
  final String? email;

  AuthState({
    this.isAuthenticated = false,
    this.token,
    this.userId,
    this.username,
    this.email,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    String? userId,
    String? username,
    String? email,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
    );
  }
}

/// 认证状态管理
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final LocalStorage _localStorage;

  AuthNotifier(this._authRepository, this._localStorage) : super(AuthState()) {
    _loadToken();
  }

  /// 从本地存储加载 token
  Future<void> _loadToken() async {
    final token = await _localStorage.getToken();
    if (token != null) {
      state = state.copyWith(token: token, isAuthenticated: true);
    }
  }

  /// 用户登录
  Future<bool> login(String username, String password) async {
    try {
      final response = await _authRepository.login(
        username: username,
        password: password,
      );

      final token = response['access_token'];
      await _localStorage.saveToken(token);

      state = state.copyWith(
        isAuthenticated: true,
        token: token,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 用户注册
  Future<bool> register(String username, String email, String password) async {
    try {
      await _authRepository.register(
        username: username,
        email: email,
        password: password,
      );
      return await login(username, password);
    } catch (e) {
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    await _localStorage.clearToken();
    state = AuthState();
  }
}

/// Provider
final authRepositoryProvider = Provider((ref) => AuthRepository(apiClient: ref.watch(apiClientProvider)));
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(localStorageProvider),
  ),
);
