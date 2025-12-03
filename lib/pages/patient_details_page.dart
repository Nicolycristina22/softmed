import 'package:flutter/material.dart';

class PatientDetailsPage extends StatelessWidget {
  final String nome;
  final String cpf;
  final String nascimento;

  const PatientDetailsPage({
    super.key,
    required this.nome,
    required this.cpf,
    required this.nascimento,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ficha de $nome"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nome: $nome", style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              Text("CPF: $cpf", style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              Text("Nascimento: $nascimento",
                  style: const TextStyle(fontSize: 20)),

              const SizedBox(height: 30),

              const Text(
                "Histórico, alergias, exames e observações médicas aparecem aqui...",
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

