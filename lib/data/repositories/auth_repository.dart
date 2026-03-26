import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../datasources/remote/supabase_client.dart';
import '../../core/errors/exceptions.dart';
import '../../core/services/biometric_service.dart';

class AuthRepository {
  final _auth = SupabaseConfig.auth;
  final _biometrics = BiometricService();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<bool> isBiometricAvailable() => _biometrics.isBiometricAvailable();

  Future<bool> authenticateWithBiometrics() => _biometrics.authenticate();

  // Email / Password login
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response.user;
    } on AuthException catch (e) {
      throw AppAuthException(
        message: _parseAuthError(e.message),
        code: e.statusCode,
      );
    } catch (e) {
      throw AppAuthException(message: 'Erro ao fazer login. Tente novamente.');
    }
  }

  // Email / Password register
  Future<User?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );
      return response.user;
    } on AuthException catch (e) {
      throw AppAuthException(
        message: _parseAuthError(e.message),
        code: e.statusCode,
      );
    } catch (e) {
      throw AppAuthException(message: 'Erro ao criar conta. Tente novamente.');
    }
  }

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null)
        throw AppAuthException(message: 'Token Google inválido');

      final response = await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return response.user;
    } on AuthException catch (e) {
      throw AppAuthException(message: _parseAuthError(e.message));
    } catch (e) {
      throw AppAuthException(
        message: 'Erro ao entrar com Google. Tente novamente.',
      );
    }
  }

  // Forgot password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AppAuthException(message: _parseAuthError(e.message));
    }
  }

  // Resend confirmation email
  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
    } on AuthException catch (e) {
      throw AppAuthException(
        message: _parseAuthError(e.message),
        code: e.statusCode,
      );
    } catch (e) {
      throw AppAuthException(
        message: 'Erro ao reenviar e-mail de confirmação.',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AppAuthException(message: 'Erro ao sair da conta.');
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw AppAuthException(message: _parseAuthError(e.message));
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await SupabaseConfig.client.rpc('delete_user');
      await signOut();
    } catch (e) {
      throw AppAuthException(
          message: 'Erro ao excluir conta. Contate o suporte.');
    }
  }

  String _parseAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'E-mail ou senha incorretos';
    }
    if (message.contains('Email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar';
    }
    if (message.contains('User already registered')) {
      return 'Este e-mail já está cadastrado';
    }
    if (message.contains('Password should be')) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }
    return message;
  }
}

