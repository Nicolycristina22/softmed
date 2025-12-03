import 'package:flutter/material.dart';
import 'package:softmed/pages/dashboard_paciente_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/patients_page.dart';
import 'pages/medications_page.dart';
import 'pages/not_found_page.dart';
import 'pages/login_paciente_page.dart'; 

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardPage());

      case '/patients':
        return MaterialPageRoute(builder: (_) => const PatientsPage());

      case '/medications':
        return MaterialPageRoute(builder: (_) => const MedicationsPage());

      case '/loginPaciente':
  return MaterialPageRoute(builder: (_) => const LoginPacientePage());

case '/dashboardPaciente':
  return MaterialPageRoute(builder: (_) => const DashboardPacientePage());


      default:
        return MaterialPageRoute(builder: (_) => const NotFoundPage());
    }
  }
}
