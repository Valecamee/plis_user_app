// lib/screens/soporte_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';

/// Pantalla de Soporte Técnico
/// Proporciona canales de contacto para ayudar al usuario
class SoporteScreen extends StatelessWidget {
  const SoporteScreen({Key? key}) : super(key: key);

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
              AppColors.gris50
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Icon(
                      Icons.support_agent,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Soporte Técnico',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '¿Cómo podemos ayudarte?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
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
                      children: [
                        _buildSupportCard(
                          context,
                          icon: Icons.help_outline,
                          title: 'Preguntas Frecuentes',
                          subtitle: 'Encuentra respuestas rápidas',
                          color: AppColors.informacion,
                          onTap: () => _showFAQ(context),
                        ),
                        _buildSupportCard(
                          context,
                          icon: Icons.email_outlined,
                          title: 'Enviar Email',
                          subtitle: 'soporte@plisusuario.com',
                          color: AppColors.principal,
                          onTap: () => _launchEmail(context),
                        ),
                        _buildSupportCard(
                          context,
                          icon: Icons.phone_outlined,
                          title: 'Llamar a Soporte',
                          subtitle: '+57 (1) 234-5678',
                          color: AppColors.secundario,
                          onTap: () => _launchPhone(context),
                        ),
                        _buildSupportCard(
                          context,
                          icon: Icons.chat_bubble_outline,
                          title: 'WhatsApp',
                          subtitle: 'Chatea con nosotros',
                          color: const Color(0xFF25D366),
                          onTap: () => _launchWhatsApp(context),
                        ),
                        _buildSupportCard(
                          context,
                          icon: Icons.bug_report_outlined,
                          title: 'Reportar Problema',
                          subtitle: 'Cuéntanos qué pasó',
                          color: AppColors.advertencia,
                          onTap: () => _showReportDialog(context),
                        ),

                        const SizedBox(height: 32),

                        // Información adicional
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.gris50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: AppColors.subtitulo,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Horario de atención',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.titulo,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Lunes a Viernes: 8:00 AM - 6:00 PM\nSábados: 9:00 AM - 2:00 PM',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.subtitulo,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildSupportCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.titulo,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.subtitulo,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.gris400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFAQ(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gris300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Preguntas Frecuentes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titulo,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    _FAQItem(
                      question: '¿Cómo reservar un viaje?',
                      answer: 'Busca el viaje que te interesa en la pantalla de inicio, revisa los detalles y presiona "Reservar viaje".',
                    ),
                    _FAQItem(
                      question: '¿Cómo cancelar una reserva?',
                      answer: 'Ve a "Mis Viajes", selecciona el viaje que deseas cancelar y presiona el botón de cancelar.',
                    ),
                    _FAQItem(
                      question: '¿Qué hago si el conductor no llega?',
                      answer: 'Contacta al conductor por la app. Si no responde, reporta el problema a través de Soporte.',
                    ),
                    _FAQItem(
                      question: '¿Cómo calificar un viaje?',
                      answer: 'Después de completar el viaje, recibirás una notificación para calificar al conductor.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'soporte@plisusuario.com',
      query: 'subject=Soporte Plis Usuario',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showError(context, 'No se pudo abrir el cliente de correo');
      }
    } catch (e) {
      _showError(context, 'Error al abrir correo: $e');
    }
  }

  void _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+5712345678');

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showError(context, 'No se pudo realizar la llamada');
      }
    } catch (e) {
      _showError(context, 'Error al realizar llamada: $e');
    }
  }

  void _launchWhatsApp(BuildContext context) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/5712345678');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        _showError(context, 'No se pudo abrir WhatsApp');
      }
    } catch (e) {
      _showError(context, 'Error al abrir WhatsApp: $e');
    }
  }

  void _showReportDialog(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar Problema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Describe el problema que estás experimentando:'),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe el problema...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reporte enviado. Te contactaremos pronto.'),
                  backgroundColor: AppColors.exito,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.principal,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.gris50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.question,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.titulo,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.principal,
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.answer,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.subtitulo,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}