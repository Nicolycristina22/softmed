import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Login com email/senha
  Future<User?> signIn(String email, String password) async {
    final creds = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return creds.user;
  }

  // Criar conta normal
  Future<User?> signUp(String email, String password) async {
    final creds = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return creds.user;
  }

  // 🔥 Criar usuário ESPECIALMENTE para o médico cadastrar pacientes
  Future<User?> createUserWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final creds = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return creds.user;
    } on FirebaseAuthException catch (e) {
      throw Exception("Erro ao criar usuário: ${e.message}");
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Retorna usuário atual
  User? get currentUser => _auth.currentUser;

  // Stream de autenticação
  Stream<User?> authStateChanges() => _auth.authStateChanges();
}
