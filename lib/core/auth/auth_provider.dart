import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? nombre;
  final String? rol;
  final String? id;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.nombre,
    this.rol,
    this.id,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? nombre,
    String? rol,
    String? id,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      id: id ?? this.id,
    );
  }
}

class AuthProvider extends StateNotifier<AuthState> {
  AuthProvider() : super(const AuthState());

  Future<void> checkSession() async {
    final hasToken = await SecureStorage.hasToken();
    if (hasToken) {
      final tecnico = await SecureStorage.getTecnico();
      state = AuthState(
        isAuthenticated: true,
        nombre: tecnico['nombre'],
        rol: tecnico['rol'],
        id: tecnico['id'],
      );
    }
  }

  Future<void> login({
    required String token,
    required String id,
    required String nombre,
    required String rol,
    required String codigo,
  }) async {
    await SecureStorage.saveToken(token);
    await SecureStorage.saveTecnico(
      id: id,
      nombre: nombre,
      rol: rol,
      codigo: codigo,
    );
    state = AuthState(
      isAuthenticated: true,
      nombre: nombre,
      rol: rol,
      id: id,
    );
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthProvider, AuthState>((ref) {
  return AuthProvider();
});
