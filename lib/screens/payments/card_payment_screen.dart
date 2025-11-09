import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import '../../utils/payment_validators.dart';
import '../../utils/payment_constants.dart';
import '../../models/travel_model.dart';
import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'processing_payment_screen.dart';

/// Pantalla para pago con tarjeta de crédito/débito
class CardPaymentScreen extends StatefulWidget {
  final Travel travel;
  final int seatsReserved;
  final double totalAmount;

  const CardPaymentScreen({
    Key? key,
    required this.travel,
    required this.seatsReserved,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isProcessing = false;
  String _cardType = 'unknown';

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_updateCardType);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _updateCardType() {
    setState(() {
      _cardType = PaymentValidators.getCardType(_cardNumberController.text);
    });
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('Debes iniciar sesión para continuar');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Inicializar pago
      final payment = await PaymentService.initializePayment(
        passengerId: user.uid,
        travelId: widget.travel.id!,
        amount: widget.totalAmount,
        seatsReserved: widget.seatsReserved,
        paymentMethod: PaymentMethod.card,
      );

      // 2. Navegar a pantalla de procesamiento
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProcessingPaymentScreen(
            payment: payment,
            travel: widget.travel,
            cardNumber: _cardNumberController.text,
            cvc: _cvvController.text,
            expMonth: _expiryMonthController.text,
            expYear: _expiryYearController.text,
            cardHolder: _cardHolderController.text,
            customerEmail: user.email ?? '',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error iniciando el pago: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _fillTestCard() {
    final testCard = PaymentConstants.testCards['visa_approved']!;
    _cardNumberController.text = testCard['number'];
    _cardHolderController.text = testCard['card_holder'];
    _expiryMonthController.text = testCard['exp_month'];
    _expiryYearController.text = testCard['exp_year'];
    _cvvController.text = testCard['cvc'];
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
              AppColors.gris50,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.gris50,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPaymentSummary(),
                          const SizedBox(height: 24),
                          _buildCardPreview(),
                          const SizedBox(height: 24),
                          _buildCardNumberField(),
                          const SizedBox(height: 16),
                          _buildCardHolderField(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildExpiryField()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildCVVField()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (PaymentConstants.isSandbox) _buildTestCardButton(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.principal),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pago con tarjeta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Ingresa los datos de tu tarjeta',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.principal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.principal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del pago',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.titulo,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Viaje', '${widget.travel.origen} → ${widget.travel.destino}', multiline: true),
          _buildSummaryRow('Asientos', '${widget.seatsReserved}'),
          _buildSummaryRow('Precio por asiento', PaymentConstants.formatearMonto(widget.travel.precioPorAsiento ?? 0)),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total a pagar',
            PaymentConstants.formatearMonto(widget.totalAmount),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, bool multiline = false}) {
    if (multiline) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.subtitulo,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.titulo,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? AppColors.titulo : AppColors.subtitulo,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                color: isTotal ? AppColors.principal : AppColors.titulo,
              ),
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _cardType == 'visa'
                ? Colors.blue.shade900
                : _cardType == 'mastercard'
                    ? Colors.orange.shade900
                    : AppColors.principal,
            _cardType == 'visa'
                ? Colors.blue.shade700
                : _cardType == 'mastercard'
                    ? Colors.orange.shade700
                    : AppColors.secundario,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.credit_card, color: Colors.white, size: 40),
                if (_cardType != 'unknown')
                  Text(
                    _cardType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            Text(
              PaymentValidators.formatCardNumber(_cardNumberController.text.isEmpty
                  ? '#### #### #### ####'
                  : _cardNumberController.text),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TITULAR',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      _cardHolderController.text.isEmpty
                          ? 'NOMBRE APELLIDO'
                          : _cardHolderController.text.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VENCE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      _expiryMonthController.text.isEmpty ||
                              _expiryYearController.text.isEmpty
                          ? 'MM/AA'
                          : '${_expiryMonthController.text.padLeft(2, '0')}/${_expiryYearController.text}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardNumberField() {
    return TextFormField(
      controller: _cardNumberController,
      decoration: InputDecoration(
        labelText: 'Número de tarjeta',
        hintText: '1234 5678 9012 3456',
        prefixIcon: const Icon(Icons.credit_card),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(16),
        _CardNumberFormatter(),
      ],
      validator: (value) => PaymentValidators.getCardNumberError(value ?? ''),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildCardHolderField() {
    return TextFormField(
      controller: _cardHolderController,
      decoration: InputDecoration(
        labelText: 'Nombre del titular',
        hintText: 'NOMBRE APELLIDO',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
      ],
      validator: (value) => PaymentValidators.getCardHolderError(value ?? ''),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildExpiryField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _expiryMonthController,
            decoration: InputDecoration(
              labelText: 'Mes',
              hintText: 'MM',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Requerido';
              if (!PaymentValidators.validateExpiryMonth(value)) {
                return 'Inválido';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('/', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: TextFormField(
            controller: _expiryYearController,
            decoration: InputDecoration(
              labelText: 'Año',
              hintText: 'AA',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Requerido';
              if (!PaymentValidators.validateExpiryYear(value)) {
                return 'Inválido';
              }
              return PaymentValidators.getExpiryDateError(
                _expiryMonthController.text,
                value,
              );
            },
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildCVVField() {
    return TextFormField(
      controller: _cvvController,
      decoration: InputDecoration(
        labelText: 'CVV',
        hintText: '123',
        prefixIcon: const Icon(Icons.lock),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.number,
      obscureText: true,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      validator: (value) => PaymentValidators.getCVVError(value ?? ''),
    );
  }

  Widget _buildTestCardButton() {
    return OutlinedButton.icon(
      onPressed: _fillTestCard,
      icon: const Icon(Icons.science),
      label: const Text('Usar tarjeta de prueba'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.principal,
        side: const BorderSide(color: AppColors.principal),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
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
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.principal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock),
                    const SizedBox(width: 8),
                    Text(
                      'Pagar ${PaymentConstants.formatearMonto(widget.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Formateador para el número de tarjeta (agrega espacios cada 4 dígitos)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
