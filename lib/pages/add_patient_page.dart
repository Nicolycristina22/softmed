import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// -------------------------
// MODEL MedicationEntry
// -------------------------
class MedicationEntry {
  String nome;
  String horario;
  List<String> dias;
  int quantidade;
  String? obs;

  MedicationEntry({
    required this.nome,
    required this.horario,
    required this.dias,
    required this.quantidade,
    this.obs,
  });

  Map<String, dynamic> toMap() {
    return {
      "nome": nome,
      "horario": horario,
      "dias": dias,
      "quantidade": quantidade,
      "obs": obs ?? "",
    };
  }

  static MedicationEntry fromMap(Map<String, dynamic> map) {
    return MedicationEntry(
      nome: map['nome'] ?? '',
      horario: map['horario'] ?? '',
      dias: List<String>.from(map['dias'] ?? []),
      quantidade: (map['quantidade'] is int)
          ? map['quantidade']
          : int.tryParse("${map['quantidade']}") ?? 0,
      obs: map['obs'] ?? '',
    );
  }
}

// -------------------------
// PAGE AddPatientPage
// -------------------------
class AddPatientPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initialData;

  const AddPatientPage({super.key, this.docId, this.initialData});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController doencaController = TextEditingController();
  DateTime? nascimento;

  // NOVOS CAMPOS
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  List<MedicationEntry> medicacoes = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      final data = widget.initialData!;

      nomeController.text = data['Nome'] ?? '';
      cpfController.text = (data['CPF'] ?? '').toString();
      doencaController.text = data['Doença'] ?? '';

      if (data['Nascimento'] is Timestamp) {
        nascimento = (data['Nascimento'] as Timestamp).toDate();
      }

      emailController.text = data['email'] ?? "";
      senhaController.text = data['senha'] ?? "";

      if (data['medicacoes'] is List) {
        medicacoes = (data['medicacoes'] as List)
            .map((e) => MedicationEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
  }

  Future<void> pickNascimento() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: nascimento ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        nascimento = picked;
      });
    }
  }

  Future<String?> pickTime(String initial) async {
    final parts = initial.split(':');
    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = int.tryParse(parts[1]) ?? 0;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (t != null) {
      return t.hour.toString().padLeft(2, '0') +
          ':' +
          t.minute.toString().padLeft(2, '0');
    }
    return null;
  }

  // -------------------------------------
  // 🔥 MÉDICO CADASTRA PACIENTE COMPLETO
  // -------------------------------------
  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    // SE FOR CRIAÇÃO NORMAL
    if (widget.docId == null) {
      try {
        // 🔥 1 - criar usuário no Firebase Auth
        final user = await _auth.createUserWithEmail(
          email: emailController.text.trim(),
          password: senhaController.text.trim(),
        );

        if (user == null) {
          throw Exception("Erro ao criar conta do paciente.");
        }

        // 🔥 2 - montar dados para salvar no Firestore
        final data = {
          "Nome": nomeController.text,
          "CPF": cpfController.text,
          "Doença": doencaController.text,
          "Nascimento":
              nascimento != null ? Timestamp.fromDate(nascimento!) : null,
          "email": emailController.text,
          "senha": senhaController.text, // se quiser, pode remover
          "uid": user.uid,
          "medicacoes": medicacoes.map((m) => m.toMap()).toList(),
        };

        // 🔥 3 - salvar no doc do UID
        await FirebaseFirestore.instance
            .collection("pacientes")
            .doc(user.uid)
            .set(data);

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${e.toString()}")),
        );
      }
    }

    // SE FOR EDIÇÃO
    else {
      final data = {
        "Nome": nomeController.text,
        "CPF": cpfController.text,
        "Doença": doencaController.text,
        "Nascimento":
            nascimento != null ? Timestamp.fromDate(nascimento!) : null,
        "email": emailController.text,
        "senha": senhaController.text,
        "medicacoes": medicacoes.map((m) => m.toMap()).toList(),
      };

      await FirebaseFirestore.instance
          .collection("pacientes")
          .doc(widget.docId)
          .update(data);

      Navigator.pop(context);
    }
  }

  // --------------------------------------------------

  final List<String> diasSemana = [
    "Segunda",
    "Terça",
    "Quarta",
    "Quinta",
    "Sexta",
    "Sábado",
    "Domingo"
  ];

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.docId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(isEditing ? "Editar Paciente" : "Novo Paciente"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // CAMPOS DOS DADOS
              TextFormField(
                controller: nomeController,
                decoration: _fieldDecoration("Nome"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Informe o nome" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: cpfController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration("CPF"),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: doencaController,
                decoration: _fieldDecoration("Doença"),
              ),
              const SizedBox(height: 12),

              // NOVOS CAMPOS
              TextFormField(
                controller: emailController,
                decoration: _fieldDecoration("Email do Paciente"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Informe o email" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: senhaController,
                decoration: _fieldDecoration("Senha do Paciente"),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Informe a senha" : null,
              ),

              const SizedBox(height: 12),

              // DATA DE NASCIMENTO
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: _fieldDecoration("Nascimento"),
                      child: TextButton(
                        onPressed: pickNascimento,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            nascimento == null
                                ? "Selecionar data"
                                : "${nascimento!.day}/${nascimento!.month}/${nascimento!.year}",
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ---------------------------
              // MEDICAÇÕES
              // ---------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Medicamentos",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        medicacoes.add(MedicationEntry(
                          nome: "",
                          horario: "00:00",
                          dias: [],
                          quantidade: 1,
                          obs: "",
                        ));
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Adicionar"),
                  )
                ],
              ),

              const SizedBox(height: 12),

              ...List.generate(medicacoes.length, (index) {
                final m = medicacoes[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: m.nome,
                          decoration: _fieldDecoration("Nome do medicamento"),
                          onChanged: (v) => m.nome = v,
                        ),
                        const SizedBox(height: 8),

                        TextFormField(
                          initialValue: m.quantidade.toString(),
                          decoration:
                              _fieldDecoration("Quantidade (estoque)"),
                          keyboardType: TextInputType.number,
                          onChanged: (v) =>
                              m.quantidade = int.tryParse(v) ?? 0,
                        ),

                        const SizedBox(height: 8),

                        // Horário
                        Row(
                          children: [
                            Expanded(
                              child: InputDecorator(
                                decoration: _fieldDecoration("Horário"),
                                child: TextButton(
                                  onPressed: () async {
                                    final picked =
                                        await pickTime(m.horario);
                                    if (picked != null) {
                                      setState(() {
                                        m.horario = picked;
                                      });
                                    }
                                  },
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(m.horario),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: diasSemana.map((dia) {
                            final selected = m.dias.contains(dia);
                            return FilterChip(
                              label: Text(dia),
                              selected: selected,
                              onSelected: (sel) {
                                setState(() {
                                  sel
                                      ? m.dias.add(dia)
                                      : m.dias.remove(dia);
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          initialValue: m.obs ?? "",
                          decoration: _fieldDecoration("Observações"),
                          onChanged: (v) => m.obs = v,
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  medicacoes.removeAt(index);
                                });
                              },
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              label: const Text("Remover",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                    isEditing ? "Salvar alterações" : "Cadastrar paciente"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
