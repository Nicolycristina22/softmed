// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// 🔹 Novo _submit com verificação de tipo
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // 1️⃣ Autentica no Firebase Auth
      final user = await _authService.signIn(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );

      if (user != null) {
        // 2️⃣ Busca o tipo de usuário no Firestore
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (!doc.exists) {
          _showMessage('Usuário não encontrado no sistema.');
          return;
        }

        final tipo = doc.data()?['tipo'] ?? 'medico';

        // 3️⃣ Redireciona de acordo com o tipo
        if (tipo == 'medico') {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else if (tipo == 'paciente') {
          Navigator.pushReplacementNamed(context, '/dashboardPaciente');
        } else {
          _showMessage('Tipo de usuário inválido.');
        }
      } else {
        _showMessage('Falha ao autenticar. Tente novamente.');
      }
    } on Exception catch (e) {
      _showMessage(_mapAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('wrong-password')) return 'Senha incorreta.';
    if (msg.contains('user-not-found')) return 'Usuário não encontrado.';
    if (msg.contains('invalid-email')) return 'Email inválido.';
    if (msg.contains('network-request-failed')) return 'Sem conexão.';
    return 'Erro ao autenticar. Verifique os dados e tente novamente.';
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth =
        width >= 1000 ? 480.0 : (width >= 600 ? 420.0 : width - 48.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F5FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2B7AFF), Color(0xFF00C389)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 8,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.monitor_heart,
                        color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'SoftMed',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sistema inteligente de gerenciamento médico',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 20),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Email',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          hintText: 'seu@email.com',
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe o email';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(v)) return 'Email inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Senha',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: '••••••••',
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe a senha';
                          if (v.length < 6)
                            return 'A senha precisa ter ao menos 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Ink(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [Color(0xFF276BFB), Color(0xFF00C389)]),
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              constraints:
                                  const BoxConstraints(minHeight: 44),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Entrar no Sistema',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Text('Sistema seguro para profissionais de saúde',
                          style: TextStyle(color: Colors.black45)),

                      // 🔹 BOTÃO ADICIONAL PARA LOGIN DO PACIENTE
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/loginPaciente');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            side: const BorderSide(
                                color: Color(0xFF276BFB), width: 2),
                          ),
                          child: const Text(
                            'Sou paciente',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF276BFB)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

