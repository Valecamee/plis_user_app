// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
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

      // BottomNavigationBar con sombra superior
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.principal,
          unselectedItemColor: AppColors.gris400,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: 'Mis Viajes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.support_agent_outlined),
              activeIcon: Icon(Icons.support_agent),
              label: 'Soporte',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}