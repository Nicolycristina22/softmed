import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MedicationFormPage extends StatefulWidget {
  final String? id;
  final String? nome;
  final String? categoria;
  final String? estoque;
  final String? descricao;

  const MedicationFormPage({
    super.key,
    this.id,
    this.nome,
    this.categoria,
    this.estoque,
    this.descricao,
  });

  @override
  State<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController categoriaController = TextEditingController();
  final TextEditingController estoqueController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nomeController.text = widget.nome ?? "";
    categoriaController.text = widget.categoria ?? "";
    estoqueController.text = widget.estoque ?? "";
    descricaoController.text = widget.descricao ?? "";
  }

  Future<void> salvar() async {
    final dados = {
      "nome": nomeController.text,
      "categoria": categoriaController.text,
      "estoque": int.tryParse(estoqueController.text) ?? 0,
      "descricao": descricaoController.text,
    };

    if (widget.id == null) {
      // Criar novo
      await FirebaseFirestore.instance.collection("medications").add(dados);
    } else {
      // Atualizar existente
      await FirebaseFirestore.instance
          .collection("medications")
          .doc(widget.id)
          .update(dados);
    }

    // Voltar para a lista de medicamentos
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/medications', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.id == null ? "Adicionar Medicamento" : "Editar Medicamento"),
        backgroundColor: Colors.blue,

        // Botão voltar direto para medicamentos
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/medications', (route) => false);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTextField(nomeController, "Nome"),
            _buildTextField(categoriaController, "Categoria"),
            _buildTextField(estoqueController, "Estoque", keyboardType: TextInputType.number),
            _buildTextField(descricaoController, "Descrição", maxLines: 3),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: salvar,
                child: Text(
                  widget.id == null ? "Adicionar" : "Salvar alterações",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

