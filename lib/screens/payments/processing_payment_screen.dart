import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/payment_model.dart';
import '../../models/travel_model.dart';
import '../../services/payment_service.dart';
import 'payment_result_screen.dart';

/// Pantalla de procesamiento de pago
class ProcessingPaymentScreen extends StatefulWidget {
  final PaymentModel payment;
  final Travel travel;
  final String cardNumber;
  final String cvc;
  final String expMonth;
  final String expYear;
  final String cardHolder;
  final String customerEmail;

  const ProcessingPaymentScreen({
    Key? key,
    required this.payment,
    required this.travel,
    required this.cardNumber,
    required this.cvc,
    required this.expMonth,
    required this.expYear,
    required this.cardHolder,
    required this.customerEmail,
  }) : super(key: key);

  @override
  State<ProcessingPaymentScreen> createState() =>
      _ProcessingPaymentScreenState();
}

class _ProcessingPaymentScreenState extends State<ProcessingPaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  String _statusMessage = 'Procesando pago...';
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    // Configurar animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Procesar pago
    _processPayment();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    try {
      setState(() {
        _statusMessage = 'Validando datos de la tarjeta...';
      });

      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _statusMessage = 'Conectando con el banco...';
      });

      // Procesar el pago
      final result = await PaymentService.processCardPayment(
        payment: widget.payment,
        cardNumber: widget.cardNumber,
        cvc: widget.cvc,
        expMonth: widget.expMonth,
        expYear: widget.expYear,
        cardHolder: widget.cardHolder,
        customerEmail: widget.customerEmail,
        travel: widget.travel,
      );

      setState(() {
        _statusMessage = 'Finalizando...';
        _isCompleted = true;
      });

      await Future.delayed(const Duration(seconds: 1));

      // Navegar a pantalla de resultado
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentResultScreen(
            success: result['success'] ?? false,
            payment: widget.payment,
            travel: widget.travel,
            message: result['message'] ?? '',
            transactionData: result['transaction'],
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error procesando el pago';
        _isCompleted = true;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentResultScreen(
            success: false,
            payment: widget.payment,
            travel: widget.travel,
            message: 'Error: $e',
            transactionData: null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // No permitir regresar durante el proceso
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono animado
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.principal.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isCompleted
                              ? Icons.check_circle
                              : Icons.credit_card,
                          size: 60,
                          color: AppColors.principal,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Mensaje de estado
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Por favor espera mientras procesamos tu pago de forma segura',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Indicador de progreso
                    if (!_isCompleted)
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),

                    const SizedBox(height: 40),

                    // Información de seguridad
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pago 100% seguro',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tus datos están protegidos con cifrado de última generación',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }
}
