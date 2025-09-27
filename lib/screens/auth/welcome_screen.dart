import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/link_text.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _goToRegister(BuildContext context) {
    print("🔥 Intentando ir a Register...");
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _goToLogin(BuildContext context) {
    print("🔥 Intentando ir a Login...");
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.principal,
              AppColors.secundario,
              Colors.white,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Indicador superior
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Logo temporal (círculo con icono)
                Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 80,
                    color: AppColors.principal,
                  ),
                ),

                const Spacer(flex: 1),

                // Slogan
                Column(
                  children: [
                    Text(
                      "Viajar es",
                      style: TextStyle(
                        fontSize: 42.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.titulo,
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Compartir",
                      style: TextStyle(
                        fontSize: 42.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.white, // Cambiado a blanco
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Descripción
                Column(
                  children: [
                    Text(
                      "Conecta con conductores verificados",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.titulo,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Encuentra viajes seguros y económicos hacia tu destino",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.subtitulo,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // Botones
                GradientButton(
                  text: 'Crear cuenta',
                  onTap: () => _goToRegister(context),
                ),

                const SizedBox(height: 16),

                // Botón secundario para login
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => _goToLogin(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.principal, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.principal,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Link para login
                LinkText(
                  text1: "¿Ya tienes una cuenta? ",
                  text2: "Iniciar sesión",
                  colorText1: AppColors.subtitulo,
                  colorText2: AppColors.verdePlis,
                  onTap: () => _goToLogin(context),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}