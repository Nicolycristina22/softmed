// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_patient_page.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Pacientes"),
        elevation: 0,

        // 🔵 BOTÃO VOLTAR SEM CONFIRMAÇÃO
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/dashboard', (route) => false);
          },
        ),

        actions: [
          // Botão de adicionar paciente no appbar
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPatientPage()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Campo de pesquisa (nome ou CPF)
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Pesquisar por nome ou CPF...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // StreamBuilder dos pacientes
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("pacientes")
                    .orderBy("Nome")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Erro ao carregar dados"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  // Filtrar por nome (string) ou CPF (numérico -> string)
                  final filtered = docs.where((doc) {
                    final nome = (doc.get("Nome") ?? "").toString().toLowerCase();
                    final cpfField = doc.data().toString().contains("CPF")
                        ? (doc.get("CPF") ?? "").toString()
                        : "";
                    // cpf pode ser number no banco, convert para string sem pontuacao
                    final cpfNormalized =
                        cpfField.replaceAll(RegExp(r'[^0-9]'), '');

                    final q = searchQuery.replaceAll(RegExp(r'[^0-9a-z]'), '');

                    return nome.contains(q) ||
                        cpfNormalized.contains(q) ||
                        cpfField.toLowerCase().contains(q);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        "Nenhum paciente encontrado.",
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index] as QueryDocumentSnapshot;
                      return _buildPatientCard(doc);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cartão do paciente (estilo dashboard)
  Widget _buildPatientCard(QueryDocumentSnapshot doc) {
    // Ler campos com segurança (existência)
    final nome = doc.data().toString().contains("Nome") ? doc.get("Nome") : "";
    final cpfRaw = doc.data().toString().contains("CPF") ? doc.get("CPF") : "";
    final cpf = cpfRaw?.toString() ?? "";
    final doenca = doc.data().toString().contains("Doença") ? doc.get("Doença") : "";
    final nascimento = doc.data().toString().contains("Nascimento")
        ? (doc.get("Nascimento") as Timestamp?)?.toDate()
        : null;

    final medicamentos = <Map<String, dynamic>>[];
    if (doc.data().toString().contains("medicacoes")) {
      try {
        final meds = doc.get("medicacoes");
        if (meds is List) {
          for (final m in meds) {
            if (m is Map) {
              medicamentos.add(Map<String, dynamic>.from(m));
            }
          }
        }
      } catch (e) {
        // ignora se não existir ou formato diferente
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Expanded(
              child: Text(
                nome ?? "",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Botão editar
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddPatientPage(
                      docId: doc.id,
                      initialData: doc.data() as Map<String, dynamic>?,
                    ),
                  ),
                );
              },
            ),
            // Botão excluir (opcional)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Excluir paciente?"),
                    content: const Text("Deseja realmente excluir este paciente?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Excluir")),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirebaseFirestore.instance.collection("pacientes").doc(doc.id).delete();
                }
              },
            )
          ],
        ),
        const SizedBox(height: 6),
        Text("CPF: $cpf"),
        Text("Doença: ${doenca ?? ''}"),
        Text("Remédios: ${medicamentos.map((m) => m['nome']).join(', ')}"),
        if (nascimento != null)
          Text(
            "Nascimento: ${nascimento.day.toString().padLeft(2, '0')}/${nascimento.month.toString().padLeft(2, '0')}/${nascimento.year}",
          ),
        const SizedBox(height: 10),
        // Lista compacta de medicações e horários
        if (medicamentos.isNotEmpty) ...[
          const Divider(),
          ...medicamentos.map((m) {
            final nomeMed = m['nome'] ?? '';
            final horario = m['horario'] ?? '';
            final dias = (m['dias'] is List) ? (m['dias'] as List).join(', ') : '';
            final quantidade = m['quantidade'] ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text("$nomeMed — $horario (${dias})")),
                  Text("Qtd: $quantidade"),
                ],
              ),
            );
          }).toList(),
        ]
      ]),
    );
  }
}

