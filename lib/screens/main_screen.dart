// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'home_screen.dart';
import 'historial_viajes_screen.dart';
import 'soporte_screen.dart';
import 'perfil_screen.dart';

/// Pantalla principal con BottomNavigationBar
/// Maneja la navegación entre las 4 secciones principales de la app:
/// - Inicio
/// - Mis Viajes
/// - Soporte
/// - Perfil
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Lista de pantallas correspondientes a cada tab
  // IndexedStack mantiene el estado de cada pantalla
  final List<Widget> _screens = const [
    HomeScreen(),
    HistorialViajesScreen(),
    SoporteScreen(),
    PerfilScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene el estado de cada pantalla
      // Evita que se reconstruyan al cambiar de tab
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // Barra de navegación personalizada
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}