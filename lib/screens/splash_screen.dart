import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // ✅ AGREGAR ESTE IMPORT
import '../utils/app_colors.dart';
import 'auth/welcome_screen.dart';
import 'main_screen.dart';  // ✅ AGREGAR ESTE IMPORT
import '../widgets/common/logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();  // ✅ CAMBIADO: ahora verifica la autenticación
  }

  // ✅ NUEVO MÉTODO: Verifica si hay sesión activa
  Future<void> _checkAuthAndNavigate() async {
    // Esperar 3 segundos para mostrar el splash
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Verificar si hay un usuario autenticado
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // ✅ HAY SESIÓN ACTIVA → Ir a MainScreen
      print('✅ Usuario ya autenticado: ${currentUser.email}');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // ❌ NO HAY SESIÓN → Ir a WelcomeScreen
      print('❌ No hay sesión activa, ir a Welcome');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.principal,
              AppColors.secundario,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Logo(),
              SizedBox(height: 20),
              Text(
                'Plis Usuario',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tu compañero de viaje',  // ✅ Arreglé el encoding aquí también
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}