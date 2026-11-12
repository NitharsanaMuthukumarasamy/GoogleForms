import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/admin_model.dart';
import '../../data/auth_repository.dart';

/// Provider for the AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream provider for raw Firebase auth state changes.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Future provider to fetch the active Admin model from Firestore.
final currentAdminProvider = FutureProvider<Admin?>((ref) async {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) return null;

  final repo = ref.watch(authRepositoryProvider);
  return repo.getCurrentAdminProfile();
});

/// State for managing login / logout async operations.
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final Admin? admin;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.admin,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    Admin? admin,
    bool clearErrors = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearErrors ? null : (successMessage ?? this.successMessage),
      admin: admin ?? this.admin,
    );
  }
}

/// Controller managing the authentication lifecycle.
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState());

  /// Attempts to sign in with email & password, verifying admin authorization.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      final admin = await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        admin: admin,
        clearErrors: true,
      );
      return true;
    } on UnauthorizedAdminException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  /// Sends a password reset email.
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearErrors: true);

    try {
      await _repository.sendPasswordResetEmail(email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset link sent to $email. Please check your inbox.',
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send password reset email. Please try again.',
      );
      return false;
    }
  }

  /// Signs the admin out.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.signOut();
    state = const AuthState();
  }

  /// Clears any lingering error or success messages.
  void clearMessages() {
    state = state.copyWith(clearErrors: true);
  }
}

/// Global provider for the AuthController.
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
