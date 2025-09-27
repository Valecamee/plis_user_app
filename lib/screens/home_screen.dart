// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import 'auth/welcome_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      final authService = AuthService();
      await authService.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plis Usuario - Home'),
        backgroundColor: AppColors.principal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _handleSignOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: AppColors.exito,
            ),
            SizedBox(height: 20),
            Text(
              '¡Login exitoso!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Bienvenido a Plis Usuario',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.subtitulo,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Aquí desarrollaremos la funcionalidad principal',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.subtitulo,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}