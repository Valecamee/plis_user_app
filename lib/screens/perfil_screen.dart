// lib/screens/perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import 'auth/welcome_screen.dart';
import 'auth/terms_screen.dart';

/// Pantalla de Perfil del Usuario
/// Muestra información personal y opciones de configuración
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.principal, AppColors.secundario, Colors.white],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con foto de perfil
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.principal,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nombre
                    Text(
                      user?.displayName ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Email
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Badge de verificación
                    if (user?.emailVerified ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.exito.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.exito,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Verificado',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Contenido
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sección: Cuenta
                        const Text(
                          'Mi Cuenta',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.subtitulo,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildOptionTile(
                          context,
                          icon: Icons.person_outline,
                          title: 'Editar Perfil',
                          subtitle: 'Actualiza tu información',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Función próximamente'),
                              ),
                            );
                          },
                        ),

                        _buildOptionTile(
                          context,
                          icon: Icons.verified_user_outlined,
                          title: 'Verificación',
                          subtitle: 'Verifica tu identidad',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Función próximamente'),
                              ),
                            );
                          },
                        ),

                        _buildOptionTile(
                          context,
                          icon: Icons.payment_outlined,
                          title: 'Métodos de Pago',
                          subtitle: 'Administra tus pagos',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Función próximamente'),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Sección: Preferencias
                        const Text(
                          'Preferencias',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.subtitulo,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildOptionTile(
                          context,
                          icon: Icons.notifications_outlined,
                          title: 'Notificaciones',
                          subtitle: 'Configura tus alertas',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Función próximamente'),
                              ),
                            );
                          },
                        ),

                        _buildOptionTile(
                          context,
                          icon: Icons.security_outlined,
                          title: 'Privacidad y Seguridad',
                          subtitle: 'Protege tu cuenta',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Función próximamente'),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Sección: Legal
                        const Text(
                          'Legal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.subtitulo,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildOptionTile(
                          context,
                          icon: Icons.description_outlined,
                          title: 'Términos y Condiciones',
                          subtitle: 'Lee nuestros términos',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TermsScreen(),
                              ),
                            );
                          },
                        ),

                        _buildOptionTile(
                          context,
                          icon: Icons.info_outline,
                          title: 'Acerca de',
                          subtitle: 'Versión 1.0.0',
                          onTap: () {
                            _showAboutDialog(context);
                          },
                        ),

                        const SizedBox(height: 32),

                        // Botón de cerrar sesión
                        _buildLogoutButton(context),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.gris50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.principal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.principal, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.titulo,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.subtitulo,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.gris400,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleLogout(context),
        icon: const Icon(Icons.logout),
        label: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthService().signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        ),
            (route) => false,
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.principal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: AppColors.principal,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Acerca de Plis Usuario'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Plis Usuario',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.titulo,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Versión: 1.0.0',
              style: TextStyle(color: AppColors.subtitulo),
            ),
            SizedBox(height: 16),
            Text(
              'Aplicación de viajes compartidos que conecta pasajeros con conductores verificados.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.subtitulo,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '© 2025 Plis Usuario',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gris400,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}