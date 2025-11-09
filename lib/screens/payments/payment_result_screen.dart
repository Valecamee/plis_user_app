import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/payment_constants.dart';
import '../../models/payment_model.dart';
import '../../models/travel_model.dart';
import '../historial_viajes_screen.dart';

/// Pantalla de resultado del pago (éxito o fallo)
class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final PaymentModel payment;
  final Travel travel;
  final String message;
  final Map<String, dynamic>? transactionData;

  const PaymentResultScreen({
    Key? key,
    required this.success,
    required this.payment,
    required this.travel,
    required this.message,
    this.transactionData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // NOTA: La reserva ya fue creada en el flujo de pago mediante
    // TravelBookingService o directamente en el proceso de pago
    // No es necesario crearla nuevamente aquí

    return PopScope(
      canPop: false, // No permitir volver atrás
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.principal,
                AppColors.secundario,
                AppColors.gris50,
              ],
              stops: [0.0, 0.3, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icono de resultado
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: success
                                  ? AppColors.exito.withOpacity(0.2)
                                  : AppColors.error.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              success
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              size: 80,
                              color: success ? AppColors.exito : AppColors.error,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Título
                          Text(
                            success ? '¡Pago exitoso!' : 'Pago rechazado',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          // Mensaje
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 40),

                          // Detalles del pago
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  success
                                      ? 'Detalles de la transacción'
                                      : 'Información del intento',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.titulo,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildDetailRow(
                                  'Viaje',
                                  '${travel.origen} → ${travel.destino}',
                                ),
                                _buildDetailRow(
                                  'Fecha',
                                  travel.fechaFormateada,
                                ),
                                _buildDetailRow(
                                  'Hora',
                                  travel.horaFormateada,
                                ),
                                _buildDetailRow(
                                  'Asientos',
                                  '${payment.seatsReserved}',
                                ),
                                const Divider(height: 24),
                                _buildDetailRow(
                                  'Monto total',
                                  PaymentConstants.formatearMonto(payment.amount),
                                  isHighlighted: true,
                                ),
                                if (success) ...[
                                  _buildDetailRow(
                                    'ID de transacción',
                                    payment.transactionId,
                                    isSmall: true,
                                  ),
                                ],
                                if (success && transactionData != null) ...[
                                  _buildDetailRow(
                                    'Referencia Wompi',
                                    transactionData!['id']?.toString() ?? 'N/A',
                                    isSmall: true,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          if (success) ...[
                            const SizedBox(height: 24),
                            _buildSuccessInfo(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Botones de acción
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlighted = false,
    bool isSmall = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 12 : 14,
              color: AppColors.subtitulo,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlighted ? 18 : (isSmall ? 12 : 14),
                fontWeight:
                    isHighlighted ? FontWeight.w700 : FontWeight.w600,
                color: isHighlighted ? AppColors.principal : AppColors.titulo,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.exito.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.exito.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.exito,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Tu reserva está confirmada!',
                  style: TextStyle(
                    color: AppColors.exito,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'El conductor ha sido notificado. Revisa tu historial de viajes para más detalles.',
                  style: TextStyle(
                    color: AppColors.exito.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gris600.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (success) ...[
              ElevatedButton.icon(
                onPressed: () => _navigateToHistory(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.principal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.history),
                label: const Text(
                  'Ver mis viajes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _navigateToHome(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.principal,
                  side: const BorderSide(color: AppColors.principal),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.home),
                label: const Text(
                  'Volver al inicio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _retry(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.principal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Intentar de nuevo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _navigateToHome(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.subtitulo,
                  side: const BorderSide(color: AppColors.subtitulo),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.cancel),
                label: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HistorialViajesScreen(),
      ),
      (route) => false,
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _retry(BuildContext context) {
    // Volver a la pantalla anterior (que debería ser el detalle del viaje)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
