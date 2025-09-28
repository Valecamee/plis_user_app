import 'package:flutter/material.dart';
import 'package:plis_user/widgets/common/logo.dart';
import 'package:plis_user/widgets/common/slogan_text.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/link_text.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../widgets/common/gradient_background.dart'; // 👈 importa tu GradientBackground

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _goToRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        color1: AppColors.oceano,
        color2: AppColors.gris800,
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

                // Logo
                const Logo(),

                const Spacer(flex: 1),

                // Slogan
                const SloganText(),

                const SizedBox(height: 20),

                // Descripción
                const Column(
                  children: [
                    Text(
                      "Conecta con conductores verificados",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.indigoSuave,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Encuentra viajes seguros y económicos hacia tu destino",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.gris100,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // Botón principal
                GradientButton(
                  text: 'Crear cuenta',
                  onTap: () => _goToRegister(context),
                  colors: [AppColors.principal, AppColors.secundario], // verde neón a azul eléctrico

                ),

                const SizedBox(height: 24),

                // Link para login
                LinkText(
                  text1: "¿Ya tienes una cuenta? ",
                  text2: "Iniciar sesión",
                  colorText1: AppColors.indigoSuave,
                  colorText2: AppColors.principal,
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
