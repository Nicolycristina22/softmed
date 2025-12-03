import 'package:flutter/material.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página Não Encontrada'),
      ),
      body: const Center(
        child: Text(
          'Erro 404 — Página não encontrada',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
