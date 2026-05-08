import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndiscord/services/auth_service.dart';
import 'package:ndiscord/services/api_service.dart';
import 'package:ndiscord/models/user.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  final ApiService _api = ApiService();

  AuthNotifier() : super(AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      await _loadUser();
    }
  }

  Future<void> _loadUser() async {
    try {
      final response = await _api.get('/users/me');
      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body));
        state = state.copyWith(isAuthenticated: true, user: user);
      } else {
        final refreshed = await _authService.refreshToken();
        if (refreshed) {
          final response2 = await _api.get('/users/me');
          if (response2.statusCode == 200) {
            final user = User.fromJson(jsonDecode(response2.body));
            state = state.copyWith(isAuthenticated: true, user: user);
            return;
          }
        }
        await _authService.logout();
        state = AuthState();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final success = await _authService.login(username, password);
    if (success) {
      await _loadUser();
      state = state.copyWith(isLoading: false);
      return true;
    }
    state = state.copyWith(isLoading: false, error: 'Invalid credentials');
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final success = await _authService.register(username, email, password);
    if (success) {
      await _loadUser();
      state = state.copyWith(isLoading: false);
      return true;
    }
    state = state.copyWith(isLoading: false, error: 'Registration failed');
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
