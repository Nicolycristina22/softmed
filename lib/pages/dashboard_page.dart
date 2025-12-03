import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppNavigation extends StatelessWidget {
  final String currentRoute;
  const AppNavigation({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    Widget navItem(IconData icon, String label, String route) {
      final bool active = route == currentRoute;
      return InkWell(
        onTap: () {
          if (!active) Navigator.pushReplacementNamed(context, route);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: active ? Colors.blue.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: active ? Colors.blue : Colors.grey[700]),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.blue[800] : Colors.grey[800],
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Future<void> _confirmLogout() async {
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
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        }
      }
    }

    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2B7AFF), Color(0xFF00C389)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.monitor_heart, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                'SoftMed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          navItem(Icons.dashboard, 'Dashboard', '/dashboard'),
          const SizedBox(height: 6),
          navItem(Icons.people, 'Pacientes', '/patients'),
          const SizedBox(height: 6),
          navItem(Icons.medication, 'Medicamentos', '/medications'),
          const Spacer(),
          InkWell(
            onTap: _confirmLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red[400]),
                  const SizedBox(width: 12),
                  Text(
                    'Sair',
                    style: TextStyle(
                      color: Colors.red[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              'v1.0.0',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> upcomingMedications = [];

  @override
  void initState() {
    super.initState();
    loadMedications();
  }

  Future<void> loadMedications() async {
    final query =
        await FirebaseFirestore.instance.collection("pacientes").get();

    List<Map<String, dynamic>> meds = [];

    for (var doc in query.docs) {
      final data = doc.data();

      final String patientName = data["Nome"] ?? "";
      final List medsList = data["medicacoes"] ?? [];

      for (var med in medsList) {
        meds.add({
          "patient": patientName,
          "medication": med["nome"],
          "time": med["horario"],
          "dias": med["dias"],
        });
      }
    }

    meds.sort((a, b) {
      final t1 = a["time"];
      final t2 = b["time"];
      return t1.compareTo(t2);
    });

    setState(() {
      upcomingMedications = meds;
    });
  }

  String _formattedDate() {
    final now = DateTime.now();

    const weekdays = [
      "domingo",
      "segunda",
      "terça",
      "quarta",
      "quinta",
      "sexta",
      "sábado"
    ];

    const months = [
      "janeiro",
      "fevereiro",
      "março",
      "abril",
      "maio",
      "junho",
      "julho",
      "agosto",
      "setembro",
      "outubro",
      "novembro",
      "dezembro"
    ];

    final dayName = weekdays[now.weekday % 7];
    final day = now.day;
    final month = months[now.month - 1];
    final year = now.year;

    return "$dayName, $day de $month de $year";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: Row(
        children: [
          const AppNavigation(currentRoute: '/dashboard'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Visão geral das próximas medicações - ${_formattedDate()}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.access_time),
                              SizedBox(width: 8),
                              Text(
                                "Próximas Medicações",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (upcomingMedications.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("Nenhuma medicação cadastrada."),
                              ),
                            )
                          else
                            Column(
                              children: upcomingMedications.map((med) {
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                            ),
                                            child: const Icon(Icons.medication,
                                                color: Colors.blue),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                med["patient"],
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                med["medication"],
                                                style: TextStyle(
                                                    color: Colors.grey[700]),
                                              ),
                                              Text("Horário: ${med["time"]}"),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

