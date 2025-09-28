import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../constants/terms_and_conditions.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.titulo,
            size: 20,
          ),
        ),
        title: const Text(
          'Términos y Condiciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.titulo,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.principal,
          unselectedLabelColor: AppColors.subtitulo,
          indicatorColor: AppColors.principal,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Términos y Condiciones'),
            Tab(text: 'Política de Privacidad'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Términos y Condiciones
          _buildTermsTab(),
          // Tab 2: Política de Privacidad
          _buildPrivacyTab(),
        ],
      ),
    );
  }

  Widget _buildTermsTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.principal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.principal.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.principal,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lee cuidadosamente nuestros términos antes de usar la aplicación',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.principal,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Contenido scrolleable
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SelectableText(
                  TermsAndConditions.termsText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.titulo,
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Botón de aceptar (opcional)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Puedes aceptar los términos en el formulario de registro'),
                    backgroundColor: AppColors.principal,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.principal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secundario.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secundario.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: AppColors.secundario,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tu privacidad es importante para nosotros',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secundario,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Contenido scrolleable
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SelectableText(
                  TermsAndConditions.privacyPolicyText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.titulo,
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Información de contacto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gris50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contacto para temas de privacidad',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.titulo,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'soporte@plisusuario.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.principal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+57 (1) 234-5678',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.subtitulo,
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
