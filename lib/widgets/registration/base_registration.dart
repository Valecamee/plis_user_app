import 'package:flutter/material.dart';
import '../common/gradient_button.dart';
import '../../utils/colors.dart';

// Widget base para las pantallas con el diseño común
class BaseRegistrationScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String buttonText;
  final bool buttonEnabled;

  const BaseRegistrationScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onNext,
    this.onBack,
    this.buttonText = 'Siguiente',
    this.buttonEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Degradado superior más pequeño
          Container(
            height: MediaQuery.of(context).size.height * 0.25, // Reducido de 0.4 a 0.25
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.principal,
                  AppColors.secundario,
                  Colors.white.withOpacity(0.0),
                ],
                stops: [0.0, 0.7, 1.0],
              ),
            ),
          ),

          // Botón de regreso
          if (onBack != null)
            SafeArea(
              child: Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Espaciado para el degradado más pequeño
                SizedBox(height: MediaQuery.of(context).size.height * 0.08), // Reducido

                // Tarjeta de contenido
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Título y subtítulo
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.titulo,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.subtitulo,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 32),

                        // Contenido específico de cada pantalla
                        Expanded(child: child),

                        // Botón principal
                        SizedBox(height: 24),
                        GradientButton(
                          text: buttonText,
                          onTap: buttonEnabled ? onNext : null,
                          enabled: buttonEnabled,
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
