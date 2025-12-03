import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class DashboardPacientePage extends StatefulWidget {
  const DashboardPacientePage({super.key});

  @override
  State<DashboardPacientePage> createState() => _DashboardPacientePageState();
}

class _DashboardPacientePageState extends State<DashboardPacientePage> {
  String? uid;
  DocumentSnapshot? pacienteData;

  Timer? timer;
  List<int> notificacoesEnviadas = [];

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
    _loadPacienteData();

    timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _verificarNotificacoes();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPacienteData() async {
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("pacientes")
        .doc(uid)
        .get();

    if (doc.exists) {
      setState(() => pacienteData = doc);
    }
  }

  bool estaAtrasado(String horario) {
    final agora = TimeOfDay.now();

    final partes = horario.split(":");
    final hora = int.parse(partes[0]);
    final minuto = int.parse(partes[1]);

    final horarioRemedio = TimeOfDay(hour: hora, minute: minuto);

    if (agora.hour > horarioRemedio.hour) return true;
    if (agora.hour == horarioRemedio.hour && agora.minute > horarioRemedio.minute) return true;

    return false;
  }

  void exibirNotificacao(String mensagem, Color cor) {
    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 30,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.25),
                    blurRadius: 10,
                    offset: const Offset(2, 4),
                  )
                ],
              ),
              child: Text(
                mensagem,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  void _verificarNotificacoes() {
    if (pacienteData == null) return;

    final meds = pacienteData!["medicacoes"] as List;
    final agora = TimeOfDay.now();

    for (int i = 0; i < meds.length; i++) {
      final med = meds[i];
      final partes = med["horario"].split(":");
      final hora = int.parse(partes[0]);
      final minuto = int.parse(partes[1]);

      final horario = TimeOfDay(hour: hora, minute: minuto);

      if (notificacoesEnviadas.contains(i)) continue;

      if (horario.hour == agora.hour &&
          (horario.minute - agora.minute).abs() <= 5 &&
          agora.minute < horario.minute) {
        notificacoesEnviadas.add(i);
        exibirNotificacao(
          "⏰ Está quase na hora de tomar: ${med["nome"]}",
          Colors.blue,
        );
      }

      if (horario.hour == agora.hour && horario.minute == agora.minute) {
        notificacoesEnviadas.add(i);
        exibirNotificacao(
          "💊 Hora de tomar seu medicamento: ${med["nome"]}",
          Colors.green,
        );
      }

      if (estaAtrasado(med["horario"]) && med["tomado"] != true) {
        notificacoesEnviadas.add(i);
        exibirNotificacao(
          "⚠️ Você está ATRASADA para: ${med["nome"]}",
          Colors.red,
        );
      }
    }
  }

  Future<void> marcarComoTomado(int index) async {
    List meds = pacienteData!["medicacoes"];
    meds[index]["tomado"] = true;

    await FirebaseFirestore.instance
        .collection("pacientes")
        .doc(uid)
        .update({"medicacoes": meds});

    _loadPacienteData();
  }

  List<Map<String, dynamic>> getProximasDoses(List meds) {
    List<Map<String, dynamic>> futuras = [];

    final agora = TimeOfDay.now();

    for (var m in meds) {
      final partes = m["horario"].split(":");
      final hora = int.parse(partes[0]);
      final minuto = int.parse(partes[1]);

      final horario = TimeOfDay(hour: hora, minute: minuto);

      final aindaHoje = (horario.hour > agora.hour) ||
          (horario.hour == agora.hour && horario.minute > agora.minute);

      if (aindaHoje) futuras.add(m);
    }

    futuras.sort((a, b) {
      final pa = a["horario"].split(":");
      final pb = b["horario"].split(":");

      return (int.parse(pa[0]) * 60 + int.parse(pa[1]))
          .compareTo(int.parse(pb[0]) * 60 + int.parse(pb[1]));
    });

    return futuras;
  }

  // 🔵 CONFIRMAÇÃO DE SAIR (BOTÃO DE VOLTAR)
  Future<void> _confirmarLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Sair do SoftMed",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blueAccent),
          ),
          content: const Text(
            "Você deseja realmente sair do SoftMed?",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar", style: TextStyle(fontSize: 16)),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Sair", style: TextStyle(fontSize: 16)),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pacienteData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final meds = pacienteData!["medicacoes"] as List;
    final proximas = getProximasDoses(meds);

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),

      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _confirmarLogout,
        ),

        title: const Text("Painel do Paciente"),
        actions: const [],
      ),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "Olá, ${pacienteData!["Nome"]}",
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Seus medicamentos de hoje:",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                Expanded(
                  child: ListView(
                    children: [
                      if (proximas.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.08),
                                blurRadius: 6,
                                offset: const Offset(2, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Próximas doses",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              for (var p in proximas)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    "• ${p["nome"]} às ${p["horario"]}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                )
                            ],
                          ),
                        ),

                      ...List.generate(meds.length, (index) {
                        final med = meds[index];
                        final bool tomado = med["tomado"] == true;
                        final bool atrasado =
                            !tomado && estaAtrasado(med["horario"]);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: tomado
                                ? Colors.green.shade100
                                : atrasado
                                    ? Colors.red.shade100
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.1),
                                blurRadius: 6,
                                offset: const Offset(2, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med["nome"],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text("Horário: ${med["horario"]}",
                                  style: const TextStyle(fontSize: 16)),

                              const SizedBox(height: 6),

                              Text("Observação: ${med["obs"]}",
                                  style: const TextStyle(fontSize: 15)),

                              const SizedBox(height: 10),

                              if (atrasado)
                                const Text(
                                  "⚠️ ATRASADO",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                              if (!tomado)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () => marcarComoTomado(index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                    ),
                                    child: const Text(
                                      "Marcar como tomado",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),

                              if (tomado)
                                const Text(
                                  "✔ Remédio tomado",
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 16),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

